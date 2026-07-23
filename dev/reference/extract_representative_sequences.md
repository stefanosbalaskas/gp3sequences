# Extract representative sequences from clusters

Extract representative sequences from clusters

## Usage

``` r
extract_representative_sequences(
  clustering,
  distance = NULL,
  n_per_cluster = 1L
)
```

## Arguments

- clustering:

  A clustering result.

- distance:

  Optional distance when absent from `clustering`.

- n_per_cluster:

  Number of representatives per cluster.

## Value

A data frame with cluster, rank, representative ID, and mean
within-cluster distance.

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
extract_representative_sequences(fit)
#>   cluster rank sequence_id mean_within_distance
#> 1       1    1          s1                    1
#> 2       2    1          s3                    1
```
