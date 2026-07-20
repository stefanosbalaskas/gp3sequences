# Summarise Adjacent Sequence Transitions

Counts transitions between adjacent ordered states for each sequence and
across the complete data set.

## Usage

``` r
summarise_sequence_transitions(
  data,
  sequence_id_col,
  order_col,
  state_col,
  metadata_cols = NULL,
  expected_states = NULL,
  include_self = TRUE
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

- metadata_cols:

  Optional character vector naming columns that should remain constant
  within each sequence.

- expected_states:

  Optional vector of known or permitted state values.

- include_self:

  Logical value indicating whether transitions from a state to the same
  state should be included.

## Value

A named list containing:

- `by_sequence`: transition counts, proportions within each sequence,
  and conditional proportions within each origin state;

- `overall`: transition counts, sequence coverage, global proportions,
  and conditional origin-state proportions;

- `audit`, `status`, `mapping`, and the resolved `include_self` setting.

## Details

A transition is defined only between adjacent rows after deterministic
ordering by sequence identifier, sequence order, and original row.
Sequences with one state contribute no transitions.

## Examples

``` r
sequences <- data.frame(
  id = c("s1", "s1", "s1", "s2", "s2"),
  position = c(1, 2, 3, 1, 2),
  state = c("A", "B", "C", "A", "C")
)

transitions <- summarise_sequence_transitions(
  sequences,
  sequence_id_col = "id",
  order_col = "position",
  state_col = "state"
)

transitions$by_sequence
#>   sequence_id from_state to_state n_transitions sequence_transition_proportion
#> 1          s1          A        B             1                            0.5
#> 2          s1          B        C             1                            0.5
#> 3          s2          A        C             1                            1.0
#>   origin_transition_proportion
#> 1                            1
#> 2                            1
#> 3                            1
transitions$overall
#>   from_state to_state n_sequences sequence_proportion n_transitions
#> 1          A        B           1                 0.5             1
#> 2          B        C           1                 0.5             1
#> 3          A        C           1                 0.5             1
#>   transition_proportion origin_transition_proportion
#> 1             0.3333333                          0.5
#> 2             0.3333333                          1.0
#> 3             0.3333333                          0.5
```
