# Create a transition network from ordered sequences

Create a transition network from ordered sequences

## Usage

``` r
create_transition_network(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  group_cols = NULL,
  order = 1L,
  include_self = TRUE,
  normalise = c("count", "from", "global"),
  smoothing = 0,
  context_separator = " > "
)
```

## Arguments

- data:

  Long-format sequence data or a prepared result.

- sequence_id_col, order_col, state_col:

  Sequence columns.

- group_cols:

  Optional grouping columns constant within sequence.

- order:

  Markov order. `1` creates ordinary state-to-state edges; larger values
  create context-to-next-state edges.

- include_self:

  Include first-order self-transitions.

- normalise:

  Edge weight scale: counts, conditional probabilities from each
  context, or global shares.

- smoothing:

  Non-negative additive smoothing applied to observed edges.

- context_separator:

  Separator used for higher-order contexts.

## Value

A data frame of class `gp3_transition_network` containing context, next
state, counts, weights, sequence prevalence, and group columns.

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
create_transition_network(sequences, normalise = "from")
#>   group_key context from_state to_state count sequence_count
#> 1   __all__       A          A        A     1              1
#> 2   __all__       A          A        B     2              2
#> 3   __all__       B          B        A     1              1
#> 4   __all__       B          B        C     2              2
#> 5   __all__       C          C        A     1              1
#> 6   __all__       C          C        B     1              1
#> 7   __all__       C          C        C     1              1
#> 8   __all__       C          C        D     1              1
#> 9   __all__       D          D        C     2              2
#>   sequence_prevalence    weight
#> 1                0.25 0.3333333
#> 2                0.50 0.6666667
#> 3                0.25 0.3333333
#> 4                0.50 0.6666667
#> 5                0.25 0.2500000
#> 6                0.25 0.2500000
#> 7                0.25 0.2500000
#> 8                0.25 0.2500000
#> 9                0.50 1.0000000
```
