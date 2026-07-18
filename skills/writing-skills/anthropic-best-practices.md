<!--
Canonical Anthropic Skill-authoring reference.
Original: https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/best-practices

ICON-specific conventions (folded YAML scalar, step-heading format, `user-invocable`
field, README skills-table registration) are documented in SKILL.md alongside.

Mintlify-specific markup (image tags, MDX components, theme attributes) stripped for
clean rendering in plain markdown viewers and agent contexts.
-->

# Skill authoring best practices

> How to write effective Skills that Claude can discover and use.

Good Skills are concise, well-structured, and tested with real usage.

For background, see the [Skills overview](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview).

## Core principles

### Concise is key

The [context window](https://platform.claude.com/docs/en/build-with-claude/context-windows) is a public good, shared with everything else Claude needs:

* The system prompt
* Conversation history
* Other Skills' metadata
* Your actual request

Not every token has immediate cost: at startup only metadata (name, description) is pre-loaded; Claude reads SKILL.md when the Skill becomes relevant, other files as needed. But conciseness still matters — once loaded, every token competes with conversation history and other context.

**Default assumption**: Claude is already very smart

Only add context Claude doesn't already have. Challenge each piece:

* "Does Claude really need this explanation?"
* "Can I assume Claude knows this?"
* "Does this paragraph justify its token cost?"

**Good example: Concise** (approximately 50 tokens):

````markdown
## Extract PDF text

Use pdfplumber for text extraction:

```python
import pdfplumber

with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
````

**Bad example: Too verbose** (approximately 150 tokens):

```markdown
## Extract PDF text

PDF (Portable Document Format) files are a common file format that contains
text, images, and other content. To extract text from a PDF, you'll need to
use a library. There are many libraries available for PDF processing, but we
recommend pdfplumber because it's easy to use and handles most cases well.
First, you'll need to install it using pip. Then you can use the code below...
```

### Set appropriate degrees of freedom

Match specificity to task fragility and variability.

**High freedom** (text-based instructions):

Use when:

* Multiple approaches are valid
* Decisions depend on context
* Heuristics guide the approach

Example:

```markdown
## Code review process

1. Analyze the code structure and organization
2. Check for potential bugs or edge cases
3. Suggest improvements for readability and maintainability
4. Verify adherence to project conventions
```

**Medium freedom** (pseudocode or scripts with parameters):

Use when:

* A preferred pattern exists
* Some variation is acceptable
* Configuration affects behavior

Example:

````markdown
## Generate report

Use this template and customize as needed:

```python
def generate_report(data, format="markdown", include_charts=True):
    # Process data
    # Generate output in specified format
    # Optionally include visualizations
```
````

**Low freedom** (specific scripts, few or no parameters):

Use when:

* Operations are fragile and error-prone
* Consistency is critical
* A specific sequence must be followed

Example:

````markdown
## Database migration

Run exactly this script:

```bash
python scripts/migrate.py --verify --backup
```

Do not modify the command or add additional flags.
````

**Analogy**: Claude as a robot exploring a path:

* **Narrow bridge with cliffs on both sides**: one safe way forward. Provide guardrails and exact instructions (low freedom). Example: database migrations that must run in exact sequence.
* **Open field with no hazards**: many paths succeed. Give general direction and trust Claude to find the best route (high freedom). Example: code reviews where context determines the approach.

### Test with all models you plan to use

Skills add to models, so effectiveness depends on the underlying model.

**Testing considerations by model**:

* **Claude Haiku** (fast, economical): Does the Skill provide enough guidance?
* **Claude Sonnet** (balanced): Is the Skill clear and efficient?
* **Claude Opus** (powerful reasoning): Does the Skill avoid over-explaining?

What works for Opus might need more detail for Haiku. Aim for instructions that work well across all of them.

## Skill structure

**Note:**
  **YAML Frontmatter**: The SKILL.md frontmatter requires two fields:

  * `name` - Human-readable name (64 characters maximum)
  * `description` - what the Skill does and when to use it (1024 characters maximum)

  For complete structure details, see the [Skills overview](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview#skill-structure).


### Naming conventions

Consistent naming makes Skills easier to reference. Prefer **gerund form** (verb + -ing) — it clearly describes the activity or capability.

**Good naming examples (gerund form)**:

* "Processing PDFs"
* "Analyzing spreadsheets"
* "Managing databases"
* "Testing code"
* "Writing documentation"

**Acceptable alternatives**:

* Noun phrases: "PDF Processing", "Spreadsheet Analysis"
* Action-oriented: "Process PDFs", "Analyze Spreadsheets"

**Avoid**:

* Vague names: "Helper", "Utils", "Tools"
* Overly generic: "Documents", "Data", "Files"
* Inconsistent patterns within your skill collection

### Writing effective descriptions

The `description` field drives Skill discovery — include both what the Skill does and when to use it.

**Warning:**
  **Always write in third person**. The description is injected into the system prompt; inconsistent point-of-view causes discovery problems.

  * **Good:** "Processes Excel files and generates reports"
  * **Avoid:** "I can help you process Excel files"
  * **Avoid:** "You can use this to process Excel files"


**Be specific and include key terms** — both what the Skill does and its triggers/contexts.

The single description field is critical: Claude uses it to choose the right Skill from potentially 100+ available. It must give enough detail to know when to select this Skill; the rest of SKILL.md provides implementation details.

Effective examples:

**PDF Processing skill:**

```yaml
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
```

**Excel Analysis skill:**

```yaml
description: Analyze Excel spreadsheets, create pivot tables, generate charts. Use when analyzing Excel files, spreadsheets, tabular data, or .xlsx files.
```

**Git Commit Helper skill:**

```yaml
description: Generate descriptive commit messages by analyzing git diffs. Use when the user asks for help writing commit messages or reviewing staged changes.
```

Avoid vague descriptions like these:

```yaml
description: Helps with documents
```

```yaml
description: Processes data
```

```yaml
description: Does stuff with files
```

### Progressive disclosure patterns

SKILL.md is an overview that points Claude to detailed materials as needed, like a table of contents. For how progressive disclosure works, see [How Skills work](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview#how-skills-work) in the overview.

**Practical guidance:**

* Keep SKILL.md body under 500 lines
* Split content into separate files when approaching this limit
* Use the patterns below to organize instructions, code, and resources

#### Visual overview: From simple to complex

A basic Skill starts with just a SKILL.md file containing metadata and instructions.

As your Skill grows, bundle additional content that Claude loads only when needed.

The complete Skill directory structure might look like this:

```
pdf/
├── SKILL.md              # Main instructions (loaded when triggered)
├── FORMS.md              # Form-filling guide (loaded as needed)
├── reference.md          # API reference (loaded as needed)
├── examples.md           # Usage examples (loaded as needed)
└── scripts/
    ├── analyze_form.py   # Utility script (executed, not loaded)
    ├── fill_form.py      # Form filling script
    └── validate.py       # Validation script
```

#### Pattern 1: High-level guide with references

````markdown
---
name: PDF Processing
description: Extracts text and tables from PDF files, fills forms, and merges documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
---

# PDF Processing

## Quick start

Extract text with pdfplumber:
```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

## Advanced features

**Form filling**: See [FORMS.md](FORMS.md) for complete guide
**API reference**: See [REFERENCE.md](REFERENCE.md) for all methods
**Examples**: See [EXAMPLES.md](EXAMPLES.md) for common patterns
````

Claude loads FORMS.md, REFERENCE.md, or EXAMPLES.md only as needed.

#### Pattern 2: Domain-specific organization

For Skills spanning multiple domains, organize by domain to avoid loading irrelevant context. Asked about sales metrics, Claude reads only sales schemas, not finance or marketing — keeping token usage low and context focused.

```
bigquery-skill/
├── SKILL.md (overview and navigation)
└── reference/
    ├── finance.md (revenue, billing metrics)
    ├── sales.md (opportunities, pipeline)
    ├── product.md (API usage, features)
    └── marketing.md (campaigns, attribution)
```

````markdown SKILL.md
# BigQuery Data Analysis

## Available datasets

**Finance**: Revenue, ARR, billing → See [reference/finance.md](reference/finance.md)
**Sales**: Opportunities, pipeline, accounts → See [reference/sales.md](reference/sales.md)
**Product**: API usage, features, adoption → See [reference/product.md](reference/product.md)
**Marketing**: Campaigns, attribution, email → See [reference/marketing.md](reference/marketing.md)

## Quick search

Find specific metrics using grep:

```bash
grep -i "revenue" reference/finance.md
grep -i "pipeline" reference/sales.md
grep -i "api usage" reference/product.md
```
````

#### Pattern 3: Conditional details

Show basic content, link to advanced content:

```markdown
# DOCX Processing

## Creating documents

Use docx-js for new documents. See [DOCX-JS.md](DOCX-JS.md).

## Editing documents

For simple edits, modify the XML directly.

**For tracked changes**: See [REDLINING.md](REDLINING.md)
**For OOXML details**: See [OOXML.md](OOXML.md)
```

Claude reads REDLINING.md or OOXML.md only when those features are needed.

### Avoid deeply nested references

Claude may only partially read files referenced from other referenced files — previewing with `head -100` rather than reading whole files, yielding incomplete information.

**Keep references one level deep from SKILL.md**. All reference files should link directly from SKILL.md so Claude reads complete files when needed.

**Bad example: Too deep**:

```markdown
# SKILL.md
See [advanced.md](advanced.md)...

# advanced.md
See [details.md](details.md)...

# details.md
Here's the actual information...
```

**Good example: One level deep**:

```markdown
# SKILL.md

**Basic usage**: [instructions in SKILL.md]
**Advanced features**: See [advanced.md](advanced.md)
**API reference**: See [reference.md](reference.md)
**Examples**: See [examples.md](examples.md)
```

### Structure longer reference files with table of contents

For reference files longer than 100 lines, include a table of contents at the top, so Claude sees the full scope even when previewing with partial reads.

**Example**:

```markdown
# API Reference

## Contents
- Authentication and setup
- Core methods (create, read, update, delete)
- Advanced features (batch operations, webhooks)
- Error handling patterns
- Code examples

## Authentication and setup
...

## Core methods
...
```

Claude can then read the complete file or jump to specific sections as needed.

For how this filesystem-based architecture enables progressive disclosure, see [Runtime environment](#runtime-environment) below.

## Workflows and feedback loops

### Use workflows for complex tasks

Break complex operations into clear, sequential steps. For particularly complex workflows, provide a checklist Claude can copy into its response and check off as it goes.

**Example 1: Research synthesis workflow** (for Skills without code):

````markdown
## Research synthesis workflow

Copy this checklist and track your progress:

```
Research Progress:
- [ ] Step 1: Read all source documents
- [ ] Step 2: Identify key themes
- [ ] Step 3: Cross-reference claims
- [ ] Step 4: Create structured summary
- [ ] Step 5: Verify citations
```

**Step 1: Read all source documents**

Review each document in the `sources/` directory. Note the main arguments and supporting evidence.

**Step 2: Identify key themes**

Look for patterns across sources. What themes appear repeatedly? Where do sources agree or disagree?

**Step 3: Cross-reference claims**

For each major claim, verify it appears in the source material. Note which source supports each point.

**Step 4: Create structured summary**

Organize findings by theme. Include:
- Main claim
- Supporting evidence from sources
- Conflicting viewpoints (if any)

**Step 5: Verify citations**

Check that every claim references the correct source document. If citations are incomplete, return to Step 3.
````

The checklist pattern works for any complex, multi-step process, with or without code.

**Example 2: PDF form filling workflow** (for Skills with code):

````markdown
## PDF form filling workflow

Copy this checklist and check off items as you complete them:

```
Task Progress:
- [ ] Step 1: Analyze the form (run analyze_form.py)
- [ ] Step 2: Create field mapping (edit fields.json)
- [ ] Step 3: Validate mapping (run validate_fields.py)
- [ ] Step 4: Fill the form (run fill_form.py)
- [ ] Step 5: Verify output (run verify_output.py)
```

**Step 1: Analyze the form**

Run: `python scripts/analyze_form.py input.pdf`

This extracts form fields and their locations, saving to `fields.json`.

**Step 2: Create field mapping**

Edit `fields.json` to add values for each field.

**Step 3: Validate mapping**

Run: `python scripts/validate_fields.py fields.json`

Fix any validation errors before continuing.

**Step 4: Fill the form**

Run: `python scripts/fill_form.py input.pdf fields.json output.pdf`

**Step 5: Verify output**

Run: `python scripts/verify_output.py output.pdf`

If verification fails, return to Step 2.
````

### Implement feedback loops

**Common pattern**: Run validator → fix errors → repeat. Greatly improves output quality.

**Example 1: Style guide compliance** (for Skills without code):

```markdown
## Content review process

1. Draft your content following the guidelines in STYLE_GUIDE.md
2. Review against the checklist:
   - Check terminology consistency
   - Verify examples follow the standard format
   - Confirm all required sections are present
3. If issues found:
   - Note each issue with specific section reference
   - Revise the content
   - Review the checklist again
4. Only proceed when all requirements are met
5. Finalize and save the document
```

The "validator" is STYLE\_GUIDE.md — Claude checks by reading and comparing; no script needed.

**Example 2: Document editing process** (for Skills with code):

```markdown
## Document editing process

1. Make your edits to `word/document.xml`
2. **Validate immediately**: `python ooxml/scripts/validate.py unpacked_dir/`
3. If validation fails:
   - Review the error message carefully
   - Fix the issues in the XML
   - Run validation again
4. **Only proceed when validation passes**
5. Rebuild: `python ooxml/scripts/pack.py unpacked_dir/ output.docx`
6. Test the output document
```

## Content guidelines

### Avoid time-sensitive information

Don't include information that will become outdated.

**Bad example: Time-sensitive** (will become wrong):

```markdown
If you're doing this before August 2025, use the old API.
After August 2025, use the new API.
```

**Good example** (use "old patterns" section):

```markdown
## Current method

Use the v2 API endpoint: `api.example.com/v2/messages`

## Old patterns

<details>
<summary>Legacy v1 API (deprecated 2025-08)</summary>

The v1 API used: `api.example.com/v1/messages`

This endpoint is no longer supported.
</details>
```

The old patterns section gives historical context without cluttering the main content.

### Use consistent terminology

Choose one term and use it throughout:

**Good - Consistent**:

* Always "API endpoint"
* Always "field"
* Always "extract"

**Bad - Inconsistent**:

* Mix "API endpoint", "URL", "API route", "path"
* Mix "field", "box", "element", "control"
* Mix "extract", "pull", "get", "retrieve"

## Common patterns

### Template pattern

Provide output-format templates. Match strictness to your needs.

**For strict requirements** (like API responses or data formats):

````markdown
## Report structure

ALWAYS use this exact template structure:

```markdown
# [Analysis Title]

## Executive summary
[One-paragraph overview of key findings]

## Key findings
- Finding 1 with supporting data
- Finding 2 with supporting data
- Finding 3 with supporting data

## Recommendations
1. Specific actionable recommendation
2. Specific actionable recommendation
```
````

**For flexible guidance** (when adaptation is useful):

````markdown
## Report structure

Here is a sensible default format, but use your best judgment based on the analysis:

```markdown
# [Analysis Title]

## Executive summary
[Overview]

## Key findings
[Adapt sections based on what you discover]

## Recommendations
[Tailor to the specific context]
```

Adjust sections as needed for the specific analysis type.
````

### Examples pattern

Where output quality depends on seeing examples, provide input/output pairs as in regular prompting:

````markdown
## Commit message format

Generate commit messages following these examples:

**Example 1:**
Input: Added user authentication with JWT tokens
Output:
```
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware
```

**Example 2:**
Input: Fixed bug where dates displayed incorrectly in reports
Output:
```
fix(reports): correct date formatting in timezone conversion

Use UTC timestamps consistently across report generation
```

**Example 3:**
Input: Updated dependencies and refactored error handling
Output:
```
chore: update dependencies and refactor error handling

- Upgrade lodash to 4.17.21
- Standardize error response format across endpoints
```

Follow this style: type(scope): brief description, then detailed explanation.
````

### Conditional workflow pattern

Guide Claude through decision points:

```markdown
## Document modification workflow

1. Determine the modification type:

   **Creating new content?** → Follow "Creation workflow" below
   **Editing existing content?** → Follow "Editing workflow" below

2. Creation workflow:
   - Use docx-js library
   - Build document from scratch
   - Export to .docx format

3. Editing workflow:
   - Unpack existing document
   - Modify XML directly
   - Validate after each change
   - Repack when complete
```

**Tip:**
  If workflows grow large or complicated, push them into separate files and tell Claude which to read for the task at hand.


## Evaluation and iteration

### Build evaluations first

**Create evaluations BEFORE writing extensive documentation.** This ensures your Skill solves real problems, not imagined ones.

**Evaluation-driven development:**

1. **Identify gaps**: Run Claude on representative tasks without a Skill. Document specific failures or missing context
2. **Create evaluations**: Build three scenarios testing these gaps
3. **Establish baseline**: Measure Claude's performance without the Skill
4. **Write minimal instructions**: Just enough to address the gaps and pass evaluations
5. **Iterate**: Execute evaluations, compare against baseline, refine

**Evaluation structure**:

```json
{
  "skills": ["pdf-processing"],
  "query": "Extract all text from this PDF file and save it to output.txt",
  "files": ["test-files/document.pdf"],
  "expected_behavior": [
    "Successfully reads the PDF file using an appropriate PDF processing library or command-line tool",
    "Extracts text content from all pages in the document without missing any pages",
    "Saves the extracted text to a file named output.txt in a clear, readable format"
  ]
}
```

**Note:**
  There is no built-in way to run these evaluations; create your own. Evaluations are your source of truth for measuring Skill effectiveness.


### Develop Skills iteratively with Claude

The most effective process uses Claude itself. One instance ("Claude A") creates a Skill that others ("Claude B") use: A designs and refines, B tests in real tasks. This works because Claude models understand both how to write effective agent instructions and what agents need.

**Creating a new Skill:**

1. **Complete a task without a Skill**: Work a problem with Claude A using normal prompting. You'll naturally provide context, preferences, and procedural knowledge — notice what you repeatedly provide.

2. **Identify the reusable pattern**: Afterward, identify what context would help similar future tasks.

   **Example**: A BigQuery analysis might have required table names, field definitions, filtering rules (like "always exclude test accounts"), and common query patterns.

3. **Ask Claude A to create a Skill**: "Create a Skill that captures this BigQuery analysis pattern we just used. Include the table schemas, naming conventions, and the rule about filtering test accounts."

   **Tip:**
     Claude models understand the Skill format natively. No special system prompts or "writing skills" skill needed — just ask Claude to create a Skill and it generates a properly structured SKILL.md with appropriate frontmatter and body.
   

4. **Review for conciseness**: Check that Claude A hasn't added unnecessary explanations. Ask: "Remove the explanation of win rate — Claude already knows that."

5. **Improve information architecture**: Ask Claude A to reorganize. E.g.: "Put the table schema in a separate reference file. We might add more tables later."

6. **Test on similar tasks**: Use the Skill with Claude B (a fresh instance, Skill loaded) on related cases. Observe whether it finds the right information, applies rules correctly, and handles the task.

7. **Iterate based on observation**: If Claude B struggles, return to Claude A with specifics: "Using this Skill, Claude forgot to filter by date for Q4. Should we add a section on date filtering?"

**Iterating on existing Skills:**

The same pattern continues. You alternate between:

* **Working with Claude A** (the expert who refines the Skill)
* **Testing with Claude B** (the agent using the Skill for real work)
* **Observing Claude B's behavior** and bringing insights back to Claude A

1. **Use the Skill in real workflows**: Give Claude B actual tasks, not test scenarios

2. **Observe Claude B's behavior**: Note where it struggles, succeeds, or makes unexpected choices

   **Example observation**: "Asked for a regional sales report, Claude B wrote the query but forgot to filter out test accounts, though the Skill mentions this rule."

3. **Return to Claude A for improvements**: Share the current SKILL.md and what you observed. Ask: "Claude B forgot to filter test accounts for a regional report. The Skill mentions filtering — maybe not prominently enough?"

4. **Review Claude A's suggestions**: it might make rules more prominent, use stronger language ("MUST filter" vs "always filter"), or restructure the workflow section.

5. **Apply and test changes**: Update with Claude A's refinements, then test again with Claude B on similar requests

6. **Repeat based on usage**: Continue this observe-refine-test cycle as new scenarios arise. Each iteration improves the Skill on real agent behavior, not assumptions.

**Gathering team feedback:**

1. Share Skills with teammates and observe their usage
2. Ask: Does the Skill activate when expected? Are instructions clear? What's missing?
3. Incorporate feedback to address blind spots in your own usage

**Why this works**: Claude A understands agent needs, you provide domain expertise, Claude B reveals gaps through real usage, and refinement improves Skills on observed behavior, not assumptions.

### Observe how Claude navigates Skills

As you iterate, watch how Claude actually uses Skills:

* **Unexpected exploration paths**: Claude reads files in an order you didn't anticipate? Your structure may be less intuitive than you thought
* **Missed connections**: Claude fails to follow references? Your links may need to be more explicit or prominent
* **Overreliance on certain sections**: Claude repeatedly reads the same file? Move that content into SKILL.md
* **Ignored content**: Claude never accesses a bundled file? It may be unnecessary or poorly signaled

Iterate on these observations, not assumptions. The 'name' and 'description' metadata are especially critical — Claude uses them to decide whether to trigger the Skill. Make sure they clearly describe what the Skill does and when to use it.

## Anti-patterns to avoid

### Avoid Windows-style paths

Always use forward slashes in file paths, even on Windows:

* ✓ **Good**: `scripts/helper.py`, `reference/guide.md`
* ✗ **Avoid**: `scripts\helper.py`, `reference\guide.md`

Unix-style paths work everywhere; Windows-style ones fail on Unix systems.

### Avoid offering too many options

Don't present multiple approaches unless necessary:

````markdown
**Bad example: Too many choices** (confusing):
"You can use pypdf, or pdfplumber, or PyMuPDF, or pdf2image, or..."

**Good example: Provide a default** (with escape hatch):
"Use pdfplumber for text extraction:
```python
import pdfplumber
```

For scanned PDFs requiring OCR, use pdf2image with pytesseract instead."
````

## Advanced: Skills with executable code

The sections below cover Skills with executable scripts. If your Skill uses only markdown instructions, skip to [Checklist for effective Skills](#checklist-for-effective-skills).

### Solve, don't punt

When writing scripts for Skills, handle error conditions rather than punt to Claude.

**Good example: Handle errors explicitly**:

```python
def process_file(path):
    """Process a file, creating it if it doesn't exist."""
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        # Create file with default content instead of failing
        print(f"File {path} not found, creating default")
        with open(path, 'w') as f:
            f.write('')
        return ''
    except PermissionError:
        # Provide alternative instead of failing
        print(f"Cannot access {path}, using default")
        return ''
```

**Bad example: Punt to Claude**:

```python
def process_file(path):
    # Just fail and let Claude figure it out
    return open(path).read()
```

Justify and document configuration parameters to avoid "voodoo constants" (Ousterhout's law). If you don't know the right value, how will Claude?

**Good example: Self-documenting**:

```python
# HTTP requests typically complete within 30 seconds
# Longer timeout accounts for slow connections
REQUEST_TIMEOUT = 30

# Three retries balances reliability vs speed
# Most intermittent failures resolve by the second retry
MAX_RETRIES = 3
```

**Bad example: Magic numbers**:

```python
TIMEOUT = 47  # Why 47?
RETRIES = 5   # Why 5?
```

### Provide utility scripts

Even if Claude could write a script, pre-made scripts offer advantages:

**Benefits of utility scripts**:

* More reliable than generated code
* Save tokens (no need to include code in context)
* Save time (no code generation required)
* Ensure consistency across uses

An instruction file (e.g. forms.md) references the script, and Claude executes it without loading its contents.

**Important distinction**: Make clear whether Claude should:

* **Execute the script** (most common): "Run `analyze_form.py` to extract fields"
* **Read it as reference** (for complex logic): "See `analyze_form.py` for the field extraction algorithm"

For most utility scripts, prefer execution — more reliable and efficient. See [Runtime environment](#runtime-environment) below for how script execution works.

**Example**:

````markdown
## Utility scripts

**analyze_form.py**: Extract all form fields from PDF

```bash
python scripts/analyze_form.py input.pdf > fields.json
```

Output format:
```json
{
  "field_name": {"type": "text", "x": 100, "y": 200},
  "signature": {"type": "sig", "x": 150, "y": 500}
}
```

**validate_boxes.py**: Check for overlapping bounding boxes

```bash
python scripts/validate_boxes.py fields.json
# Returns: "OK" or lists conflicts
```

**fill_form.py**: Apply field values to PDF

```bash
python scripts/fill_form.py input.pdf fields.json output.pdf
```
````

### Use visual analysis

When inputs render as images, have Claude analyze them:

````markdown
## Form layout analysis

1. Convert PDF to images:
   ```bash
   python scripts/pdf_to_images.py form.pdf
   ```

2. Analyze each page image to identify form fields
3. Claude can see field locations and types visually
````

**Note:**
  In this example, you'd need to write the `pdf_to_images.py` script.


### Create verifiable intermediate outputs

Claude can make mistakes on complex, open-ended tasks. The "plan-validate-execute" pattern catches errors early: Claude creates a structured plan, then validates it with a script before executing.

**Example**: updating 50 PDF form fields from a spreadsheet. Without validation, Claude might reference non-existent fields, create conflicting values, miss required fields, or apply updates incorrectly.

**Solution**: Use the PDF form filling workflow above, adding an intermediate `changes.json` validated before applying changes. The workflow becomes: analyze → **create plan file** → **validate plan** → execute → verify.

**Why this pattern works:**

* **Catches errors early**: Validation finds problems before changes are applied
* **Machine-verifiable**: Scripts provide objective verification
* **Reversible planning**: Claude iterates on the plan without touching originals
* **Clear debugging**: Error messages point to specific problems

**When to use**: Batch operations, destructive changes, complex validation rules, high-stakes operations.

**Implementation tip**: Make validation scripts verbose with specific error messages like "Field 'signature\_date' not found. Available fields: customer\_name, order\_total, signature\_date\_signed" so Claude can fix issues.

### Package dependencies

Skills run in the code execution environment with platform-specific limitations:

* **claude.ai**: Can install packages from npm and PyPI and pull from GitHub repositories
* **Anthropic API**: Has no network access and no runtime package installation

List required packages in your SKILL.md and verify they're available in the [code execution tool documentation](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/code-execution-tool).

### Runtime environment

Skills run in a code execution environment with filesystem access and bash. For the concept, see [The Skills architecture](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview#the-skills-architecture) in the overview.

**How Claude accesses Skills:**

1. **Metadata pre-loaded**: At startup, each Skill's name and description load from YAML frontmatter into the system prompt
2. **Files read on-demand**: Claude uses bash Read tools to access SKILL.md and other files when needed
3. **Scripts executed efficiently**: Utility scripts run via bash without loading their contents; only output consumes tokens
4. **No context penalty for large files**: Reference files, data, or documentation don't consume tokens until read

* **File paths matter**: Claude navigates your skill directory like a filesystem. Use forward slashes (`reference/guide.md`), not backslashes
* **Name files descriptively**: Use names that indicate content: `form_validation_rules.md`, not `doc2.md`
* **Organize for discovery**: Structure directories by domain or feature
  * Good: `reference/finance.md`, `reference/sales.md`
  * Bad: `docs/file1.md`, `docs/file2.md`
* **Bundle comprehensive resources**: Include complete API docs, extensive examples, large datasets; no context penalty until accessed
* **Prefer scripts for deterministic operations**: Write `validate_form.py` rather than have Claude generate validation code
* **Make execution intent clear**:
  * "Run `analyze_form.py` to extract fields" (execute)
  * "See `analyze_form.py` for the extraction algorithm" (read as reference)
* **Test file access patterns**: Verify Claude can navigate your directory by testing with real requests

**Example:**

```
bigquery-skill/
├── SKILL.md (overview, points to reference files)
└── reference/
    ├── finance.md (revenue metrics)
    ├── sales.md (pipeline data)
    └── product.md (usage analytics)
```

Asked about revenue, Claude reads SKILL.md, sees the reference to `reference/finance.md`, and invokes bash to read just that file. sales.md and product.md stay on the filesystem, consuming zero tokens until needed. This filesystem model enables progressive disclosure — Claude selectively loads exactly what each task requires.

For complete technical architecture, see [How Skills work](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview#how-skills-work) in the Skills overview.

### MCP tool references

If your Skill uses MCP (Model Context Protocol) tools, always use fully qualified names to avoid "tool not found" errors.

**Format**: `ServerName:tool_name`

**Example**:

```markdown
Use the BigQuery:bigquery_schema tool to retrieve table schemas.
Use the GitHub:create_issue tool to create issues.
```

Where:

* `BigQuery` and `GitHub` are MCP server names
* `bigquery_schema` and `create_issue` are the tool names within those servers

Without the server prefix, Claude may fail to locate the tool, especially with multiple MCP servers available.

### Avoid assuming tools are installed

Don't assume packages are available:

````markdown
**Bad example: Assumes installation**:
"Use the pdf library to process the file."

**Good example: Explicit about dependencies**:
"Install required package: `pip install pypdf`

Then use it:
```python
from pypdf import PdfReader
reader = PdfReader("file.pdf")
```"
````

## Technical notes

### YAML frontmatter requirements

The SKILL.md frontmatter requires `name` (64 characters max) and `description` (1024 characters max) fields. See the [Skills overview](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview#skill-structure) for complete structure details.

### Token budgets

Keep SKILL.md body under 500 lines for optimal performance. If content exceeds this, split into separate files using the progressive disclosure patterns above. For architectural details, see the [Skills overview](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview#how-skills-work).

## Checklist for effective Skills

Before sharing a Skill, verify:

### Core quality

* [ ] Description is specific and includes key terms
* [ ] Description includes both what the Skill does and when to use it
* [ ] SKILL.md body is under 500 lines
* [ ] Additional details are in separate files (if needed)
* [ ] No time-sensitive information (or in "old patterns" section)
* [ ] Consistent terminology throughout
* [ ] Examples are concrete, not abstract
* [ ] File references are one level deep
* [ ] Progressive disclosure used appropriately
* [ ] Workflows have clear steps

### Code and scripts

* [ ] Scripts solve problems rather than punt to Claude
* [ ] Error handling is explicit and helpful
* [ ] No "voodoo constants" (all values justified)
* [ ] Required packages listed in instructions and verified as available
* [ ] Scripts have clear documentation
* [ ] No Windows-style paths (all forward slashes)
* [ ] Validation/verification steps for critical operations
* [ ] Feedback loops included for quality-critical tasks

### Testing

* [ ] At least three evaluations created
* [ ] Tested with Haiku, Sonnet, and Opus
* [ ] Tested with real usage scenarios
* [ ] Team feedback incorporated (if applicable)

## Next steps

- [Get started with Agent Skills](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/quickstart) — create your first Skill.
- [Use Skills in Claude Code](https://docs.anthropic.com/en/docs/claude-code/skills) — create and manage Skills in Claude Code.
- [Use Skills with the API](https://docs.anthropic.com/en/api/skills-guide) — upload and use Skills programmatically.
