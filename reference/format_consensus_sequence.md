# Format consensus sequences as paths

Format consensus sequences as paths

## Usage

``` r
format_consensus_sequence(
  consensus,
  separator = " -> ",
  include_order = FALSE,
  include_agreement = FALSE,
  digits = 3L
)
```

## Arguments

- consensus:

  A consensus result.

- separator:

  State separator.

- include_order:

  Include position labels.

- include_agreement:

  Include rounded agreement values.

- digits:

  Number of decimal places for agreement values.

## Value

One row per consensus group with a formatted path and position count.

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
format_consensus_sequence(consensus)
#>               path n_positions
#> 1 A -> B -> C -> A           4
```
