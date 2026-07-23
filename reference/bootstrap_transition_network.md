# Bootstrap transition-network edge weights

Bootstrap transition-network edge weights

## Usage

``` r
bootstrap_transition_network(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  n_boot = 100L,
  level = 0.95,
  seed = 1L,
  include_self = TRUE
)
```

## Arguments

- data:

  Long-format sequence data.

- sequence_id_col, order_col, state_col:

  Sequence columns.

- n_boot:

  Number of bootstrap samples of whole sequences.

- level:

  Confidence level for percentile intervals.

- seed:

  Reproducibility seed.

- include_self:

  Include self-transitions.

## Value

A data frame containing observed edge weights, bootstrap means, standard
deviations, and percentile intervals.

## Examples

``` r
sequences <- data.frame(
  sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
  sequence_order = rep(1:4, times = 4L),
  state = c("A", "B", "C", "D", "A", "B", "C", "C",
            "D", "C", "B", "A", "D", "C", "A", "A"),
  group = rep(c("g1", "g2"), each = 8L),
  stringsAsFactors = FALSE
)
bootstrap_transition_network(sequences, n_boot = 5L, seed = 1L)
#>   group_key context from_state to_state count sequence_count
#> 1   __all__       A          A        A     1              1
#> 2   __all__       A          A        B     2              2
#> 3   __all__       B          B        A     1              1
#> 4   __all__       B          B        C     2              2
#> 5   __all__       C          C        A     1              1
#> 6   __all__       C          C        B     1              1
#> 7   __all__       C          C        C     1              1
#> 8   __all__       C          C        D     1              1
#> 9   __all__       D          D        C     2              2
#>   sequence_prevalence    weight bootstrap_mean bootstrap_sd conf_low conf_high
#> 1                0.25 0.3333333     0.06666667    0.1490712    0.000     0.300
#> 2                0.50 0.6666667     0.93333333    0.1490712    0.700     1.000
#> 3                0.25 0.3333333     0.31666667    0.2074983    0.025     0.500
#> 4                0.50 0.6666667     0.68333333    0.2074983    0.500     0.975
#> 5                0.25 0.2500000     0.05000000    0.1118034    0.000     0.225
#> 6                0.25 0.2500000     0.30000000    0.2091650    0.025     0.500
#> 7                0.25 0.2500000     0.35000000    0.2850439    0.025     0.725
#> 8                0.25 0.2500000     0.30000000    0.3259601    0.000     0.725
#> 9                0.50 1.0000000     0.80000000    0.4472136    0.100     1.000
#>   n_boot confidence_level
#> 1      5             0.95
#> 2      5             0.95
#> 3      5             0.95
#> 4      5             0.95
#> 5      5             0.95
#> 6      5             0.95
#> 7      5             0.95
#> 8      5             0.95
#> 9      5             0.95
```
