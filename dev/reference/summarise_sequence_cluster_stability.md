# Summarise sequence-cluster stability

Summarise sequence-cluster stability

## Usage

``` r
summarise_sequence_cluster_stability(bootstrap, threshold = 0.8)
```

## Arguments

- bootstrap:

  A result from
  [`bootstrap_sequence_clusters()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/bootstrap_sequence_clusters.md).

- threshold:

  Pairwise stability threshold.

## Value

Overall, cluster-level, and low-stability pair summaries.

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
boot <- bootstrap_sequence_clusters(distance, k = 2L, n_boot = 5L)
summarise_sequence_cluster_stability(boot)
#> $overall
#>   n_boot sample_fraction mean_pairwise_stability min_pairwise_stability
#> 1      5             0.8                       1                      1
#> 
#> $clusters
#>   cluster n_sequences mean_within_stability min_within_stability
#> 1       1           2                     1                    1
#> 2       2           2                     1                    1
#>   n_evaluated_pairs
#> 1                 1
#> 2                 1
#> 
#> $low_stability_pairs
#> [1] sequence_id_1 sequence_id_2 stability    
#> <0 rows> (or 0-length row.names)
#> 
#> $threshold
#> [1] 0.8
#> 
```
