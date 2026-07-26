# Fit a multichannel categorical hidden Markov model

Fits a finite-state, time-homogeneous HMM to two or more categorical
channels under conditional independence of channels given the latent
state. Latent states are statistical model states only.

## Usage

``` r
fit_multichannel_sequence_hmm(
  data,
  n_states,
  channel_cols,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  symbol_levels = NULL,
  state_names = NULL,
  initial_probs = NULL,
  transition_probs = NULL,
  emission_probs = NULL,
  max_iter = 200L,
  tolerance = 1e-06,
  pseudocount = 1e-06,
  seed = 1L,
  keep_posteriors = FALSE
)
```

## Arguments

- data:

  Long-format multichannel sequence data.

- n_states:

  Number of latent states.

- channel_cols:

  Names of categorical observation channels.

- sequence_id_col, order_col:

  Core sequence columns.

- symbol_levels:

  Optional named list of symbol orders by channel.

- state_names:

  Optional latent-state names.

- initial_probs, transition_probs, emission_probs:

  Optional starting values.

- max_iter:

  Maximum EM iterations.

- tolerance:

  Relative log-likelihood tolerance.

- pseudocount:

  Non-negative smoothing count.

- seed:

  Reproducibility seed.

- keep_posteriors:

  Retain final forward-backward results.

## Value

An object of class `gp3_multichannel_sequence_hmm`.

## Examples

``` r
multichannel <- data.frame(
  sequence_id = rep(paste0("s", 1:4), each = 5L),
  sequence_order = rep(1:5, times = 4L),
  action = c("A", "B", "C", "C", "D", "A", "B", "B", "C", "D",
             "D", "C", "B", "A", "A", "D", "C", "C", "B", "A"),
  context = rep(c("x", "x", "y", "y", "z"), times = 4L)
)
fit_multichannel_sequence_hmm(multichannel, 2L,
                              channel_cols = c("action", "context"),
                              max_iter = 5L, seed = 1L)
#> $initial_probs
#>   latent_1   latent_2 
#> 0.01289931 0.98710069 
#> 
#> $transition_probs
#>           latent_1  latent_2
#> latent_1 0.6329796 0.3670204
#> latent_2 0.8182752 0.1817248
#> 
#> $emission_probs
#> $emission_probs$action
#>                   A          B         C            D
#> latent_1 0.07512987 0.43306632 0.4914386 0.0003652114
#> latent_2 0.46785161 0.02193765 0.0615075 0.4487032442
#> 
#> $emission_probs$context
#>                  x         y           z
#> latent_1 0.3132968 0.6836852 0.003017959
#> latent_2 0.5080140 0.0465875 0.445398526
#> 
#> 
#> $state_names
#> [1] "latent_1" "latent_2"
#> 
#> $channel_names
#> [1] "action"  "context"
#> 
#> $symbol_names
#> $symbol_names$action
#> [1] "A" "B" "C" "D"
#> 
#> $symbol_names$context
#> [1] "x" "y" "z"
#> 
#> 
#> $sequence_ids
#> [1] "s1" "s2" "s3" "s4"
#> 
#> $sequence_log_likelihoods
#>         s1         s2         s3         s4 
#>  -9.323289  -9.453464 -11.058358  -9.290705 
#> 
#> $log_likelihood
#> [1] -39.12582
#> 
#> $iterations
#> [1] 5
#> 
#> $converged
#> [1] FALSE
#> 
#> $tolerance
#> [1] 1e-06
#> 
#> $pseudocount
#> [1] 1e-06
#> 
#> $log_likelihood_history
#> [1] -57.06672 -47.96278 -47.19259 -45.05632 -39.12582
#> 
#> $n_parameters
#> [1] 13
#> 
#> $n_observations
#> [1] 20
#> 
#> $aic
#> [1] 104.2516
#> 
#> $bic
#> [1] 117.1962
#> 
#> $seed
#> [1] 1
#> 
#> $training_observations
#> $training_observations$s1
#>      action context
#> [1,]      1       1
#> [2,]      2       1
#> [3,]      3       2
#> [4,]      3       2
#> [5,]      4       3
#> 
#> $training_observations$s2
#>      action context
#> [1,]      1       1
#> [2,]      2       1
#> [3,]      2       2
#> [4,]      3       2
#> [5,]      4       3
#> 
#> $training_observations$s3
#>      action context
#> [1,]      4       1
#> [2,]      3       1
#> [3,]      2       2
#> [4,]      1       2
#> [5,]      1       3
#> 
#> $training_observations$s4
#>      action context
#> [1,]      4       1
#> [2,]      3       1
#> [3,]      3       2
#> [4,]      2       2
#> [5,]      1       3
#> 
#> 
#> $training_orders
#> $training_orders$s1
#> [1] 1 2 3 4 5
#> 
#> $training_orders$s2
#> [1] 1 2 3 4 5
#> 
#> $training_orders$s3
#> [1] 1 2 3 4 5
#> 
#> $training_orders$s4
#> [1] 1 2 3 4 5
#> 
#> 
#> $posteriors
#> NULL
#> 
#> $columns
#> $columns$sequence_id
#> [1] "sequence_id"
#> 
#> $columns$order
#> [1] "sequence_order"
#> 
#> 
#> $call
#> fit_multichannel_sequence_hmm(data = multichannel, n_states = 2L, 
#>     channel_cols = c("action", "context"), max_iter = 5L, seed = 1L)
#> 
#> attr(,"class")
#> [1] "gp3_multichannel_sequence_hmm" "list"                         
```
