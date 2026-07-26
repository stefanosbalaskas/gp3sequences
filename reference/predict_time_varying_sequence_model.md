# Predict a time-varying sequence model

Predict a time-varying sequence model

## Usage

``` r
predict_time_varying_sequence_model(
  model,
  time = NULL,
  groups = NULL,
  level = 0.95
)
```

## Arguments

- model:

  A fitted time-varying sequence model.

- time:

  Optional numeric prediction grid.

- groups:

  Optional subset of fitted groups.

- level:

  Confidence level for pointwise intervals.

## Value

A data frame with fitted probabilities and pointwise intervals.

## Examples

``` r
# See `fit_time_varying_sequence_model()`.
```
