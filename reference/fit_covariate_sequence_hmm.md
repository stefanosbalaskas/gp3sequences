# Fit a covariate-dependent categorical hidden Markov model

Fits a categorical HMM whose initial-state and transition probabilities
may depend on explicitly declared numeric covariates. Multinomial-logit
coefficients are estimated inside the EM algorithm with a small ridge
penalty. Emission probabilities remain time-homogeneous.

## Usage

``` r
fit_covariate_sequence_hmm(
  data,
  n_states,
  initial_covariate_cols = NULL,
  transition_covariate_cols = NULL,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  symbol_levels = NULL,
  state_names = NULL,
  emission_probs = NULL,
  max_iter = 100L,
  inner_maxit = 100L,
  tolerance = 1e-06,
  pseudocount = 1e-06,
  ridge = 1e-06,
  seed = 1L,
  keep_posteriors = FALSE
)
```

## Arguments

- data:

  Long-format sequence data.

- n_states:

  Number of latent states.

- initial_covariate_cols:

  Numeric sequence-constant covariates for initial-state probabilities.

- transition_covariate_cols:

  Numeric row-level covariates for transition probabilities.

- sequence_id_col, order_col, state_col:

  Core sequence columns.

- symbol_levels:

  Optional observed-symbol order.

- state_names:

  Optional latent-state names.

- emission_probs:

  Optional starting emission matrix.

- max_iter:

  Maximum EM iterations.

- inner_maxit:

  Maximum BFGS iterations in each multinomial M-step.

- tolerance:

  Relative log-likelihood tolerance.

- pseudocount:

  Emission smoothing count.

- ridge:

  Non-negative coefficient penalty.

- seed:

  Reproducibility seed.

- keep_posteriors:

  Retain final posteriors.

## Value

An object of class `gp3_covariate_sequence_hmm`.

## Examples

