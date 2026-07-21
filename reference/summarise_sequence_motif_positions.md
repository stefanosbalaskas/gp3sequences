# Summarise Sequence Motif Positions

Summarises where contiguous motif occurrences appear within sequences.

## Usage

``` r
summarise_sequence_motif_positions(
  x,
  position = c("start", "centre", "end"),
  scale = c("absolute", "relative"),
  by = NULL
)
```

## Arguments

- x:

  An object returned by
  [`extract_sequence_ngrams()`](https://stefanosbalaskas.github.io/gp3sequences/reference/extract_sequence_ngrams.md).

- position:

  Position represented by each occurrence: motif `"start"`, `"centre"`,
  or `"end"`.

- scale:

  Position scale: one-based `"absolute"` sequence positions or
  `"relative"` positions from 0 to 1.

- by:

  Optional character vector naming preserved metadata columns used to
  produce separate summaries, such as `"group"` or `"condition"`.

## Value

A named list containing:

- `summary`: one row per motif and optional metadata group;

- `occurrences`: occurrence-level absolute, relative, and selected-scale
  positions;

- `sequences`, validation metadata, and extraction settings;

- `settings`: the resolved position basis, scale, and grouping columns.

The summary reports motif identifiers and labels, motif length,
occurrence and sequence counts, and minimum, maximum, mean, and median
positions.

## Details

Absolute positions use the one-based state index within each validated
sequence. Relative positions are calculated as
`(absolute_position - 1) / (n_states - 1)` and are constrained to the
interval from 0 to 1. A sequence containing one state is assigned
relative position 0.

Grouping is descriptive. The function does not test differences or
attach behavioural, psychological, cognitive, or causal interpretations
to motif location.

## Examples

``` r
sequences <- data.frame(
  id = c(rep("s1", 5L), rep("s2", 4L)),
  position = c(1:5, 1:4),
  state = c("A", "B", "A", "B", "C", "A", "B", "C", "B"),
  group = c(rep("g1", 5L), rep("g2", 4L))
)

extracted <- extract_sequence_ngrams(
  sequences,
  sequence_id_col = "id",
  order_col = "position",
  state_col = "state",
  metadata_cols = "group",
  min_length = 2,
  max_length = 3
)

positions <- summarise_sequence_motif_positions(
  extracted,
  position = "centre",
  scale = "relative",
  by = "group"
)

positions$summary
#>    group    motif_id motif_key     motif motif_length position_basis
#> 1     g1 L3:S1|S2|S1  S1|S2|S1 A > B > A            3         centre
#> 2     g1    L2:S1|S2     S1|S2     A > B            2         centre
#> 3     g1    L2:S2|S1     S2|S1     B > A            2         centre
#> 4     g1 L3:S2|S1|S2  S2|S1|S2 B > A > B            3         centre
#> 5     g1 L3:S1|S2|S3  S1|S2|S3 A > B > C            3         centre
#> 6     g1    L2:S2|S3     S2|S3     B > C            2         centre
#> 7     g2    L2:S1|S2     S1|S2     A > B            2         centre
#> 8     g2 L3:S1|S2|S3  S1|S2|S3 A > B > C            3         centre
#> 9     g2    L2:S2|S3     S2|S3     B > C            2         centre
#> 10    g2 L3:S2|S3|S2  S2|S3|S2 B > C > B            3         centre
#> 11    g2    L2:S3|S2     S3|S2     C > B            2         centre
#>    position_scale n_occurrences n_sequences min_position max_position
#> 1        relative             1           1    0.2500000    0.2500000
#> 2        relative             2           1    0.1250000    0.6250000
#> 3        relative             1           1    0.3750000    0.3750000
#> 4        relative             1           1    0.5000000    0.5000000
#> 5        relative             1           1    0.7500000    0.7500000
#> 6        relative             1           1    0.8750000    0.8750000
#> 7        relative             1           1    0.1666667    0.1666667
#> 8        relative             1           1    0.3333333    0.3333333
#> 9        relative             1           1    0.5000000    0.5000000
#> 10       relative             1           1    0.6666667    0.6666667
#> 11       relative             1           1    0.8333333    0.8333333
#>    mean_position median_position
#> 1      0.2500000       0.2500000
#> 2      0.3750000       0.3750000
#> 3      0.3750000       0.3750000
#> 4      0.5000000       0.5000000
#> 5      0.7500000       0.7500000
#> 6      0.8750000       0.8750000
#> 7      0.1666667       0.1666667
#> 8      0.3333333       0.3333333
#> 9      0.5000000       0.5000000
#> 10     0.6666667       0.6666667
#> 11     0.8333333       0.8333333
```
