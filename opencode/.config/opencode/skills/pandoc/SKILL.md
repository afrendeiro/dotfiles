---
name: pandoc
description: Use when converting documents with pandoc — markdown to DOCX, HTML, reveal.js slides, or PDF via xelatex. Covers this machine's engines and fonts, styling recipes, and troubleshooting.
---

# Pandoc

## Environment (this machine)

- `pandoc` 3.10.2, Lua 5.4 scripting enabled.
- PDF engines: `xelatex`, `lualatex`, `pdflatex` (TeX Live). **Prefer
  `--pdf-engine=xelatex`** — Unicode-safe and font-capable via fontspec.
  Packages `geometry`, `booktabs`, `longtable`, `fontspec`, `microtype` are
  present (check others with `kpsewhich <pkg>.sty`).
- NOT installed: typst, tectonic, wkhtmltopdf, weasyprint — do not propose
  them as alternatives.
- Fonts: Lato (sans), Liberation Serif/Sans, Nimbus, DejaVu families. No
  Inter/Source families — don't reference fonts that don't exist.
- No custom `~/.pandoc` templates or reference docs yet; defaults are fine.
- Verification tools: `file`, `pdftoppm`, `pdftotext` (poppler).

## Rules

- Output format comes from the `-o` extension — always pass an explicit `-o`.
- Standalone output (`-s`) for HTML, slides, and anything with metadata.
- Self-contained HTML uses `--embed-resources --standalone`
  (`--self-contained` is deprecated in pandoc 3.x).
- DOCX/PPTX styling: generate a reference doc once
  (`pandoc --print-default-data-file reference.docx > ref.docx`), edit it in
  Word/LibreOffice, then pass `--reference-doc=ref.docx`.
- LaTeX styling goes through `-V <var>=<value>` (geometry, fonts, links).
- Verify output after converting (see Verification).
- No citation workflow on this machine: don't introduce `--citeproc`/
  `--bibliography` recipes unless asked.

## Recipes

### Markdown → DOCX

```bash
pandoc in.md -o out.docx
pandoc in.md -o out.docx --reference-doc=ref.docx   # with custom styling
```

### Markdown → standalone HTML

```bash
pandoc in.md -o out.html -s --embed-resources --syntax-highlighting=tango
```

(`--highlight-style` is deprecated in pandoc 3.10+ — use
`--syntax-highlighting`.)

### Markdown → reveal.js slides

```bash
pandoc in.md -o slides.html -s -t revealjs
```

Slide deck metadata goes in the document's YAML block (title, author, date,
plus `theme`, `transition`, `slide-number`). Use `--slide-level=N` if heading
levels don't match your intended slide split. By default reveal.js assets load
from a CDN — for offline decks add `--embed-resources` (downloads/references
local assets where possible).

### Markdown → PDF (xelatex)

```bash
pandoc in.md -o out.pdf --pdf-engine=xelatex
pandoc in.md -o out.pdf --pdf-engine=xelatex \
  -V geometry:margin=2.5cm \
  -V mainfont="Lato" \
  -V sansfont="Lato" \
  -V monofont="DejaVu Sans Mono" \
  -V fontsize=11pt \
  -V colorlinks=true
```

### Merging multiple files

Order is preserved; a shared YAML block in the first file applies globally.

```bash
pandoc 01-intro.md 02-methods.md 03-results.md -o paper.pdf --pdf-engine=xelatex
```

### YAML metadata

```yaml
---
title: My document
author: Andre Rendeiro
date: 2026-08-20
---
```

For PDF, metadata can also be passed as flags: `-V title="..." -V author="..."`.

## Troubleshooting

- **LaTeX error "undefined control sequence" / missing package**: check the
  package exists with `kpsewhich <pkg>.sty` before assuming pandoc's fault.
- **Missing glyph / font warnings (xelatex)**: switch `-V mainfont` to an
  installed family (`fc-list : family | sort -u`), or fall back to the default
  Latin Modern.
- **Wide tables overflow the page**: reduce margins
  (`-V geometry:margin=2cm`), use a smaller font, or convert the pipe table to
  a grid table.
- **Non-ASCII garbled or missing in PDF**: use `--pdf-engine=xelatex` (not
  pdflatex) and set a Unicode-capable `-V mainfont`.
- **reveal.js slides look unstyled offline**: assets come from a CDN by
  default; re-render with `--embed-resources`.
- **pandoc 3.x**: `--self-contained` no longer exists — use
  `--embed-resources --standalone`.

## Verification

```bash
file out.pdf            # must say "PDF document"
pdftoppm -png -f 1 -l 1 -r 72 out.pdf /tmp/pandoc-check   # inspect first page
pdftotext out.pdf - | head -20                            # text sanity check
```

For DOCX/HTML: confirm the file exists and is non-empty (`file`, `ls -l`).
