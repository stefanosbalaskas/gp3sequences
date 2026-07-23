# Decode hidden states from a fitted HMM

Decode hidden states from a fitted HMM

## Usage

``` r
decode_sequence_states(
  model,
  data = NULL,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  method = c("viterbi", "posterior"),
  component = NULL
)
```

## Arguments

- model:

  A fitted single HMM or HMM mixture.

- data:

  Optional new long-format data. Training sequences are used when
  omitted.

- sequence_id_col, order_col, state_col:

  Sequence columns for new data.

- method:

  `"viterbi"` or `"posterior"`.

- component:

  Mixture component to decode. When omitted for a mixture, each sequence
  uses its highest-responsibility component.

## Value

A long data frame containing decoded latent states and posterior
probabilities where available.

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
model <- fit_sequence_hmm(sequences, 2L, max_iter = 5L)
decode_sequence_states(model)
#>    sequence_id sequence_order observed_state component latent_state
#> 1           s1              1              A         1     latent_2
#> 2           s1              2              B         1     latent_2
#> 3           s1              3              C         1     latent_2
#> 4           s1              4              D         1     latent_2
#> 5           s2              1              A         1     latent_2
#> 6           s2              2              B         1     latent_2
#> 7           s2              3              C         1     latent_2
#> 8           s2              4              C         1     latent_2
#> 9           s3              1              D         1     latent_2
#> 10          s3              2              C         1     latent_2
#> 11          s3              3              B         1     latent_2
#> 12          s3              4              A         1     latent_2
#> 13          s4              1              D         1     latent_2
#> 14          s4              2              C         1     latent_2
#> 15          s4              3              A         1     latent_1
#> 16          s4              4              A         1     latent_1
#>    posterior_probability decoding_method
#> 1              0.3886041         viterbi
#> 2              0.5192414         viterbi
#> 3              0.7541149         viterbi
#> 4              0.8003439         viterbi
#> 5              0.3878089         viterbi
#> 6              0.5168003         viterbi
#> 7              0.7469419         viterbi
#> 8              0.7769495         viterbi
#> 9              0.7677778         viterbi
#> 10             0.7480491         viterbi
#> 11             0.5322671         viterbi
#> 12             0.4357436         viterbi
#> 13             0.7612516         viterbi
#> 14             0.7253806         viterbi
#> 15             0.5550215         viterbi
#> 16             0.5938073         viterbi
```
