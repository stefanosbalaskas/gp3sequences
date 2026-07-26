# Plot state distributions over aligned positions

Plot state distributions over aligned positions

## Usage

``` r
plot_sequence_state_distribution(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  proportion = TRUE,
  state_levels = NULL,
  palette = "Dark 3",
  ...
)
```

## Arguments

- data:

  Long-format sequence data or a prepared result.

- sequence_id_col, order_col, state_col:

  Core sequence columns.

- proportion:

  Plot position-wise proportions rather than counts.

- state_levels:

  Optional state ordering.

- palette:

  Base HCL palette.

- ...:

  Additional arguments passed to
  [`graphics::matplot()`](https://rdrr.io/r/graphics/matplot.html).

## Value

A position-by-state matrix, invisibly.

## Examples

``` r
data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
                   sequence_order = rep(1:4, 2L),
                   state = c("A", "B", "C", "D", "A", "C", "C", "D"))
plot_sequence_state_distribution(data)
```
