# Plot predicted time-varying sequence probabilities

Plot predicted time-varying sequence probabilities

## Usage

``` r
plot_time_varying_sequence_model(
  model,
  time = NULL,
  level = 0.95,
  show_interval = TRUE,
  ...
)
```

## Arguments

- model:

  A fitted time-varying sequence model.

- time:

  Optional prediction grid.

- level:

  Pointwise confidence level.

- show_interval:

  Draw pointwise confidence ribbons.

- ...:

  Additional arguments passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

Prediction data, invisibly.

## Examples

``` r
# See `fit_time_varying_sequence_model()`.
```
