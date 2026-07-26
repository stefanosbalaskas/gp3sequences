# Test a sequence group difference

Aggregates sequence metrics to the declared independent unit and
performs a permutation or randomization test. For observational data the
p-value tests exchangeability-based association only; it is not a causal
estimate.

## Usage

``` r
test_sequence_group_difference(
  data,
  design,
  metric = c("sequence_length", "transition_count", "state_prevalence",
    "subsequence_presence"),
  target_state = NULL,
  target_subsequence = NULL,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  separator = " > ",
  n_permutations = 999L,
  alternative = c("two.sided", "greater", "less"),
  seed = 1L
)
```

## Arguments

- data:

  Long-format sequence data.

- design:

  A comparison design.

- metric:

  `"sequence_length"`, `"transition_count"`, `"state_prevalence"`, or
  `"subsequence_presence"`.

- target_state:

  Required for state prevalence.

- target_subsequence:

  Required for subsequence presence, expressed using `separator`.

- sequence_id_col, order_col, state_col:

  Core sequence columns.

- separator:

  Subsequence label separator.

- n_permutations:

  Number of permutations.

- alternative:

  Alternative hypothesis.

- seed:

  Reproducibility seed.

## Value

An object of class `gp3_sequence_group_inference`.

## Examples

``` r
data <- data.frame(
  participant_id = rep(paste0("p", 1:8), each = 4L),
  sequence_id = rep(paste0("s", 1:8), each = 4L),
  sequence_order = rep(1:4, times = 8L),
  state = c(rep(c("A", "B", "C", "D"), 4L),
            rep(c("A", "A", "C", "D"), 4L)),
  group = rep(rep(c("control", "treatment"), each = 4L), each = 4L)
)
design <- declare_sequence_comparison_design("group", "participant_id",
                                             design = "randomized")
test_sequence_group_difference(data, design, metric = "state_prevalence",
                               target_state = "A", n_permutations = 99L)
#> $estimate
#>   group_1   group_2 mean_group_1 mean_group_2 difference_group_2_minus_group_1
#> 1 control treatment         0.25          0.5                             0.25
#>   p_value alternative n_permutations
#> 1    0.05   two.sided             99
#> 
#> $permutation_distribution
#>  [1]  0.125  0.125  0.000 -0.125  0.250  0.000  0.125 -0.125  0.125  0.000
#> [11] -0.125 -0.125  0.000  0.000 -0.125  0.000  0.000  0.000  0.000  0.000
#> [21]  0.250 -0.125 -0.125  0.125 -0.125  0.125  0.000  0.000  0.000 -0.125
#> [31]  0.000  0.000  0.000 -0.125 -0.125  0.000  0.000  0.000  0.000  0.000
#> [41]  0.000 -0.125  0.250 -0.250  0.125  0.000  0.000 -0.125  0.000  0.000
#> [51]  0.000  0.000  0.125  0.000  0.000  0.000  0.000  0.000  0.000  0.125
#> [61]  0.000  0.000  0.125  0.000  0.125 -0.125  0.000  0.125  0.000  0.000
#> [71] -0.125  0.000 -0.125  0.125 -0.125  0.000  0.000  0.000  0.000 -0.125
#> [81]  0.000  0.000  0.000 -0.125  0.000  0.125  0.000  0.000  0.125  0.125
#> [91]  0.125 -0.125  0.000  0.000  0.000  0.000 -0.125  0.125 -0.125
#> 
#> $unit_data
#>   participant_id     group metric n_sequences
#> 1             p1   control   0.25           1
#> 2             p2   control   0.25           1
#> 3             p3   control   0.25           1
#> 4             p4   control   0.25           1
#> 5             p5 treatment   0.50           1
#> 6             p6 treatment   0.50           1
#> 7             p7 treatment   0.50           1
#> 8             p8 treatment   0.50           1
#> 
#> $sequence_data
#>   sequence_id metric     group participant_id
#> 1          s1   0.25   control             p1
#> 2          s2   0.25   control             p2
#> 3          s3   0.25   control             p3
#> 4          s4   0.25   control             p4
#> 5          s5   0.50 treatment             p5
#> 6          s6   0.50 treatment             p6
#> 7          s7   0.50 treatment             p7
#> 8          s8   0.50 treatment             p8
#> 
#> $design
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
#> 
#> $metric
#> [1] "state_prevalence"
#> 
#> $target_state
#> [1] "A"
#> 
#> $target_subsequence
#> NULL
#> 
#> $interpretation
#> [1] "Randomization-based contrast, conditional on valid assignment and study implementation."
#> 
#> $seed
#> [1] 1
#> 
#> $call
#> test_sequence_group_difference(data = data, design = design, 
#>     metric = "state_prevalence", target_state = "A", n_permutations = 99L)
#> 
#> attr(,"class")
#> [1] "gp3_sequence_group_inference" "list"                        
```
