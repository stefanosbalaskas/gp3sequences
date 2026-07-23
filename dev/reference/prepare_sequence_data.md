# Prepare Long-Format Sequence Data

Applies explicit preprocessing policies and returns a deterministic,
canonical long-format representation.

## Usage

``` r
prepare_sequence_data(
  data,
  sequence_id_col,
  order_col,
  state_col,
  duration_col = NULL,
  metadata_cols = NULL,
  expected_states = NULL,
  missing_state_policy = c("error", "drop"),
  duplicate_position_policy = c("error", "first", "last"),
  repeated_state_policy = c("preserve", "collapse"),
  zero_duration_policy = c("preserve", "drop", "error"),
  unknown_state_policy = c("preserve", "drop", "error"),
  unused_state_levels = c("preserve", "drop")
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

- missing_state_policy:

  Policy for missing states: `"error"` or `"drop"`.

- duplicate_position_policy:

  Policy for duplicated sequence positions: `"error"`, `"first"`, or
  `"last"`.

- repeated_state_policy:

  Policy for consecutive repeated states: `"preserve"` or `"collapse"`.

- zero_duration_policy:

  Policy for zero durations: `"preserve"`, `"drop"`, or `"error"`.

- unknown_state_policy:

  Policy for states absent from `expected_states`: `"preserve"`,
  `"drop"`, or `"error"`.

- unused_state_levels:

  Policy for unused factor levels: `"preserve"` or `"drop"`.

## Value

A named list containing:

- `data`: canonical prepared data, or `NULL` when unresolved errors
  remain;

- `audit`: input- and output-stage diagnostics;

- `decisions`: a machine-readable preprocessing decision log;

- `mapping`: source-to-contract column mappings;

- `status`: `pass`, `review`, or `fail`;

- row counts and final state levels.

The canonical columns are `sequence_id`, `sequence_order`, `state`,
`original_row`, and optional `duration`. Unmapped columns are preserved.

## Details

Rows are sorted deterministically by sequence identifier, sequence
order, and original row number. When consecutive repeats are collapsed,
the first row supplies non-duration values and available durations are
summed.

Unresolved errors produce `status = "fail"` and `data = NULL`;
diagnostics and decision records remain available.

## Examples

``` r
sequences <- data.frame(
  id = c("s2", "s1", "s1", "s2"),
  position = c(2, 2, 1, 1),
  state = c("product", "search", "home", "home")
)

prepared <- prepare_sequence_data(
  sequences,
  sequence_id_col = "id",
  order_col = "position",
  state_col = "state"
)

prepared$status
#> [1] "pass"
prepared$data
#>   sequence_id sequence_order   state original_row
#> 1          s1              1    home            3
#> 2          s1              2  search            2
#> 3          s2              1    home            4
#> 4          s2              2 product            1
```
