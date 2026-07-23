# Audit Long-Format Sequence Data

Examines a long-format data frame against the neutral `gp3sequences`
sequence-data contract without modifying the input.

## Usage

``` r
audit_sequence_data(
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

A data frame with one row per detected issue and the stable columns
`sequence_id`, `row`, `column`, `issue_code`, `severity`, `value`,
`message`, and `action`. Severity values are `error`, `review`, and
`info`.

## Details

The audit checks column mappings, empty inputs, missing identifiers,
missing or non-numeric order values, duplicated positions, integer order
gaps, unordered rows, missing states, consecutive repeated states,
single-row sequences, invalid durations, inconsistent metadata,
unexpected states, and unused factor levels.

The function reports structural properties only. It does not infer
psychological, cognitive, emotional, or diagnostic states.

## Examples

``` r
sequences <- data.frame(
  id = rep(c("s1", "s2"), each = 3L),
  position = rep(1:3, times = 2L),
  state = c("home", "search", "product", "home", "category", "product")
)

audit_sequence_data(
  sequences,
  sequence_id_col = "id",
  order_col = "position",
  state_col = "state"
)
#> [1] sequence_id row         column      issue_code  severity    value      
#> [7] message     action     
#> <0 rows> (or 0-length row.names)
```
