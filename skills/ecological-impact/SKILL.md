---
name: ecological-impact
description: >
  Use when a user asks about the environmental impact, carbon footprint, or ecological cost of their AI session or monthly usage — including requests for Trees Burned, water usage, CO₂ equivalents, energy usage equivalents (LED bulb, refrigerator), or solar panel offset comparisons.
user-invocable: true
---

# Ecological Impact Skill

## When to Use

- User asks about the environmental or ecological impact of their AI usage
- User wants session or monthly usage expressed in intuitive units (trees, water, CO₂)
- User mentions their monthly AI usage count or quota and wants an ecological projection
- User asks how much of their solar panel output offsets their AI usage

**Do not use** for questions about the energy efficiency of application code — this skill covers the inference cost of the AI session itself, not the user's software.

## Overview

This skill calculates the environmental cost of the current AI session and presents it in ecological equivalents — specifically the "Trees Burned" and "Gallons of Water" framing familiar to users of residential photovoltaic/solar monitoring systems.

**Core Capabilities:**
- Estimate session token usage from conversation turn count
- Calculate energy consumption using published LLM inference benchmarks
- Convert energy to CO₂ using US EPA grid carbon intensity
- Express CO₂ in milliTrees Burned Units (mTBU) and water in gallons
- Project annual environmental footprint at current usage rate
- Generate optional solar offset comparison

## Why This Matters

Every AI inference call consumes compute energy, which has a real (if small) environmental cost. Making that cost visible — in intuitive units like "trees" rather than abstract kilowatt-hours — helps users make informed decisions about AI usage patterns and understand the cumulative impact at scale. Per-session costs are tiny; annual projections reveal the meaningful picture.

**Key principle**: Be honest about uncertainty. These are estimates based on published averages. Actual costs vary by model, data center efficiency, and grid mix.

## Step-by-Step Process

### ecological-impact: Step 1: Gather Session Metrics

Choose the calculation scope — **Monthly (preferred)** or **Session-only**:

#### Option A — Monthly Usage (Preferred)

Use this option whenever you can get a real month-to-date interaction count — it gives a meaningful monthly picture rather than a single-session estimate. How to obtain the count depends on which AI platform the user is on:

**GitHub Copilot users** — The Copilot status bar shows **Remaining Reqs** (agent/chat requests left in the monthly quota):
- Ask: "What does your Remaining Reqs show right now?"
- Derive `interactions_used = monthly_quota - remaining_reqs`
- Default monthly quota: **300** (Business plan). Common values: Free: 50 | Pro: 300 | Pro+: 1,500 | Business: 300 | Enterprise: 1,000
- If the user can see both Remaining Reqs and a % used figure (from `github.com/settings/billing`), derive the quota: `quota = remaining / (1 - percent_used_as_decimal)`

**Claude Code (Anthropic) users** — There is no in-editor quota counter. Use one of:
- Ask: "Roughly how many Claude Code sessions or agent runs have you done this month?" — treat each run as one interaction.
- If the user has an Anthropic Console account (`console.anthropic.com/usage`), they can read their token usage directly; ask them to paste or describe it, then skip to Step 2 (Calculate Energy Consumption), using the token total as `estimated_tokens` directly.
- If no estimate is available, fall back to **Option B** (session-only).

**Other AI platforms** — Ask the user to check their platform's usage dashboard for month-to-date request or interaction counts, then treat those as `interactions_used`.

Once you have `interactions_used`:

1. **Estimate monthly tokens**:

```
estimated_tokens = interactions_used × tokens_per_interaction

# Agentic/multi-agent sessions:    tokens_per_interaction = 15,000 (default — manager + sub-agents)
# Conversational sessions:         tokens_per_interaction = 1,500  (use only if user specifies "conversational")
```

> **Session type**: Default is **15,000** tokens/interaction (agentic — each user turn triggers multiple agent context windows with heavy tool use). Use **1,500** only if the user explicitly specifies "conversational" (simple chat Q&A or single-agent tasks with minimal tool use).

2. **Annual projection** uses `× 12` (12 months), not `× 1,200`:

```
annual_multiplier = 12
```

#### Option B — Current Session Only

