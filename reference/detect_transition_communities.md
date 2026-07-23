# Detect descriptive transition communities

Detect descriptive transition communities

## Usage

``` r
detect_transition_communities(
  network,
  method = c("label_propagation", "components"),
  max_iter = 100L,
  seed = 1L
)
```

## Arguments

- network:

  A first-order transition network.

- method:

  `"label_propagation"` or `"components"`.

- max_iter:

  Maximum label-propagation iterations.

- seed:

  Reproducibility seed used only to rotate update order.

## Value

A data frame with states and deterministic community labels.

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
detect_transition_communities(network)
#>   state community
#> 1     A         1
#> 2     B         1
#> 3     C         1
#> 4     D         1
```
