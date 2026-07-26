# Plot multichannel HMM emission profiles

Plot multichannel HMM emission profiles

## Usage

``` r
plot_multichannel_sequence_hmm(model, channel = model$channel_names[1L], ...)
```

## Arguments

- model:

  A fitted multichannel HMM.

- channel:

  Channel name to plot.

- ...:

  Additional arguments passed to
  [`graphics::barplot()`](https://rdrr.io/r/graphics/barplot.html).

## Value

The selected emission matrix, invisibly.

## Examples

``` r
# See `fit_multichannel_sequence_hmm()`.
```
