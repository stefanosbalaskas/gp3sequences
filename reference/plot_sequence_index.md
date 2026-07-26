# Plot a sequence index heatmap

Plot a sequence index heatmap

## Usage

``` r
plot_sequence_index(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  sort_by = c("input", "length", "path"),
  state_levels = NULL,
  palette = "Dark 3",
  show_sequence_labels = TRUE,
  ...
)
```

## Arguments

- data:

  Long-format sequence data or a prepared result.

- sequence_id_col, order_col, state_col:

  Core sequence columns.

- sort_by:

  `"input"`, `"length"`, or `"path"`.

- state_levels:

  Optional state ordering.

- palette:

  Base HCL palette.

- show_sequence_labels:

  Draw sequence identifiers.

- ...:

  Additional arguments passed to
  [`graphics::image()`](https://rdrr.io/r/graphics/image.html).

## Value

The plotted state-code matrix, invisibly.

## Examples

``` r
data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
                   sequence_order = rep(1:4, 2L),
                   state = c("A", "B", "C", "D", "A", "C", "C", "D"))
plot_sequence_index(data)
```
