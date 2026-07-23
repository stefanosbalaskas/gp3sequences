# Compare fitted sequence HMMs descriptively

Compare fitted sequence HMMs descriptively

## Usage

``` r
compare_sequence_hmms(...)
```

## Arguments

- ...:

  Fitted HMM or mixture-HMM objects.

## Value

A data frame containing log likelihood, AIC, BIC, parameter count,
convergence status, and delta criteria. Criteria are descriptive and do
not automatically select a substantive model.

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
model_1 <- fit_sequence_hmm(sequences, 1L, max_iter = 5L)
model_2 <- fit_sequence_hmm(sequences, 2L, max_iter = 5L)
compare_sequence_hmms(one = model_1, two = model_2)
#>   model            class log_likelihood      aic      bic n_parameters
#> 1   one gp3_sequence_hmm      -21.67537 49.35073 51.66850            3
#> 2   two gp3_sequence_hmm      -21.62420 61.24841 68.20171            9
#>   n_observations converged delta_aic delta_bic
#> 1             16      TRUE   0.00000   0.00000
#> 2             16     FALSE  11.89767  16.53321
```
