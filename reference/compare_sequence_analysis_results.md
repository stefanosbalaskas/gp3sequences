# Compare two gp3sequences analysis results

Compares structural contracts and recoverable provenance from two
analysis objects. This helper is intended for regression checks,
sensitivity analyses, and reproducibility audits; it does not select a
statistically or substantively "best" analysis.

## Usage

``` r
compare_sequence_analysis_results(
  x,
  y,
  tolerance = 1e-08,
  compare_values = FALSE
)
```

## Arguments

- x, y:

  Two analysis objects.

- tolerance:

  Numerical comparison tolerance.

- compare_values:

  Logical; when `TRUE`, also run
  [`all.equal()`](https://rdrr.io/r/base/all.equal.html) on the complete
  objects after structural comparison.

## Value

An object of class `gp3_sequence_analysis_comparison` containing
per-field comparisons, both audits, optional whole-object comparison,
and an overall equality flag.

## Examples

``` r
sequences <- data.frame(
  sequence_id = rep(c("s1", "s2", "s3"), each = 3L),
  sequence_order = rep(1:3, times = 3L),
  state = c(
    "A", "B", "C",
    "A", "B", "B",
    "C", "B", "A"
  )
)
d1 <- compute_sequence_distance(
  sequences,
  method = "levenshtein"
)
d2 <- compute_sequence_distance(
  sequences,
  method = "levenshtein"
)
compare_sequence_analysis_results(d1, d2)
#> Error in compare_sequence_analysis_results(d1, d2): could not find function "compare_sequence_analysis_results"
```
