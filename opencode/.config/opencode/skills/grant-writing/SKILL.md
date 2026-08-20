---
name: grant-writing
description: Use when drafting, revising, or assembling a funding/grant proposal written in Markdown, converting Markdown to .docx/.pdf for submission, starting a new grant project folder, or applying this developer's grant-writing voice to proposal text. Covers the markdown-first project layout, proposal structure per funding-program template, the pandoc + LibreOffice build pipeline, and the writing style. Never use for non-proposal documents.
---

# Grant writing workflow

Grant proposals are written in Markdown, versioned with git, and rendered on
demand to .docx (via pandoc with a reference template) and .pdf (via
LibreOffice). The source of truth is always the Markdown; generated
.docx/.pdf files are disposable build artifacts.

This skill encodes the workflow, the build toolchain, and the writing voice.
It must stay generic: never mention any specific funding program, agency,
call, consortium, project, partner, dataset, figure, deadline, budget, or
proposal content — including in examples. If a user shares proposal material,
use it as input context but do not carry its specifics into the skill or into
other projects.

## Critical rules

1. **Markdown is the source of truth.** Never hand-edit generated .docx/.pdf
   files. Edit Markdown and rebuild.
2. **Never invent numbers, partners, letters of support, or consortium
   details.** All claims must come from user-provided material.
3. **Generated artifacts are disposable.** Build outputs (.docx/.pdf) are
   gitignored; only source Markdown and the reference template are tracked.
4. **Write with the house voice** (see Writing voice) — acknowledge the field
   first, never critique it, never overclaim.
5. **Map every section to the funding program's evaluation criteria.** The
   reviewers score against explicit criteria; the structure must mirror them.
6. **Never leak content across projects.** The skill and templates contain no
   real proposal material. Do not copy text, names, or figures from one
   proposal into another.
7. **Headings and titles use sentence case: capitalize only the first word
   and proper nouns, always.** This applies to proposal headings, document
   titles, and to any headings written by or for this workflow. No
   title-case ("State Of The Art") and no all-caps.

## Project layout

A standard grant project directory:

```
<grant-project>/
├── grant.md              # master proposal (the deliverable)
├── plan.md               # roadmap: narrative, strengths/weaknesses, criteria mapping, writing order
├── options.md            # (optional) program/agency comparison analysis
├── justfile              # build orchestration
├── .gitignore            # ignores generated artifacts, keeps the reference template
├── ref.docx              # pandoc reference template (styles only, no content)
├── resources/            # distilled call specs, lessons learned, partner material
├── _style/               # reusable style guides
├── _archive/             # dated snapshots of earlier drafts
└── graphical_abstract/   # (optional) figures
```

When invoked in an existing project, **adopt**: detect and reuse the existing
naming, structure, and justfile. Only **scaffold** a new skeleton when the
user explicitly asks to start a new project.

### .gitignore pattern

Ignore build artifacts but keep the styling template:

```gitignore
*.pdf
*.docx
*.odt
!ref.docx
```

## Build pipeline

### Canonical chain

1. `pandoc grant.md -o grant.docx --reference-doc=ref.docx`
2. `libreoffice --headless --convert-to pdf --outdir . grant.docx`

Pandoc needs `--reference-doc` (a .docx whose styles define the look) — the
default output lacks the desired typography. LibreOffice (not pandoc's PDF
engines) renders the docx with its styles intact.

### justfile recipe

```make
_pandoc := "pandoc"
_ref := "ref.docx"

default:
    @just --list

build:
    {{_pandoc}} grant.md -o grant.docx --reference-doc={{_ref}}
    libreoffice --headless --convert-to pdf --outdir . grant.docx

clean:
    rm -f grant.docx grant.pdf
```

### Variants seen in practice

- **Split-section proposals**: source is multiple Markdown files (one per
  template section, often under `proposal/` or `tables/`). Concatenate in
  order, then clean markers (e.g. HTML comments, checkbox markers, `---`
  separators) before pandoc:
  ```make
  build:
      awk 'FNR==1 && NR>1 {print ""} 1' {{files}} > combined.md
      sed -i -e '/<!--/d' -e 's/^- \[ \] //' -e '/^---$/d' combined.md
      pandoc -f markdown -s combined.md -o out.docx --reference-doc=template.docx
      libreoffice --headless --convert-to pdf --outdir . out.docx
  ```
