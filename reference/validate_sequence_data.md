# Validate Long-Format Sequence Data

Produces a compact validation result based on
[`audit_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/audit_sequence_data.md)
without modifying the input.

## Usage

``` r
validate_sequence_data(
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

A named list containing `valid`, `status`, issue counts, the complete
`audit` table, the column `mapping`, row and sequence counts, and
observed `state_levels`. A result is valid when no error-severity issue
is present. Review-severity issues do not automatically invalidate the
input.

## Examples

``` r
sequences <- data.frame(
  id = rep(c("s1", "s2"), each = 2L),
  position = rep(1:2, times = 2L),
  state = c("home", "search", "home", "product")
)

validation <- validate_sequence_data(
  sequences,
  sequence_id_col = "id",
  order_col = "position",
  state_col = "state"
)

validation$status
#> [1] "pass"
validation$valid
#> [1] TRUE
```
