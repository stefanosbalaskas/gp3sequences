# Fit a mixture of categorical hidden Markov models

Fits sequence-level mixture components, each containing a categorical
HMM. Component membership is a statistical clustering device and should
not be interpreted as a substantive latent type without external
validation.

## Usage

``` r
fit_sequence_hmm_mixture(
  data,
  n_components,
  n_states,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  symbol_levels = NULL,
  max_iter = 200L,
  inner_initial_iter = 20L,
  tolerance = 1e-06,
  pseudocount = 1e-06,
  seed = 1L
)
```

## Arguments

- data:

  Long-format sequence data.

- n_components:

  Number of mixture components.

- n_states:

  Number of hidden states per component; scalar or vector.

- sequence_id_col, order_col, state_col:

  Sequence columns.

- symbol_levels:

  Optional symbol ordering.

- max_iter:

  Maximum mixture-EM iterations.

- inner_initial_iter:

  Initial single-HMM iterations per component.

- tolerance:

  Relative log-likelihood tolerance.

- pseudocount:

  Smoothing count.

- seed:

  Reproducibility seed.

## Value

An object of class `gp3_sequence_hmm_mixture`.

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
fit_sequence_hmm_mixture(sequences, n_components = 2L, n_states = 2L,
                         max_iter = 5L, inner_initial_iter = 2L, seed = 1L)
#> $mixture_weights
#> component_1 component_2 
#>   0.3784486   0.6215514 
#> 
#> $components
#> $components[[1]]
#> $components[[1]]$initial_probs
#> component_1_latent_1 component_1_latent_2 
#>            0.6313579            0.3686421 
#> 
#> $components[[1]]$transition_probs
#>                      component_1_latent_1 component_1_latent_2
#> component_1_latent_1            0.5829952            0.4170048
#> component_1_latent_2            0.7987138            0.2012862
#> 
#> $components[[1]]$emission_probs
#>                              A          B         C         D
#> component_1_latent_1 0.2457640 0.34558524 0.2229322 0.1857186
#> component_1_latent_2 0.2794406 0.04993156 0.5563558 0.1142720
#> 
#> $components[[1]]$state_names
#> [1] "component_1_latent_1" "component_1_latent_2"
#> 
#> $components[[1]]$symbol_names
#> [1] "A" "B" "C" "D"
#> 
#> 
#> $components[[2]]
#> $components[[2]]$initial_probs
#> component_2_latent_1 component_2_latent_2 
#>            0.1819599            0.8180401 
#> 
#> $components[[2]]$transition_probs
#>                      component_2_latent_1 component_2_latent_2
#> component_2_latent_1            0.9720768         0.0279232140
#> component_2_latent_2            0.9994576         0.0005423998
#> 
#> $components[[2]]$emission_probs
#>                               A            B           C           D
#> component_2_latent_1 0.41961788 1.973971e-01 0.379386252 0.003598727
#> component_2_latent_2 0.08466801 6.232563e-05 0.001194968 0.914074698
#> 
#> $components[[2]]$state_names
#> [1] "component_2_latent_1" "component_2_latent_2"
#> 
#> $components[[2]]$symbol_names
#> [1] "A" "B" "C" "D"
#> 
#> 
#> 
#> $responsibilities
#>   sequence_id component_1 component_2 assigned_component
#> 1          s1  0.88372261   0.1162774                  1
#> 2          s2  0.53364199   0.4663580                  1
#> 3          s3  0.09115750   0.9088425                  2
#> 4          s4  0.04383831   0.9561617                  2
#> 
#> $log_likelihood
#> [1] -19.35061
#> 
#> $log_likelihood_history
#> [1] -20.97004 -20.62229 -20.27647 -19.90725 -19.35061
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
#> $inner_initial_iter
#> [1] 2
#> 
#> $n_components
#> [1] 2
#> 
#> $n_states
#> [1] 2 2
#> 
#> $n_parameters
#> [1] 19
#> 
#> $n_observations
#> [1] 16
#> 
#> $aic
#> [1] 76.70122
#> 
#> $bic
#> [1] 91.3804
#> 
#> $symbol_names
#> [1] "A" "B" "C" "D"
#> 
#> $sequence_ids
#> [1] "s1" "s2" "s3" "s4"
#> 
#> $seed
#> [1] 1
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
#> $call
#> fit_sequence_hmm_mixture(data = sequences, n_components = 2L, 
#>     n_states = 2L, max_iter = 5L, inner_initial_iter = 2L, seed = 1L)
#> 
#> attr(,"class")
#> [1] "gp3_sequence_hmm_mixture" "list"                    
```