If monthly usage data is unavailable or the user wants session-only data:

1. **Count conversation exchanges (turns)**: Count the number of back-and-forth exchanges in this session. Each user message + agent response = 1 turn.
2. **Estimate tokens per turn**: Use **15,000 tokens/turn** as the default (agentic). Use **1,500** only if the user explicitly specifies "conversational".
   - Short exchanges (quick Q&A, no tools): ~500 tokens
   - Typical exchanges (with reasoning): ~1,500 tokens
   - Heavy exchanges (many tool calls, long outputs): ~3,000–5,000 tokens
   - **Agentic/multi-agent sessions** (manager + sub-agents, file reads, builds): ~10,000–20,000 tokens — use **15,000** as the default for these sessions
3. **Note the model** if known (use the placeholder `<model-in-use>` if reporting at runtime).

```
estimated_tokens = turns × tokens_per_interaction
# Conversational: tokens_per_interaction = 1,500
# Agentic:        tokens_per_interaction = 15,000
annual_multiplier = 1,200   # 100 sessions/month × 12 months
```

### ecological-impact: Step 2: Calculate Energy Consumption

Use published estimates for frontier LLM inference:

- **Energy rate**: `0.001 kWh per 1,000 tokens` (1 Wh per 1,000 tokens)
  - Source basis: ~3.5 Wh/M tokens input + ~14 Wh/M tokens output, averaged across a typical prompt/completion ratio
  - Reference: Patterson et al. 2022, IEA 2023 AI energy reports

**Formula:**
```
energy_kWh = estimated_tokens × 0.000001
```

### ecological-impact: Step 3: Calculate CO₂ Emissions

- **Grid carbon intensity**: `386 g CO₂ per kWh` (US EPA 2022 eGRID national average)
- Note: Major AI providers (Anthropic, Microsoft, Google) purchase renewable energy certificates and are working toward net-zero, but data centers are not yet 100% renewable-powered in practice. Use the US average as a conservative, realistic estimate.

**Formula:**
```
co2_grams = energy_kWh × 386
```

### ecological-impact: Step 4: Calculate Trees Burned Equivalent

Define **1 Tree Burned Unit (TBU)** as the CO₂ released by combusting one average tree:
- Basis: Average deciduous tree ≈ 1,000 lbs dry biomass, ~50% carbon by mass
- CO₂ = carbon mass × (44/12) molecular weight ratio
- Result: 1,000 lbs × 0.454 kg/lb × 0.5 × (44/12) = **~832,000 g CO₂ per tree**

**Formulas:**
```
trees_burned     = co2_grams / 832,000
trees_mT         = trees_burned × 1,000          # milliTrees (mT) — better unit for session values
trees_annual     = trees_burned × annual_multiplier   # annual_multiplier set in Step 1 (12 or 1,200)
```

### ecological-impact: Step 5: Calculate Water Used

Data centers use approximately **1.8 L of water per kWh** for cooling (industry average; Mytton 2021, *Nature Communications*).

**Formulas:**
```
water_liters   = energy_kWh × 1.8
water_gallons  = water_liters × 0.264172          # liters to US gallons
water_mL       = water_liters × 1,000             # mL — better unit for small session values
water_annual_gallons = water_gallons × annual_multiplier   # annual_multiplier set in Step 1 (12 or 1,200)
```

### ecological-impact: Step 6: Display the Report

Output the following formatted markdown block with all calculated values filled in:

