# Format Ordered Sequence Paths

Creates a compact one-row-per-sequence representation of ordered state
paths.

## Usage

``` r
format_sequence_paths(
  data,
  sequence_id_col,
  order_col,
  state_col,
  metadata_cols = NULL,
  expected_states = NULL,
  separator = " > ",
  collapse_repeats = FALSE
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

- separator:

  Character value inserted between adjacent state labels.

- collapse_repeats:

  Logical value indicating whether consecutive repeated states should be
  collapsed for path display.

## Value

A named list containing:

- `paths`: one row per sequence with observation counts, formatted-state
  counts, unique-state counts, start and end states, and the path
  string;

- `audit`, `status`, and `mapping` from input validation;

- `settings`: the path separator and repeat-collapsing choice.

## Details

Repeat collapsing affects only the formatted representation. It does not
modify the supplied data or alter non-consecutive repeated states. Input
rows are ordered deterministically for formatting, but review-level
diagnostics such as `unordered_rows` remain reflected in the returned
`status` and `audit`.

## Examples

``` r
sequences <- data.frame(
  id = c("s1", "s1", "s1", "s2", "s2"),
  position = c(1, 2, 3, 1, 2),
  state = c("A", "B", "C", "A", "C")
)

paths <- format_sequence_paths(
  sequences,
  sequence_id_col = "id",
  order_col = "position",
  state_col = "state"
)

paths$paths
#>   sequence_id n_observations n_states n_unique_states start_state end_state
#> 1          s1              3        3               3           A         C
#> 2          s2              2        2               2           A         C
#>        path
#> 1 A > B > C
#> 2     A > C
```
