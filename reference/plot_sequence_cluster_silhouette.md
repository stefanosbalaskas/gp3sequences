# Plot sequence-cluster silhouette values

Plot sequence-cluster silhouette values

## Usage

``` r
plot_sequence_cluster_silhouette(clustering, distance = NULL, ...)
```

## Arguments

- clustering:

  A clustering result or named assignment vector.

- distance:

  Optional distance when `clustering` is an assignment vector.

- ...:

  Additional arguments passed to
  [`graphics::barplot()`](https://rdrr.io/r/graphics/barplot.html).

## Value

The ordered per-sequence silhouette table, invisibly.

## Examples

``` r
data <- data.frame(sequence_id = rep(paste0("s", 1:4), each = 4L),
                   sequence_order = rep(1:4, 4L),
                   state = c("A", "B", "C", "D", "A", "B", "C", "C",
                             "D", "C", "B", "A", "D", "C", "A", "A"))
distance <- compute_sequence_distance(data)
plot_sequence_cluster_silhouette(cluster_sequences(distance, 2L))
```
