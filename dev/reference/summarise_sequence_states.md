# Summarise Sequence States

Produces per-sequence and overall state-frequency summaries from
validated ordered sequence data.

## Usage

``` r
summarise_sequence_states(
  data,
  sequence_id_col,
  order_col,
  state_col,
  duration_col = NULL,
  metadata_cols = NULL,
  expected_states = NULL
)
```

## Arguments

- data:

  A data frame containing ordered state observations.

- sequence_id_col:

  Name of the sequence identifier column.

- order_col:

  Name of the numeric sequence-order column.

- state_col:

  Name of the categorical state column.

- duration_col:

  Optional name of a numeric duration column.

- metadata_cols:

  Optional character vector naming columns that should remain constant
  within each sequence.

- expected_states:

  Optional vector of known or permitted state values.

## Value

A named list containing:

- `by_sequence`: state counts and proportions within each sequence;

- `overall`: state counts and proportions across all sequences;

- `audit`, `status`, and `mapping` from input validation.

When `duration_col` is supplied, both tables also include duration sums,
duration proportions, and mean durations.

## Details

Observation proportions use state rows as the denominator. Sequence
proportions report the proportion of sequences in which each state
occurs. Missing durations are excluded from duration calculations; an
all-missing duration group returns `NA`.

## Examples

``` r
sequences <- data.frame(
  id = c("s1", "s1", "s1", "s2", "s2"),
  position = c(1, 2, 3, 1, 2),
  state = c("A", "B", "A", "B", "C")
)

summaries <- summarise_sequence_states(
  sequences,
  sequence_id_col = "id",
  order_col = "position",
  state_col = "state"
)

summaries$by_sequence
#>   sequence_id state n_observations observation_proportion
#> 1          s1     A              2              0.6666667
#> 2          s1     B              1              0.3333333
#> 3          s2     B              1              0.5000000
#> 4          s2     C              1              0.5000000
summaries$overall
#>   state n_sequences sequence_proportion n_observations observation_proportion
#> 1     A           1                 0.5              2                    0.4
#> 2     B           2                 1.0              2                    0.4
#> 3     C           1                 0.5              1                    0.2
```
