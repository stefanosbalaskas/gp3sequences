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
#> $comparisons
#>           field
#> 1        family
#> 2 primary_class
#> 3        method
#> 4  sequence_ids
#> 5  state_levels
#> 6          seed
#> 7      settings
#>                                                                                                                                                                                    x
#> 1                                                                                                                                                                           distance
#> 2                                                                                                                                                              gp3_sequence_distance
#> 3                                                                                                                                                                        levenshtein
#> 4                                                                                                                                                                       s1 | s2 | s3
#> 5                                                                                                                                                                          A | B | C
#> 6                                                                                                                                                                                 NA
#> 7 List of 5 |  $ indel_cost          : num 1 |  $ substitution_cost   : num 1 |  $ substitution_matrix : NULL |  $ transition_smoothing: num 0 |  $ normalise           : chr "none"
#>                                                                                                                                                                                    y
#> 1                                                                                                                                                                           distance
#> 2                                                                                                                                                              gp3_sequence_distance
#> 3                                                                                                                                                                        levenshtein
#> 4                                                                                                                                                                       s1 | s2 | s3
#> 5                                                                                                                                                                          A | B | C
#> 6                                                                                                                                                                                 NA
#> 7 List of 5 |  $ indel_cost          : num 1 |  $ substitution_cost   : num 1 |  $ substitution_matrix : NULL |  $ transition_smoothing: num 0 |  $ normalise           : chr "none"
#>   equal
#> 1  TRUE
#> 2  TRUE
#> 3  TRUE
#> 4  TRUE
#> 5  TRUE
#> 6  TRUE
#> 7  TRUE
#> 
#> $x_audit
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
#> 
#> $y_audit
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
#> 
#> $value_comparison
#> NULL
#> 
#> $all_equal
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "gp3_sequence_analysis_comparison" "list"                            
```