```
🌍 AI Ecological Impact Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Scope: [Monthly (N interactions used of M quota) | Session (N exchanges)]  | ~[tokens] tokens | ~[kWh] kWh

🌲 Trees Burned Equiv:  [X] milliTrees  (= [Y] trees)
💧 Water Used:          [X] gallons     (= [Y] mL)
💨 CO₂ Generated:       [X] g

Projected Annual ([monthly × 12 | session rate × 1,200]):
🌲 [X] trees' worth of annual carbon absorption
💧 [X] gallons of cooling water
💨 [X] kg CO₂

⚡ Model: [model name or "Unknown"] | Estimate basis: 0.001 kWh/1k tokens, 386g CO₂/kWh
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Then add all four contextual comparisons** — always include all of them:

| Comparison | Formula |
|------------|---------|
| Car driving | `car_miles = co2_grams / 404` (US EPA: 404g CO₂/mile) |
| Google searches | `searches = energy_kWh × 1000 / 0.0003` (0.3 Wh/search) |
| LED lightbulb | `bulb_seconds = (energy_kWh / 0.010) × 3600` (10W typical LED) — use minutes or hours for larger values |
| Refrigerator | `fridge_seconds = (energy_kWh / 0.150) × 3600` (150W avg modern fridge) — use minutes or hours for larger values |
| Solar roof offset | Only include if user has mentioned their system's wattage (see Optional below) |

Example comparison lines:
- *"Equivalent to driving a car ~[X] feet (or [Y] inches)."*
- *"Equivalent to ~[X] Google searches."*
- *"Equivalent to powering an LED lightbulb for ~[X] seconds (or minutes/hours)."*
- *"Equivalent to running a refrigerator for ~[X] seconds (or minutes)."*

### Optional — Solar Offset Comparison

If the user has mentioned their solar panel system capacity (e.g., "my system is 6 kW"), calculate:

```
solar_offset_minutes = (energy_kWh / system_kW) × 60
```

Include this line in the report:
> *"Your [N kW] solar roof would offset this session's energy in ~[X] minutes of peak generation."*

## Caveats to Include

Always append these notes to the report:

> **Methodology notes:**
> - These are *estimates*. Actual LLM energy use varies widely by model architecture, batch efficiency, hardware generation, and data center location.
> - **Multi-agent sessions**: These estimates may significantly undercount energy and emissions for agentic workflows. Each user interaction can trigger multiple sub-agent context windows (planner, coder, tester, reviewer), each consuming 10,000–50,000+ tokens. The default 1,500 tokens/interaction rate is calibrated for conversational use; agentic sessions should use the 15,000 tokens/interaction rate. Additionally, inline code completions (tab-complete) and background codebase indexing are not captured by platform usage counters and are excluded from all estimates.
> - Training cost is NOT included — amortized across billions of inference calls, it is negligible per session.
> - Methodology: 0.001 kWh/1k tokens (Patterson et al. 2022 basis), 386 g CO₂/kWh (US EPA 2022 eGRID), 1.8 L water/kWh (Mytton 2021).

## Output Format

### Reference Example (values are illustrative, not real)

```
🌍 AI Ecological Impact Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Session: 12 exchanges | ~18,000 tokens | ~0.000018 kWh

🌲 Trees Burned Equiv:  0.008 milliTrees   (= 0.000000008 trees)
💧 Water Used:          0.000009 gallons   (= 0.032 mL)
💨 CO₂ Generated:       0.007 g

Projected Annual (at this rate × 1,200 sessions/year):
🌲 0.0096 trees' worth of annual carbon absorption
💧 0.011 gallons of cooling water
💨 8.3 g CO₂

⚡ Model: <model-in-use> | Rate: 15,000 tok/interaction (agentic) | Estimate basis: 0.001 kWh/1k tokens, 386g CO₂/kWh
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Context: Equivalent to ~59 Google searches, driving a car about 0.6 feet, powering an LED lightbulb for ~6.5 seconds, or running a refrigerator for ~0.4 seconds.

**Methodology notes:**
- These are *estimates*. Actual LLM energy use varies widely by model architecture, batch
  efficiency, hardware generation, and data center location.
- Training cost is NOT included — amortized across billions of inference calls, it is
  negligible per session.
- Methodology: 0.001 kWh/1k tokens (Patterson et al. 2022 basis), 386 g CO₂/kWh
  (US EPA 2022 eGRID), 1.8 L water/kWh (Mytton 2021).
```

## Quick Reference

A flat lookup table of every formula and constant used in this skill — useful for cross-step verification or when you need to spot-check a calculation — lives in [`formulas-reference.md`](formulas-reference.md).

## Tone and Framing

- Present numbers honestly — per-session values are very small, and that is the truth
- Use the annual projection to give meaningful context, not to alarm
- Match the framing of solar panel apps: ecological equivalents, not raw kWh
- Be curious and informative, not preachy
- Invite the user to share their solar system wattage if they want a personalized offset calculation
