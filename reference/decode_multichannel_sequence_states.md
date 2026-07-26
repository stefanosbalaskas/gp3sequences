# Decode latent states from a multichannel HMM

Decode latent states from a multichannel HMM

## Usage

``` r
decode_multichannel_sequence_states(
  model,
  data = NULL,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  channel_cols = NULL,
  method = c("viterbi", "posterior")
)
```

## Arguments

- model:

  A fitted multichannel HMM.

- data:

  Optional new long-format multichannel data.

- sequence_id_col, order_col:

  Core sequence columns for new data.

- channel_cols:

  Channel columns for new data; defaults to training names.

- method:

  `"viterbi"` or `"posterior"`.

## Value

A long data frame of decoded states and posterior probabilities.

## Examples

``` r
# See `fit_multichannel_sequence_hmm()`.
```
