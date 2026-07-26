# Decode states from a covariate-dependent HMM

Decode states from a covariate-dependent HMM

## Usage

``` r
decode_covariate_sequence_states(
  model,
  data = NULL,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  method = c("viterbi", "posterior")
)
```

## Arguments

- model:

  A fitted covariate HMM.

- data:

  Optional new data. Training data are used when omitted.

- sequence_id_col, order_col, state_col:

  Core columns for new data.

- method:

  `"viterbi"` or `"posterior"`.

## Value

A long decoded-state data frame.

## Examples

``` r
# See `fit_covariate_sequence_hmm()`.
```
