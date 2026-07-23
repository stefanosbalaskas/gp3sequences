# Sequence Distances, Clustering, and Stability

## Synthetic paths

``` r

paths <- list(
  s1 = c("A", "B", "C", "D"),
  s2 = c("A", "B", "C", "C"),
  s3 = c("A", "C", "C", "D"),
  s4 = c("D", "C", "B", "A"),
  s5 = c("D", "C", "A", "A"),
  s6 = c("D", "B", "B", "A")
)
sequence_data <- do.call(rbind, lapply(seq_along(paths), function(i) {
  data.frame(sequence_id = names(paths)[i],
             sequence_order = seq_along(paths[[i]]),
             state = paths[[i]], stringsAsFactors = FALSE)
}))
```

## Transparent distance families

``` r

levenshtein <- compute_sequence_distance(sequence_data, method = "levenshtein")
lcs <- compute_sequence_distance(sequence_data, method = "lcs")
om <- compute_sequence_distance(
  sequence_data,
  method = "optimal_matching",
  indel_cost = 1,
  substitution_cost = 2,
  normalise = "max_length"
)
transition <- compute_sequence_distance(sequence_data, method = "transition")
summarise_sequence_distance(lcs)$overall
#>   n_sequences n_pairs mean_distance median_distance min_distance max_distance
#> 1           6      15      4.533333               6            2            6
```

The distance method and all costs are retained as object attributes. The
transition method compares first-order transition-probability profiles;
it is not a general stochastic-process model.

## Clustering and validation

``` r

fit <- cluster_sequences(lcs, k = 2L, method = "hierarchical", linkage = "average")
fit$assignments
#> s1 s2 s3 s4 s5 s6 
#>  1  1  1  2  2  2
validate_sequence_clusters(fit)$overall
#>   n_sequences n_clusters average_silhouette minimum_silhouette dunn_index
#> 1           6          2          0.6111111                0.5        1.5
#>   within_between_ratio singleton_clusters
#> 1            0.3888889                  0
extract_representative_sequences(fit)
#>   cluster rank sequence_id mean_within_distance
#> 1       1    1          s1                    2
#> 2       2    1          s4                    2
```

## Subsampling stability

``` r

stability <- bootstrap_sequence_clusters(
  lcs,
  k = 2L,
  n_boot = 20L,
  sample_fraction = 0.8,
  seed = 100L
)
summarise_sequence_cluster_stability(stability)$overall
#>   n_boot sample_fraction mean_pairwise_stability min_pairwise_stability
#> 1     20             0.8                       1                      1
```

Cluster stability describes reproducibility under the selected
resampling and clustering settings. It does not establish that the
clusters are natural, causal, or substantively meaningful.

## Co-association ensemble

``` r

transition_fit <- cluster_sequences(
  transition,
  k = 2L,
  method = "hierarchical",
  linkage = "average"
)
ensemble <- create_sequence_cluster_ensemble(
  fit,
  transition_fit,
  k = 2L
)
ensemble$assignments
#> s1 s2 s3 s4 s5 s6 
#>  1  1  1  2  2  1
ensemble$coassociation
#>     s1  s2  s3  s4  s5  s6
#> s1 1.0 1.0 1.0 0.0 0.0 0.5
#> s2 1.0 1.0 1.0 0.0 0.0 0.5
#> s3 1.0 1.0 1.0 0.0 0.0 0.5
#> s4 0.0 0.0 0.0 1.0 1.0 0.5
#> s5 0.0 0.0 0.0 1.0 1.0 0.5
#> s6 0.5 0.5 0.5 0.5 0.5 1.0
```

The ensemble records how often pairs are assigned together across
supplied solutions. It does not automatically validate the number or
meaning of clusters.

## Optional PAM and CLARA interfaces

``` r

if (requireNamespace("cluster", quietly = TRUE)) {
  pam_fit <- cluster_sequences(lcs, k = 2L, method = "pam", seed = 11L)
  clara_fit <- cluster_sequences(
    lcs,
    k = 2L,
    method = "clara",
    seed = 11L,
    samples = 5L,
    sampsize = 5L
  )
  list(pam = pam_fit$assignments, clara = clara_fit$assignments)
}
#> $pam
#> s1 s2 s3 s4 s5 s6 
#>  1  1  1  2  2  2 
#> 
#> $clara
#> s1 s2 s3 s4 s5 s6 
#>  1  1  1  2  2  2
```

PAM uses the supplied dissimilarities directly. CLARA uses a documented
classical multidimensional-scaling embedding because
[`cluster::clara()`](https://rdrr.io/pkg/cluster/man/clara.html) expects
observations rather than a dissimilarity object.
