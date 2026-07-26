# Compare within-panel sequence changes

Computes distance and simple structural changes between consecutive
panel occasions. The output is descriptive and does not establish a
causal or psychological change.

## Usage

``` r
compare_sequence_panel_changes(
  panel,
  method = c("levenshtein", "lcs", "optimal_matching", "transition"),
  normalise = c("none", "max_length", "path_length"),
  indel_cost = 1,
  substitution_cost = 1,
  substitution_matrix = NULL,
  transition_smoothing = 0
)
```

## Arguments

- panel:

  A sequence panel.

- method:

  Distance method supported by
  [`compute_sequence_distance()`](https://stefanosbalaskas.github.io/gp3sequences/reference/compute_sequence_distance.md).

- normalise:

  Distance normalisation.

- indel_cost, substitution_cost:

  Costs for optimal matching.

- substitution_matrix:

  Optional named substitution matrix.

- transition_smoothing:

  Smoothing for transition-profile distance.

## Value

A data frame of class `gp3_sequence_panel_changes`.

## Examples

``` r
panel_data <- data.frame(
  participant_id = rep(c("p1", "p2"), each = 8L),
  occasion = rep(rep(c(1, 2), each = 4L), times = 2L),
  sequence_id = rep(c("a", "b", "c", "d"), each = 4L),
  sequence_order = rep(1:4, times = 4L),
  state = c("A", "B", "C", "D", "A", "C", "C", "D",
            "D", "C", "B", "A", "D", "B", "B", "A")
)
compare_sequence_panel_changes(
  prepare_sequence_panel(panel_data, "participant_id", "occasion"),
  method = "lcs"
)
#>   panel_id from_sequence_id to_sequence_id from_occasion to_occasion from_rank
#> 1       p1                a              b             1           2         1
#> 2       p2                c              d             1           2         1
#>   to_rank distance length_change transition_change
#> 1       2        2             0                 0
#> 2       2        2             0                 0
```
