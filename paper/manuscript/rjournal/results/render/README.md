# Render and R Journal check evidence

This directory records compact evidence from the latest successful local
render-and-check run. The actual HTML, PDF, TeX, generated master R file,
and transient LaTeX products remain under the ignored `build/` directory.

- `render-summary.csv`: rendered output sizes, hashes, build date, source
  commit, and tool versions.
- `rjtools-check-summary.csv`: raw success/note/warning/error counts,
  accepted and unresolved warning counts, and PDF page count.
- `rjtools-check-results.csv`: individual R Journal check results and the
  explicitly documented accepted exception.

## Documented rjtools template exception

`Rjournal.sty` is retained unchanged because the official R Journal article
template creates this style file and the submission source needs it to
rebuild the PDF. The installed checker nevertheless reports this exact file
as a non-standard root file. That single warning is preserved in the raw
evidence and marked as an accepted template exception. Every other warning
remains fatal.

The installed rjtools 1.0.21 `check_date()` implementation also resolves the
Rmd basename without joining it back to the supplied article path. The
recorded date result therefore applies the same YYYY-MM-DD/check-date rule
using the absolute Rmd path.

A clean technical gate means zero errors and zero unresolved warnings.
Notes and explicitly documented tool/template inconsistencies remain visible
for editorial review.
