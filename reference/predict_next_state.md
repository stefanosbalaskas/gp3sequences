# Predict the next state from a transition model

Predict the next state from a transition model

## Usage

``` r
predict_next_state(model, history, top_n = NULL)
```

## Arguments

- model:

  A higher-order transition model.

- history:

  Character vector of observed recent states.

- top_n:

  Optional number of states to retain. Returned probabilities remain on
  the full-model scale and are not renormalised after truncation.

## Value

A probability table ordered from highest to lowest probability, with the
context order actually used.

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
model <- fit_higher_order_transition_model(sequences, order = 2L)
predict_next_state(model, c("A", "B"))
#>   order context next_state count probability used_order used_context
#> 1     2   A > B          C     2       0.625          2        A > B
#> 2     2   A > B          A     0       0.125          2        A > B
#> 3     2   A > B          B     0       0.125          2        A > B
#> 4     2   A > B          D     0       0.125          2        A > B
```
