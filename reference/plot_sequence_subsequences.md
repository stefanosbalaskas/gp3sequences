# Plot non-contiguous subsequence summaries

Plot non-contiguous subsequence summaries

## Usage

``` r
plot_sequence_subsequences(
  x,
  metric = "sequence_prevalence",
  top_n = 10L,
  decreasing = TRUE,
  ...
)
```

## Arguments

- x:

  A summary or group-comparison table.

- metric:

  Numeric column to plot.

- top_n:

  Maximum number of subsequences.

- decreasing:

  Sort metric in decreasing order.

- ...:

  Additional arguments passed to
  [`graphics::barplot()`](https://rdrr.io/r/graphics/barplot.html).

## Value

The plotted rows, invisibly.

## Examples

``` r
data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
                   sequence_order = rep(1:4, 2L),
                   state = c("A", "B", "C", "D", "A", "C", "B", "D"))
summary <- summarise_sequence_subsequences(extract_sequence_subsequences(data))
plot_sequence_subsequences(summary, top_n = 5L)
```
