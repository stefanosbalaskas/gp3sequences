# Convert sequence data to a TraMineR state-sequence object

Convert sequence data to a TraMineR state-sequence object

## Usage

``` r
as_traminer_sequences(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  missing = NA,
  right = "DEL",
  ...
)
```

## Arguments

- data:

  Long-format sequence data.

- sequence_id_col, order_col, state_col:

  Sequence columns.

- missing:

  Missing-state code passed to
  [`TraMineR::seqdef()`](https://rdrr.io/pkg/TraMineR/man/seqdef.html).

- right:

  Right-missing policy passed to
  [`TraMineR::seqdef()`](https://rdrr.io/pkg/TraMineR/man/seqdef.html).

- ...:

  Additional arguments passed to
  [`TraMineR::seqdef()`](https://rdrr.io/pkg/TraMineR/man/seqdef.html).

## Value

A TraMineR `stslist` object with original sequence identifiers as row
names.

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
if (requireNamespace("TraMineR", quietly = TRUE)) {
  as_traminer_sequences(sequences)
}
#>  [>] state coding:
#>        [alphabet]  [label]  [long label] 
#>      1  A           A        A
#>      2  B           B        B
#>      3  C           C        C
#>      4  D           D        D
#>  [>] 4 sequences in the data set
#>  [>] min/max sequence length: 4/4
#>    Sequence
#> s1 A-B-C-D 
#> s2 A-B-C-C 
#> s3 D-C-B-A 
#> s4 D-C-A-A 
```
