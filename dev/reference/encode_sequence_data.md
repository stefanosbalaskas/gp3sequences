# Encode Ordered Sequence States

Creates a deterministic dictionary and adds integer and labelled state
codes to long-format sequence data.

## Usage

``` r
encode_sequence_data(
  data,
  sequence_id_col,
  order_col,
  state_col,
  duration_col = NULL,
  metadata_cols = NULL,
  expected_states = NULL,
  state_levels = NULL,
  prefix = "S",
  width = NULL
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

- state_levels:

  Optional atomic vector defining the complete state ordering. When
  omitted, factor levels are respected; otherwise observed state labels
  are sorted alphabetically.

- prefix:

  Character prefix used for labelled codes.

- width:

  Optional positive integer width for the numeric part of each labelled
  code. The default is determined from the dictionary size.

## Value

A named list containing:

- `data`: deterministically sorted canonical data with `state_index` and
  `state_code`;

- `dictionary`: state labels, integer indices, labelled codes, and an
  observed-state indicator;

- `audit`, `status`, and `mapping` from input validation;

- `settings`: the resolved code prefix and width.

## Details

The function does not reinterpret states. State codes are transparent
identifiers derived from an explicit or deterministic state ordering.

## Examples

``` r
sequences <- data.frame(
  id = c("s1", "s1", "s2", "s2"),
  position = c(1, 2, 1, 2),
  state = c("home", "search", "home", "product")
)

encoded <- encode_sequence_data(
  sequences,
  sequence_id_col = "id",
  order_col = "position",
  state_col = "state"
)

encoded$dictionary
#>     state state_index state_code observed
#> 1    home           1         S1     TRUE
#> 2 product           2         S2     TRUE
#> 3  search           3         S3     TRUE
encoded$data
#>   sequence_id sequence_order   state state_index state_code original_row
#> 1          s1              1    home           1         S1            1
#> 2          s1              2  search           3         S3            2
#> 3          s2              1    home           1         S1            3
#> 4          s2              2 product           2         S2            4
```
