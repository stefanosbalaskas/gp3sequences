# Summarise a fitted sequence HMM

Summarise a fitted sequence HMM

## Usage

``` r
summarise_sequence_hmm(model)
```

## Arguments

- model:

  A single or mixture HMM.

## Value

A list of convergence, fit, initial, transition, emission, and mixture
summaries.

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
summarise_sequence_hmm(model)
#> $fit
#>   log_likelihood      aic      bic n_parameters n_observations iterations
#> 1       -21.6242 61.24841 68.20171            9             16          5
#>   converged
#> 1     FALSE
#> 
#> $initial
#>   latent_state probability
#> 1     latent_1   0.4248737
#> 2     latent_2   0.5751263
#> 
#> $transition
#>   from_state to_state probability
#> 1   latent_1 latent_1   0.5869242
#> 2   latent_2 latent_1   0.2499513
#> 3   latent_1 latent_2   0.4130758
#> 4   latent_2 latent_2   0.7500487
#> 
#> $emission
#>   latent_state observed_state probability
#> 1     latent_1              A   0.4533086
#> 2     latent_2              A   0.2210975
#> 3     latent_1              B   0.2305098
#> 4     latent_2              B   0.1595813
#> 5     latent_1              C   0.2053575
#> 6     latent_2              C   0.3820489
#> 7     latent_1              D   0.1108241
#> 8     latent_2              D   0.2372723
#> 
#> $mixture
#> NULL
#> 
```
