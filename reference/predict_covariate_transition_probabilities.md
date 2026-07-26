# Predict covariate-dependent transition probabilities

Predict covariate-dependent transition probabilities

## Usage

``` r
predict_covariate_transition_probabilities(model, newdata)
```

## Arguments

- model:

  A fitted covariate HMM.

- newdata:

  Data frame containing transition covariates.

## Value

A long data frame with one row per input row, origin state, and
destination state.

## Examples

``` r
# See `fit_covariate_sequence_hmm()`.
```
