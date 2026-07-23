# Plot a consensus sequence

Plot a consensus sequence

## Usage

``` r
plot_consensus_sequence(
  consensus,
  type = c("agreement", "states"),
  group = NULL,
  main = NULL,
  xlab = "Sequence position",
  ylab = NULL,
  ...
)
```

## Arguments

- consensus:

  A consensus result.

- type:

  `"agreement"` or `"states"`.

- group:

  Optional group value, encoded group key, or named list of values when
  grouped consensus was created. It is required when more than one
  consensus group is present.

- main, xlab, ylab:

  Plot labels.

- ...:

  Additional arguments passed to base graphics.

## Value

The plotted data, invisibly.

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
consensus <- create_consensus_sequence(sequences)
plot_consensus_sequence(consensus)

```
