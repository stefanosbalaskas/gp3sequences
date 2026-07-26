# Plot position-wise state entropy

Plot position-wise state entropy

## Usage

``` r
plot_sequence_entropy(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  base = 2,
  normalise = TRUE,
  ...
)
```

## Arguments

- data:

  Long-format sequence data or a prepared result.

- sequence_id_col, order_col, state_col:

  Core sequence columns.

- base:

  Logarithm base.

- normalise:

  Divide entropy by the maximum entropy for the observed alphabet.

- ...:

  Additional arguments passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

A data frame of position-wise entropy values, invisibly.

## Examples

``` r
data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
                   sequence_order = rep(1:4, 2L),
                   state = c("A", "B", "C", "D", "A", "C", "C", "D"))
plot_sequence_entropy(data)
```
