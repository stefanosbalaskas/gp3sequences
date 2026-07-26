# Summarise a sequence panel

Summarise a sequence panel

## Usage

``` r
summarise_sequence_panel(panel)
```

## Arguments

- panel:

  A result from
  [`prepare_sequence_panel()`](https://stefanosbalaskas.github.io/gp3sequences/reference/prepare_sequence_panel.md).

## Value

A list with occasion-level sequence summaries and state prevalence.

## Examples

``` r
panel_data <- data.frame(
  participant_id = rep(c("p1", "p2"), each = 6L),
  occasion = rep(rep(c(1, 2), each = 3L), times = 2L),
  sequence_id = rep(c("a", "b", "c", "d"), each = 3L),
  sequence_order = rep(1:3, times = 4L),
  state = c("A", "B", "C", "A", "C", "C", "C", "B", "A", "C", "B", "B")
)
summarise_sequence_panel(prepare_sequence_panel(panel_data, "participant_id", "occasion"))
#> $occasions
#>   occasion n_panels n_sequences mean_length median_length mean_transitions
#> 1        1        2           2           3             3                2
#> 2        2        2           2           3             3                2
#> 
#> $states
#>   occasion state occurrence_count occurrence_share sequence_count
#> 1        1     A                2        0.3333333              2
#> 2        1     B                2        0.3333333              2
#> 3        1     C                2        0.3333333              2
#> 4        2     A                1        0.1666667              1
#> 5        2     B                2        0.3333333              1
#> 6        2     C                3        0.5000000              2
#>   sequence_prevalence
#> 1                 1.0
#> 2                 1.0
#> 3                 1.0
#> 4                 0.5
#> 5                 0.5
#> 6                 1.0
#> 
#> $n_panels
#> [1] 2
#> 
#> $n_occasions
#> [1] 2
#> 
#> $state_levels
#> [1] "A" "B" "C"
#> 
```
