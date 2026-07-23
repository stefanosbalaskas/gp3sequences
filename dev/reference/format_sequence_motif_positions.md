# Format Sequence Motif Position Summaries

Produces a deterministic report-ready table from positional motif
summaries.

## Usage

``` r
format_sequence_motif_positions(
  x,
  digits = 3L,
  position_units = c("proportion", "percent"),
  include_rank = TRUE
)
```

## Arguments

- x:

  An object returned by
  [`summarise_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/summarise_sequence_motif_positions.md).

- digits:

  Whole number from 0 to 15 controlling numeric rounding.

- position_units:

  Display units for relative positions: `"proportion"` or `"percent"`.
  Absolute positions remain one-based sequence indices.

- include_rank:

  Logical value indicating whether to include an earlier-to-later rank
  based on mean position. Ranking is performed within each supplied `by`
  group.

## Value

A named list containing the formatted `table`, validation metadata, and
formatting settings.

## Details

Formatting copies and transforms the summary table only. The input
object is not modified. Rows are ordered deterministically by grouping
values, mean and median position, occurrence and sequence counts, motif
length, and motif key. Equal mean positions receive the same minimum
rank.

## Examples

``` r
sequences <- data.frame(
  id = c(rep("s1", 5L), rep("s2", 4L)),
  position = c(1:5, 1:4),
  state = c("A", "B", "A", "B", "C", "A", "B", "C", "B")
)

extracted <- extract_sequence_ngrams(
  sequences,
  sequence_id_col = "id",
  order_col = "position",
  state_col = "state"
)

positions <- summarise_sequence_motif_positions(
  extracted,
  position = "centre",
  scale = "relative"
)

formatted <- format_sequence_motif_positions(
  positions,
  position_units = "percent",
  digits = 1
)

formatted$table
#>   rank    motif_id motif_key     motif motif_length position_basis
#> 1    1 L3:S1|S2|S1  S1|S2|S1 A > B > A            3         centre
#> 2    2    L2:S1|S2     S1|S2     A > B            2         centre
#> 3    3    L2:S2|S1     S2|S1     B > A            2         centre
#> 4    4 L3:S2|S1|S2  S2|S1|S2 B > A > B            3         centre
#> 5    5 L3:S1|S2|S3  S1|S2|S3 A > B > C            3         centre
#> 6    6 L3:S2|S3|S2  S2|S3|S2 B > C > B            3         centre
#> 7    7    L2:S2|S3     S2|S3     B > C            2         centre
#> 8    8    L2:S3|S2     S3|S2     C > B            2         centre
#>   position_scale position_unit n_occurrences n_sequences min_position
#> 1       relative       percent             1           1         25.0
#> 2       relative       percent             3           2         12.5
#> 3       relative       percent             1           1         37.5
#> 4       relative       percent             1           1         50.0
#> 5       relative       percent             2           2         33.3
#> 6       relative       percent             1           1         66.7
#> 7       relative       percent             2           2         50.0
#> 8       relative       percent             1           1         83.3
#>   max_position mean_position median_position
#> 1         25.0          25.0            25.0
#> 2         62.5          30.6            16.7
#> 3         37.5          37.5            37.5
#> 4         50.0          50.0            50.0
#> 5         75.0          54.2            54.2
#> 6         66.7          66.7            66.7
#> 7         87.5          68.8            68.8
#> 8         83.3          83.3            83.3
```