``` r
sequences <- data.frame(
  sequence_id = rep(paste0("s", 1:8), each = 5L),
  sequence_order = rep(1:5, times = 8L),
  state = rep(c("A", "B", "C", "B", "A"), times = 8L),
  condition = rep(rep(c(0, 1), each = 4L), each = 5L),
  time_scaled = rep(seq(-1, 1, length.out = 5L), times = 8L)
)
fit_covariate_sequence_hmm(
  sequences, 2L,
  initial_covariate_cols = "condition",
  transition_covariate_cols = c("condition", "time_scaled"),
  max_iter = 3L, inner_maxit = 10L, seed = 1L
)
#> $initial_coefficients
#>                latent_1 latent_2
#> (Intercept) -1.35444166        0
#> condition   -0.01467263        0
#> 
#> $transition_coefficients
#> $transition_coefficients$latent_1
#>                latent_1 latent_2
#> (Intercept) -0.80208973        0
#> condition   -0.01880007        0
#> time_scaled -0.23549612        0
#> 
#> $transition_coefficients$latent_2
#>                latent_1 latent_2
#> (Intercept)  1.13439989        0
#> condition    0.01761365        0
#> time_scaled -0.64916166        0
#> 
#> 
#> $emission_probs
#>                  A         B          C
#> latent_1 0.2128147 0.7053843 0.08180104
#> latent_2 0.5621794 0.1354117 0.30240891
#> 
#> $state_names
#> [1] "latent_1" "latent_2"
#> 
#> $symbol_names
#> [1] "A" "B" "C"
#> 
#> $sequence_ids
#> [1] "s1" "s2" "s3" "s4" "s5" "s6" "s7" "s8"
#> 
#> $sequence_log_likelihoods
#>        s1        s2        s3        s4        s5        s6        s7        s8 
#> -4.156997 -4.156997 -4.156997 -4.156997 -4.129741 -4.129741 -4.129741 -4.129741 
#> 
#> $log_likelihood
#> [1] -33.14695
#> 
#> $iterations
#> [1] 3
#> 
#> $converged
#> [1] FALSE
#> 
#> $optimizer_convergence
#> [1] 0 0 0
#> 
#> $tolerance
#> [1] 1e-06
#> 
#> $pseudocount
#> [1] 1e-06
#> 
#> $ridge
#> [1] 1e-06
#> 
#> $log_likelihood_history
#> [1] -43.44331 -41.55026 -33.14695
#> 
#> $n_parameters
#> [1] 12
#> 
#> $n_observations
#> [1] 40
#> 
#> $aic
#> [1] 90.29391
#> 
#> $bic
#> [1] 110.5605
#> 
#> $seed
#> [1] 1
#> 
#> $initial_covariate_cols
#> [1] "condition"
#> 
#> $transition_covariate_cols
#> [1] "condition"   "time_scaled"
#> 
#> $initial_center
#> condition 
#>       0.5 
#> 
#> $initial_scale
#> condition 
#> 0.5345225 
#> 
#> $transition_center
#>   condition time_scaled 
#>        0.50       -0.25 
#> 
#> $transition_scale
#>   condition time_scaled 
#>   0.5080005   0.5679618 
#> 
#> $training_observations
#> $training_observations$s1
#> [1] 1 2 3 2 1
#> 
#> $training_observations$s2
#> [1] 1 2 3 2 1
#> 
#> $training_observations$s3
#> [1] 1 2 3 2 1
#> 
#> $training_observations$s4
#> [1] 1 2 3 2 1
#> 
#> $training_observations$s5
#> [1] 1 2 3 2 1
#> 
#> $training_observations$s6
#> [1] 1 2 3 2 1
#> 
#> $training_observations$s7
#> [1] 1 2 3 2 1
#> 
#> $training_observations$s8
#> [1] 1 2 3 2 1
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
#> $training_orders$s5
#> [1] 1 2 3 4 5
#> 
#> $training_orders$s6
#> [1] 1 2 3 4 5
#> 
#> $training_orders$s7
#> [1] 1 2 3 4 5
#> 
#> $training_orders$s8
#> [1] 1 2 3 4 5
#> 
#> 
#> $training_initial_design
#>    (Intercept)  condition
#> 1            1 -0.9354143
#> 6            1 -0.9354143
#> 11           1 -0.9354143
#> 16           1 -0.9354143
#> 21           1  0.9354143
#> 26           1  0.9354143
#> 31           1  0.9354143
#> 36           1  0.9354143
#> 
#> $training_transition_design
#> $training_transition_design$s1
#>   (Intercept) condition time_scaled
#> 1           1 -0.984251  -1.3205113
#> 2           1 -0.984251  -0.4401704
#> 3           1 -0.984251   0.4401704
#> 4           1 -0.984251   1.3205113
#> 
#> $training_transition_design$s2
#>   (Intercept) condition time_scaled
#> 6           1 -0.984251  -1.3205113
#> 7           1 -0.984251  -0.4401704
#> 8           1 -0.984251   0.4401704
#> 9           1 -0.984251   1.3205113
#> 
#> $training_transition_design$s3
#>    (Intercept) condition time_scaled
#> 11           1 -0.984251  -1.3205113
#> 12           1 -0.984251  -0.4401704
#> 13           1 -0.984251   0.4401704
#> 14           1 -0.984251   1.3205113
#> 
#> $training_transition_design$s4
#>    (Intercept) condition time_scaled
#> 16           1 -0.984251  -1.3205113
#> 17           1 -0.984251  -0.4401704
#> 18           1 -0.984251   0.4401704
#> 19           1 -0.984251   1.3205113
#> 
#> $training_transition_design$s5
#>    (Intercept) condition time_scaled
#> 21           1  0.984251  -1.3205113
#> 22           1  0.984251  -0.4401704
#> 23           1  0.984251   0.4401704
#> 24           1  0.984251   1.3205113
#> 
#> $training_transition_design$s6
#>    (Intercept) condition time_scaled
#> 26           1  0.984251  -1.3205113
#> 27           1  0.984251  -0.4401704
#> 28           1  0.984251   0.4401704
#> 29           1  0.984251   1.3205113
#> 
#> $training_transition_design$s7
#>    (Intercept) condition time_scaled
#> 31           1  0.984251  -1.3205113
#> 32           1  0.984251  -0.4401704
#> 33           1  0.984251   0.4401704
#> 34           1  0.984251   1.3205113
#> 
#> $training_transition_design$s8
#>    (Intercept) condition time_scaled
#> 36           1  0.984251  -1.3205113
#> 37           1  0.984251  -0.4401704
#> 38           1  0.984251   0.4401704
#> 39           1  0.984251   1.3205113
#> 
#> 
#> $training_data
#>    sequence_id sequence_order state condition time_scaled .gp3_adv_original_row
#> 1           s1              1     A         0        -1.0                     1
#> 2           s1              2     B         0        -0.5                     2
#> 3           s1              3     C         0         0.0                     3
#> 4           s1              4     B         0         0.5                     4
#> 5           s1              5     A         0         1.0                     5
#> 6           s2              1     A         0        -1.0                     6
#> 7           s2              2     B         0        -0.5                     7
#> 8           s2              3     C         0         0.0                     8
#> 9           s2              4     B         0         0.5                     9
#> 10          s2              5     A         0         1.0                    10
#> 11          s3              1     A         0        -1.0                    11
#> 12          s3              2     B         0        -0.5                    12
#> 13          s3              3     C         0         0.0                    13
#> 14          s3              4     B         0         0.5                    14
#> 15          s3              5     A         0         1.0                    15
#> 16          s4              1     A         0        -1.0                    16
#> 17          s4              2     B         0        -0.5                    17
#> 18          s4              3     C         0         0.0                    18
#> 19          s4              4     B         0         0.5                    19
#> 20          s4              5     A         0         1.0                    20
#> 21          s5              1     A         1        -1.0                    21
#> 22          s5              2     B         1        -0.5                    22
#> 23          s5              3     C         1         0.0                    23
#> 24          s5              4     B         1         0.5                    24
#> 25          s5              5     A         1         1.0                    25
#> 26          s6              1     A         1        -1.0                    26
#> 27          s6              2     B         1        -0.5                    27
#> 28          s6              3     C         1         0.0                    28
#> 29          s6              4     B         1         0.5                    29
#> 30          s6              5     A         1         1.0                    30
#> 31          s7              1     A         1        -1.0                    31
#> 32          s7              2     B         1        -0.5                    32
#> 33          s7              3     C         1         0.0                    33
#> 34          s7              4     B         1         0.5                    34
#> 35          s7              5     A         1         1.0                    35
#> 36          s8              1     A         1        -1.0                    36
#> 37          s8              2     B         1        -0.5                    37
#> 38          s8              3     C         1         0.0                    38
#> 39          s8              4     B         1         0.5                    39
#> 40          s8              5     A         1         1.0                    40
#> 
#> $columns
#> $columns$sequence_id
#> [1] "sequence_id"
#> 
#> $columns$order
#> [1] "sequence_order"
#> 
#> $columns$state
#> [1] "state"
#> 
#> 
#> $posteriors
#> NULL
#> 
#> $call
#> fit_covariate_sequence_hmm(data = sequences, n_states = 2L, initial_covariate_cols = "condition", 
#>     transition_covariate_cols = c("condition", "time_scaled"), 
#>     max_iter = 3L, inner_maxit = 10L, seed = 1L)
#> 
#> attr(,"class")
#> [1] "gp3_covariate_sequence_hmm" "list"                      
```
