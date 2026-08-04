# gp3sequences paper workspace

This directory contains the reproducible manuscript and supporting evidence
for a proposed R Journal article describing `gp3sequences`.

The directory is excluded through `.Rbuildignore`, so manuscript development
does not introduce a non-standard top-level directory into CRAN builds.

## Proposed article

**gp3sequences: Transparent, Reproducible, and Auditable Analysis of Ordered Categorical Sequences in R**

## Scope freeze

The paper describes the integrated architecture already implemented. It does
not justify adding public functions merely to enlarge the package. Further
changes should be limited to stable-release preparation, defect correction,
comparative evidence, benchmarking, replication materials, and manuscript work.

## Current state

- Development version: `0.2.0.9000`
- Current CRAN release: `0.1.0`
- Exported functions: `81`
- Package articles: `15`
- Test files: `22`

## Submission blockers

1. Release the manuscript-described functionality as CRAN version 0.2.0.
2. Freeze and permanently archive the exact release used by the manuscript.
3. Complete and verify the competing-software comparison.
4. Execute the benchmark plan and preserve machine-readable outputs.
5. Build one integrated case study that reproduces in under ten minutes.
6. Render the R Journal article in PDF and HTML.
7. Pass package, paper, and replication audits.

Only synthetic or openly licensed data may be added.