- **Post-processing**: some docx need a python-docx pass (e.g. column layout,
  bibliography formatting) after pandoc — wire it as a step between pandoc and
  LibreOffice.
- **References**: when a proposal cites sources, use a `references.bib` +
  CSL style with `--citeproc` and `--resource-path=.` so assets resolve.

### Reference template

`ref.docx` is a pandoc reference document — **styles only, no real content**.
A neutral default ships with this skill (see `templates/ref.docx`). To
customize (fonts, heading sizes), edit the template's styles in a word
processor and rebuild; never put placeholder proposal text into it.

## Proposal structure

Structures vary by program. The default is the **single-investigator
research grant** shape; adapt it to the program's template when they differ.

### Single-investigator research grants (default)

This is the standard structure for an investigator-driven research project
with one principal investigator (and optionally collaborators). It is a
standalone narrative document with annexes:

1. **Cover** — program name, proposal title (sentence case), principal
   investigator name, institution, date
2. **Table of contents**
3. **The proposal in 1 minute** — plain-language summary of the problem, the
   approach, and the expected outcome
4. **Abbreviations**
5. **State of the art** — the underlying scientific foundation: acknowledge
   the field's progress (conciliatory pivot), then the gap and why it
   matters; named landmarks cited
6. **Preliminary work** — the applicant's own results establishing
   feasibility: published results, unpublished analyses, and proof-of-concept
   (with figures)
7. **Research questions, hypotheses, and goals** — the central hypothesis,
   the specific questions it raises, and concrete bulleted goals
8. **Originality and innovation** — what is conceptually and methodologically
   distinct from prior work, and why it matters
9. **Methodology** — the technical approach, organized into work packages
   (see Work package template below)
10. **Risk assessment and learning potential** — named risks with
    mitigations, plus the learning potential in the event of failure: what
    knowledge is gained even if the main hypothesis fails
11. **Work plan and timeline** — a timeline chart (Gantt-style) plus a
    year-by-year narrative of what happens when
12. **Cooperation** — named collaborators, each with their expertise and what
    they contribute (data access, validation, interpretation)
13. **Qualification of researchers** — the PI profile, the team composition,
    and the commitment to open science
14. **Ethical and regulatory aspects** — data use agreements, compliance,
    research integrity
15. **Sex- and gender-specific aspects** — how sex/gender are handled in
    design, analysis, and reporting
16. **Annexes** — references; host institution and justification of requested
    funding (personnel, travel, overhead, equipment — with amounts); academic
    CV (personal details, positions, education, grants, publications,
    patents, community contributions); collaboration letters

### Structured-portal programs

Some programs collect submission through a web portal with fixed sections.
Mirror the portal's structure exactly — reviewers expect sections to line up
with criteria:

1. **Content description** — motivation, state of the art, innovation,
   objectives, approach, benefits, exploitation, risks, gender/sustainability,
   ethics, and the "incentive effect" (what happens without funding)
2. **Work plan** — work packages with lead partner, month ranges, activities,
   deliverables, risks; a timeline (Gantt-style) and milestones
3. **Consortium** — per-partner profiles: institution, key personnel with
   bios, resources, role
4. **Cost and financing** — per-partner, per-category budget; compliance with
   distribution rules

### Split-file template programs

Submission follows a fixed template (often per-section files). Create one
Markdown file per section, keep tables (deliverables, milestones, risks,
effort) in a `tables/` dir, and concatenate at build time.

### Work package template

Work packages live inside the Methodology section. Each work package should
include:

- **Lead** — who is responsible
- **Time period** — which months of the project
- **Detailed activities** — a step-by-step description, from foundational
  work to implementation, testing, and integration; bulleted
- **Expected outcomes and deliverables** — concrete outputs with months
  (software, datasets, reports, publications)
