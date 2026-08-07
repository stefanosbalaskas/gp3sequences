# Audit a gp3sequences analysis object

Inspects supported gp3sequences objects for structural contract
validity, recoverable provenance, identifiers, state levels, method
settings, and randomness metadata. The audit does not reinterpret
sequence structure as a psychological, diagnostic, cognitive, emotional,
or causal construct.

## Usage

``` r
audit_sequence_analysis(x, strict = FALSE, tolerance = 1e-08)
```

## Arguments

- x:

  A gp3sequences analysis result or supported structural object.

- strict:

  Logical; if `TRUE`, fail when the audit status is `"fail"`.

- tolerance:

  Numerical tolerance used for matrix/probability checks.

## Value

An object of class `gp3_sequence_analysis_audit` containing `summary`,
`issues`, `provenance`, `contract`, and `status`.

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
distance <- compute_sequence_distance(
  sequences,
  method = "levenshtein"
)
audit_sequence_analysis(distance)
#> Error in audit_sequence_analysis(distance): could not find function "audit_sequence_analysis"
```
