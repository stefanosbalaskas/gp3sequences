# Fit a categorical hidden Markov model

Fits a finite-state, time-homogeneous categorical HMM by Baum-Welch EM.
Latent states are statistical model states only; they are not
psychological, diagnostic, or causal constructs.

## Usage

``` r
fit_sequence_hmm(
  data,
  n_states,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
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

  Long-format sequence data.

- n_states:

  Number of latent states.

- sequence_id_col, order_col, state_col:

  Sequence columns.

- symbol_levels:

  Optional observed-symbol ordering.

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

An object of class `gp3_sequence_hmm` containing fitted parameters, log
likelihood, convergence diagnostics, symbol coding, and optional
posteriors.

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
fit_sequence_hmm(sequences, n_states = 2L, max_iter = 5L, seed = 1L)
#> $initial_probs
#>  latent_1  latent_2 
#> 0.4248737 0.5751263 
#> 
#> $transition_probs
#>           latent_1  latent_2
#> latent_1 0.5869242 0.4130758
#> latent_2 0.2499513 0.7500487
#> 
#> $emission_probs
#>                  A         B         C         D
#> latent_1 0.4533086 0.2305098 0.2053575 0.1108241
#> latent_2 0.2210975 0.1595813 0.3820489 0.2372723
#> 
#> $state_names
#> [1] "latent_1" "latent_2"
#> 
#> $symbol_names
#> [1] "A" "B" "C" "D"
#> 
#> $sequence_ids
#> [1] "s1" "s2" "s3" "s4"
#> 
#> $log_likelihood
#> [1] -21.6242
#> 
#> $sequence_log_likelihoods
#>        s1        s2        s3        s4 
#> -5.621695 -5.115689 -5.695995 -5.190825 
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
#> [1] -28.62288 -21.81175 -21.69121 -21.65505 -21.62420
#> 
#> $n_parameters
#> [1] 9
#> 
#> $n_observations
#> [1] 16
#> 
#> $aic
#> [1] 61.24841
#> 
#> $bic
#> [1] 68.20171
#> 
#> $seed
#> [1] 1
#> 
#> $call
#> fit_sequence_hmm(data = sequences, n_states = 2L, max_iter = 5L, 
#>     seed = 1L)
#> 
#> $posteriors
#> NULL
#> 
#> $training_sequences
#> $training_sequences$s1
#> [1] "A" "B" "C" "D"
#> 
#> $training_sequences$s2
#> [1] "A" "B" "C" "C"
#> 
#> $training_sequences$s3
#> [1] "D" "C" "B" "A"
#> 
#> $training_sequences$s4
#> [1] "D" "C" "A" "A"
#> 
#> 
#> $training_orders
#> $training_orders$s1
#> [1] 1 2 3 4
#> 
#> $training_orders$s2
#> [1] 1 2 3 4
#> 
#> $training_orders$s3
#> [1] 1 2 3 4
#> 
#> $training_orders$s4
#> [1] 1 2 3 4
#> 
#> 
#> attr(,"class")
#> [1] "gp3_sequence_hmm" "list"            
```