- **Team** — named individuals and their effort
- **Risks** — explicit risks with mitigations (or point to the risk section)

## Writing voice

Distilled writing conventions. Apply to all proposal prose.

### The conciliatory pivot

The fundamental rhetorical structure of every section:

1. Acknowledge progress — "The field has made remarkable progress [specific
   accomplishments, named frameworks or investigators]."
2. Pivot to a gap — "Yet [a specific gap remains]."
3. Offer the contribution as the natural next step — "Our work addresses
   this gap by [approach]."

Never start with critique. The gap is an **opportunity** the field is ready
for, not a failure of prior efforts.

### Framing the gap

Never: "the field has failed to…", "we have overlooked…", "this has been
ignored…", "nobody is asking…".

Instead: "yet a gap remains", "a cohesive account remains elusive", "our
understanding remains incomplete", "has received less systematic attention
than it deserves", "often remain limited in scope".

### Positioning the contribution

Never: "this project shows the field is wrong…".

Instead, future-oriented: "will establish", "aims to", "is positioned to".
Position the work as completing or enabling what the field built, not
correcting it. End paragraphs on forward-looking statements.

### Specific techniques

1. **Cite the landmarks** — name the key frameworks, tools, and investigators.
   Never say "progress has been made" without naming what and by whom.
2. **Inclusive "we"** for the field; avoid lab-first boasting.
3. **Acknowledge scope limitations respectfully** — "this dimension remains
   to be characterized", not "the prior work is insufficient".
4. **Every claim has specifics** — dataset/tool/partner names, months, costs,
   exact timeframes. No vague quantities.
5. **Be honest about limitations** — acknowledge competitor strengths and
   name risks with mitigations; reviewers trust proposals that admit
   uncertainty.
6. **Headings and titles are sentence case** — only the first word and
   proper nouns are capitalized, always. This applies throughout the
   proposal, including work package titles and annex names.

### Words to avoid

| Avoid | Use instead |
|---|---|
| "neglected" | "has received less systematic attention" |
| "ignored" | "has been understudied relative to its importance" |
| "the field has no answer" | "a cohesive account remains elusive" |
| "missing" | "represents a dimension that has received less attention" |
| "nobody is asking" | "this question has received little systematic study" |
| "failed" | "remains to be fully characterized" |
| "groundbreaking / revolutionary" | confident, measured claims with evidence |

### Tone calibration

| Document | Tone |
|---|---|
| Funding proposal | Confident, respectful of the field, evidence-backed |
| Perspective article | Argumentative but collegial |
| Review article | Neutral curator |

## Iterative workflow

Proposals improve in rounds driven by feedback (internal reviews, partner
input, or reviewer-style critiques):

1. Draft against the program's criteria, not the other way around.
2. Get feedback; revise section by section; keep a plan doc updated.
3. **Commit per round** with a message summarizing what changed and why
   (e.g. "Round 2: reframed core methods, added risk analysis, adjusted
   staffing"). The git history doubles as a revision log.
4. Archive superseded drafts to `_archive/` with dates rather than deleting.
5. Rebuild artifacts only when needed (or before sharing a snapshot).

## Scaffolding a new project

When asked to start a new project:

1. Create the directory layout from this skill's Project layout section.
2. Copy `templates/justfile.example` → `justfile`, `templates/.gitignore.example`
   → `.gitignore`, and `templates/ref.docx` → `ref.docx`.
3. Ask the user for the funding program, submission structure, partners,
   budget, and deadline before drafting any content.
4. Distill any call documentation the user provides into `resources/call-specs.md`
   (criteria with thresholds, eligibility rules, cost rules, consortium
   requirements) — this drives the proposal structure and writing order.
5. Create a `plan.md` capturing narrative, strengths/weaknesses, criteria
   mapping, and writing order; then draft `grant.md`.

## Templates

See `templates/` in this skill's directory:
- `justfile.example` — canonical build/clean recipe
- `.gitignore.example` — artifact hygiene
- `ref.docx` — neutral pandoc reference template (styles only)
