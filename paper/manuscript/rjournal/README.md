# gp3sequences R Journal manuscript

This directory contains the submission-oriented manuscript scaffold for:

**gp3sequences: Transparent, Reproducible, and Auditable Analysis of
Ordered Categorical Sequences in R**

## Current state

- R Journal R Markdown scaffold: complete
- verified software-comparison data: connected
- deterministic case-study data: created
- case-study analytical plan: created
- evaluated package case study: pending
- final author affiliation and address: pending
- HTML/PDF rendering: pending
- `rjtools` initial checks: pending until a `.tex` file exists
- CRAN 0.2.0 submission gate: blocked

## Structure

- `gp3sequences.Rmd`: main article
- `gp3sequences.bib`: manuscript bibliography
- `data/`: frozen manuscript inputs
- `figures/`: generated article figures
- `scripts/`: refresh, render, and checking scripts
- `results/`: generated diagnostics and environment records
- `motivation-letter/`: journal motivation-letter draft

## Workflow

From this directory, run:

```r
source("scripts/01-build-comparison-data.R")
source("scripts/02-build-case-study-data.R")
source("scripts/03-refresh-session-info.R")
source("scripts/04-render-article.R")
source("scripts/05-check-article.R")
```

Rendering and journal checks require `rjtools`, `rmarkdown`, `knitr`, Pandoc,
and a working LaTeX installation.
