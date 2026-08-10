# Reproducing the gp3sequences R Journal submission

This submission includes a Git bundle named
`gp3sequences-f28c9fd.bundle` containing the exact repository state
used for the final manuscript and portability validation.

## Frozen source state

- Repository: `stefanosbalaskas/gp3sequences`
- Branch: `paper/rjournal-publication`
- Commit: `f28c9fd049223ef3222a56cf24538f0f10749cf4`
- Package version: `0.2.0.9000`
- Case-study seed: `20260807`

The bundled source should be used for reproduction rather than installing
the public CRAN release, because the manuscript evaluates development
version `0.2.0.9000`.

## R packages

Install the add-on packages listed in `_Rpackages.txt` before running the
workflow. Standard base R packages are not listed.

The validated workflow uses `qpdf` for PDF page inspection. `pdftools` is
supported by the project scripts as an alternative PDF-inspection route.
`tinytex` can provide a LaTeX installation when `pdflatex` is otherwise
unavailable.

Pandoc and a working LaTeX installation are required to rebuild the PDF.

## Reconstruct the exact repository

From the directory containing the submission files, run:

```sh
git clone --branch paper/rjournal-publication gp3sequences-f28c9fd.bundle gp3sequences
cd gp3sequences
```

Verify the source state:

```sh
git rev-parse HEAD
git status --short
```

The expected commit is:

```text
f28c9fd049223ef3222a56cf24538f0f10749cf4
```

and the working tree should initially be clean.

## Reproduce the evaluated case study

From the reconstructed repository root, run:

```sh
Rscript --vanilla paper/manuscript/rjournal/scripts/06-run-evaluated-case-study.R
```

Then run the committed case-study audit:

```sh
Rscript --vanilla dev/validation/audit-rjournal-evaluated-case-study.R
```

The workflow regenerates the 20 manifest-declared case-study artifacts.
Session information is environment-specific; the substantive tables,
figures, and numerical outputs are deterministic under the declared source
state and fixed seed.

## Rebuild and check the article

Run:

```sh
Rscript --vanilla paper/manuscript/rjournal/scripts/07-render-and-check-article.R
```

The generated article products are written under:

`paper/manuscript/rjournal/build/`

The validated workflow produces a 12-page PDF and completes the project
R Journal checks with zero errors and zero unresolved warnings. The
`Rjournal.sty` folder-structure warning is retained as an accepted exception
because that file is the unchanged R Journal template style required for
reproducible PDF rebuilding.

## Portability validation

Before submission, the Git bundle was independently cloned into a disposable
external workspace. The unchanged authoritative runner reproduced all 19
substantive computational outputs exactly, the existing case-study audit
passed, the article render/check workflow passed, and total reproduction
completed within the R Journal's 10-minute reproduction limit.

The Git bundle itself is approximately 0.531 MB.
