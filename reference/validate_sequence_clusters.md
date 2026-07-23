# Validate sequence clusters descriptively

Validate sequence clusters descriptively

## Usage

``` r
validate_sequence_clusters(clustering, distance = NULL)
```

## Arguments

- clustering:

  A result from
  [`cluster_sequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/cluster_sequences.md)
  or a named assignment vector.

- distance:

  Optional distance object when `clustering` is an assignment vector.

## Value

A list containing overall validation metrics, cluster sizes, and
per-sequence silhouette values.

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
distance <- compute_sequence_distance(sequences)
fit <- cluster_sequences(distance, k = 2L)
validate_sequence_clusters(fit)
#> $overall
#>   n_sequences n_clusters average_silhouette minimum_silhouette dunn_index
#> 1           4          2               0.75               0.75          4
#>   within_between_ratio singleton_clusters
#> 1                 0.25                  0
#> 
#> $cluster_sizes
#>   cluster size
#> 1       1    2
#> 2       2    2
#> 
#> $per_sequence
#>   sequence_id cluster silhouette
#> 1          s1       1       0.75
#> 2          s2       1       0.75
#> 3          s3       2       0.75
#> 4          s4       2       0.75
#> 
```
