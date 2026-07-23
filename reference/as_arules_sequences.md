# Convert sequence data to cSPADE transaction input

Convert sequence data to cSPADE transaction input

## Usage

``` r
as_arules_sequences(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state"
)
```

## Arguments

- data:

  Long-format sequence data.

- sequence_id_col, order_col, state_col:

  Sequence columns.

## Value

An `arules` transactions object whose transaction information contains
positive integer `sequenceID` and `eventID` fields required by
[`arulesSequences::cspade()`](https://rdrr.io/pkg/arulesSequences/man/cspade.html).

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
if (requireNamespace("arules", quietly = TRUE) &&
    requireNamespace("arulesSequences", quietly = TRUE)) {
  as_arules_sequences(sequences)
}
#> transactions in sparse format with
#>  16 transactions (rows) and
#>  4 items (columns)
```
