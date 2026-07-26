# Plot longitudinal sequence changes

Plot longitudinal sequence changes

## Usage

``` r
plot_sequence_panel_changes(
  changes,
  metric = c("distance", "length_change", "transition_change"),
  type = c("individual", "summary"),
  ...
)
```

## Arguments

- changes:

  A result from
  [`compare_sequence_panel_changes()`](https://stefanosbalaskas.github.io/gp3sequences/reference/compare_sequence_panel_changes.md).

- metric:

  One of `"distance"`, `"length_change"`, or `"transition_change"`.

- type:

  Plot individual panel trajectories or occasion-transition means.

- ...:

  Additional graphical arguments passed to base plotting functions.

## Value

The plotted data, invisibly.

## Examples

``` r
panel_data <- data.frame(
  participant_id = rep(c("p1", "p2"), each = 6L),
  occasion = rep(rep(c(1, 2), each = 3L), times = 2L),
  sequence_id = rep(c("a", "b", "c", "d"), each = 3L),
  sequence_order = rep(1:3, times = 4L),
  state = c("A", "B", "C", "A", "C", "C", "C", "B", "A", "C", "B", "B")
)
changes <- compare_sequence_panel_changes(
  prepare_sequence_panel(panel_data, "participant_id", "occasion")
)
plot_sequence_panel_changes(changes)
```
