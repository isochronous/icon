# `ecological-impact` — Formula Reference

At-a-glance lookup for the formulas and constants used in `ecological-impact`. The skill body (Steps 1-6) explains *what* and *why*; this file is the *how* in tabular form.

---

## Quick Reference

| Quantity | Formula | Constants |
|----------|---------|-----------|
| Token estimate | `turns × tokens_per_interaction` | 1,500 (conversational) or 15,000 (agentic/multi-agent) |
| Energy | `tokens × 0.000001` kWh | 0.001 kWh/1k tokens |
| CO₂ | `energy_kWh × 386` g | 386 g CO₂/kWh (US avg) |
| Trees burned | `co2_g / 832,000` | 832,000 g CO₂/tree |
| milliTrees | `trees_burned × 1,000` | — |
| Water (L) | `energy_kWh × 1.8` | 1.8 L/kWh |
| Water (gal) | `water_L × 0.264172` | — |
| Annual projection | `× 12` (monthly scope) or `× 1,200` (session scope) | Monthly: × 12; Session: 100 sessions/month × 12 |
| Car equivalent | `co2_g / 404` miles | 404 g CO₂/mile |
| Search equivalent | `energy_Wh / 0.0003` searches | 0.3 Wh/Google search |
| LED bulb (10W) equiv | `(energy_kWh / 0.010) × 3600` seconds | 10W typical LED bulb |
| Refrigerator (150W) equiv | `(energy_kWh / 0.150) × 3600` seconds | 150W avg modern fridge |

## Constants Used

| Constant | Value | Source |
|---|---|---|
| LLM inference rate | 0.001 kWh / 1,000 tokens | Patterson et al. 2022; IEA 2023 AI energy reports |
| Grid carbon intensity | 386 g CO₂ / kWh | US EPA 2022 eGRID national average |
| Tree CO₂ equivalent (1 TBU) | ~832,000 g CO₂ | 1,000 lbs × 0.454 kg/lb × 0.5 carbon × 44/12 ≈ 832,000 g |
| Data center water | 1.8 L / kWh | Mytton 2021, *Nature Communications* |
| Car emissions | 404 g CO₂ / mile | US EPA |
| Google search energy | 0.3 Wh / search | — |
| LED bulb power | 10 W | typical |
| Refrigerator power | 150 W | average modern fridge |
