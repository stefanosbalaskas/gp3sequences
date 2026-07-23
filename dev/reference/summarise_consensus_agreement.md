# Summarise consensus agreement

Summarise consensus agreement

## Usage

``` r
summarise_consensus_agreement(
  consensus,
  by = c("overall", "group", "position"),
  threshold = 0.5
)
```

## Arguments

- consensus:

  A result from
  [`create_consensus_sequence()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/create_consensus_sequence.md).

- by:

  Summary level: `"overall"`, `"group"`, or `"position"`.

- threshold:

  Agreement threshold used to count low-agreement positions.

## Value

A data frame with position counts, mean, median, minimum and maximum
agreement, weighted agreement, tie counts, and low-agreement counts.

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
summarise_consensus_agreement(consensus)
#>   n_positions mean_agreement median_agreement min_agreement max_agreement
#> 1           4            0.5              0.5           0.5           0.5
#>   weighted_agreement n_ties n_below_threshold threshold
#> 1                0.5      2                 0       0.5
```
