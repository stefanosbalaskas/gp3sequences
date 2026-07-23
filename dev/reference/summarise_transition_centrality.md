# Summarise transition-network centrality

Summarise transition-network centrality

## Usage

``` r
summarise_transition_centrality(
  network,
  directed = TRUE,
  pagerank_damping = 0.85,
  pagerank_tolerance = 1e-10,
  pagerank_max_iter = 1000L
)
```

## Arguments

- network:

  A first-order transition network.

- directed:

  Treat the network as directed.

- pagerank_damping:

  Damping factor for PageRank.

- pagerank_tolerance:

  Convergence tolerance.

- pagerank_max_iter:

  Maximum PageRank iterations.

## Value

A data frame containing degree, strength, weighted closeness, unweighted
betweenness, and PageRank centrality.

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
network <- create_transition_network(sequences)
summarise_transition_centrality(network)
#>   state out_degree in_degree total_degree out_strength in_strength
#> 1     A          2         3            5            3           3
#> 2     B          2         2            4            3           3
#> 3     C          4         3            7            4           5
#> 4     D          1         1            2            2           1
#>   total_strength closeness betweenness  pagerank
#> 1              6 0.8571429           0 0.2630425
#> 2              6 1.0000000           2 0.2630425
#> 3              9 1.0000000           4 0.3599299
#> 4              3 0.8571429           0 0.1139851
```
