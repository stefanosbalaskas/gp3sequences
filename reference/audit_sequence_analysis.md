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
#> $summary
#>     family         primary_class package_version contract_version      method
#> 1 distance gp3_sequence_distance      0.2.0.9000 0.3.0-contract-1 levenshtein
#>   n_sequence_ids n_state_levels seed_recorded n_issues status
#> 1              3              3         FALSE        0   pass
#> 
#> $issues
#> [1] code     severity field    message 
#> <0 rows> (or 0-length row.names)
#> 
#> $provenance
#> $provenance$package
#> [1] "gp3sequences"
#> 
#> $provenance$package_version
#> [1] "0.2.0.9000"
#> 
#> $provenance$contract_version
#> [1] "0.3.0-contract-1"
#> 
#> $provenance$family
#> [1] "distance"
#> 
#> $provenance$method
#> [1] "levenshtein"
#> 
#> $provenance$sequence_ids
#> [1] "s1" "s2" "s3"
#> 
#> $provenance$state_levels
#> [1] "A" "B" "C"
#> 
#> $provenance$seed
#> [1] NA
#> 
#> $provenance$settings
#> $provenance$settings$indel_cost
#> [1] 1
#> 
#> $provenance$settings$substitution_cost
#> [1] 1
#> 
#> $provenance$settings$substitution_matrix
#> NULL
#> 
#> $provenance$settings$transition_smoothing
#> [1] 0
#> 
#> $provenance$settings$normalise
#> [1] "none"
#> 
#> 
#> 
#> $contract
#> $contract$contract_version
#> [1] "0.3.0-contract-1"
#> 
#> $contract$family
#> [1] "distance"
#> 
#> $contract$primary_class
#> [1] "gp3_sequence_distance"
#> 
#> $contract$required_fields
#> [1] "method"       "sequence_ids" "state_levels" "settings"    
#> 
#> 
#> $status
#> [1] "pass"
#> 
#> attr(,"class")
#> [1] "gp3_sequence_analysis_audit" "list"                       
```
