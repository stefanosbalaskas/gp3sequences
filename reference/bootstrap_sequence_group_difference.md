# Bootstrap a sequence group difference

Resamples declared independent units within groups and returns a
percentile interval for the mean difference. This interval does not by
itself license causal interpretation.

## Usage

``` r
bootstrap_sequence_group_difference(
  inference,
  n_boot = 999L,
  level = 0.95,
  seed = 1L
)
```

## Arguments

- inference:

  A result from
  [`test_sequence_group_difference()`](https://stefanosbalaskas.github.io/gp3sequences/reference/test_sequence_group_difference.md).

- n_boot:

  Number of bootstrap samples.

- level:

  Confidence level.

- seed:

  Reproducibility seed.

## Value

The inference object with a `bootstrap` component.

## Examples

``` r
# See `test_sequence_group_difference()`.
```
