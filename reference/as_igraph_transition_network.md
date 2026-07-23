# Convert a transition network to an igraph object

Convert a transition network to an igraph object

## Usage

``` r
as_igraph_transition_network(network, directed = TRUE)
```

## Arguments

- network:

  A first-order transition network.

- directed:

  Whether the resulting graph is directed.

## Value

An `igraph` graph with edge attributes copied from the network.

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
if (requireNamespace("igraph", quietly = TRUE)) {
  as_igraph_transition_network(network)
}
#> IGRAPH 7ce3d61 DNW- 4 9 -- 
#> + attr: name (v/c), weight (e/n), count (e/n), sequence_count (e/n),
#> | sequence_prevalence (e/n)
#> + edges from 7ce3d61 (vertex names):
#> [1] A->A A->B B->A B->C C->A C->B C->C C->D D->C
```
