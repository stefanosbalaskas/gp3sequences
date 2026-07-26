# Declare a sequence group-comparison design

Records the unit of assignment and the design under which a
sequence-group contrast will be evaluated. Causal interpretation is
permitted only for an explicitly randomized design and still depends on
the validity of the study implementation.

## Usage

``` r
declare_sequence_comparison_design(
  group_col,
  unit_col,
  design = c("observational", "randomized", "paired_randomized"),
  pair_col = NULL,
  cluster_col = NULL
)
```

## Arguments

- group_col:

  Group or treatment column.

- unit_col:

  Independent assignment or analysis-unit column.

- design:

  `"observational"`, `"randomized"`, or `"paired_randomized"`.

- pair_col:

  Pair or block column required for paired randomization.

- cluster_col:

  Optional higher-level assignment cluster.

## Value

An object of class `gp3_sequence_comparison_design`.

## Examples

``` r
declare_sequence_comparison_design("group", "participant_id",
                                   design = "randomized")
#> $group_col
#> [1] "group"
#> 
#> $unit_col
#> [1] "participant_id"
#> 
#> $design
#> [1] "randomized"
#> 
#> $pair_col
#> NULL
#> 
#> $cluster_col
#> NULL
#> 
#> $interpretation
#> [1] "randomization-based"
#> 
#> $call
#> declare_sequence_comparison_design(group_col = "group", unit_col = "participant_id", 
#>     design = "randomized")
#> 
#> attr(,"class")
#> [1] "gp3_sequence_comparison_design" "list"                          
```
