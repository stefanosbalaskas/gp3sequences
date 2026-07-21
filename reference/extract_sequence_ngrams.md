# Extract Contiguous Sequence N-Grams

Enumerates contiguous state motifs from validated long-format sequence
data.

## Usage

``` r
extract_sequence_ngrams(
  data,
  sequence_id_col,
  order_col,
  state_col,
  duration_col = NULL,
  metadata_cols = NULL,
  expected_states = NULL,
  min_length = 2L,
  max_length = 3L,
  overlap = c("allow", "disallow"),
  separator = " > ",
  state_levels = NULL
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

- min_length:

  Positive whole number giving the shortest motif length.

- max_length:

  Positive whole number giving the longest motif length.

- overlap:

  Character value specifying whether overlapping occurrences of the same
  motif within the same sequence are `"allow"`ed or `"disallow"`ed.

- separator:

  Character value used only to display state labels in the
  human-readable `motif` column.

- state_levels:

  Optional atomic vector defining the complete state ordering. When
  omitted, factor levels are respected; otherwise observed labels are
  sorted deterministically.

## Value

A named list containing:

- `occurrences`: one row per retained contiguous motif occurrence;

- `motifs`: the distinct motif dictionary;

- `sequences`: sequence-level counts of candidate and retained
  occurrences;

- `state_dictionary`: the deterministic state dictionary;

- `audit`, `status`, and `mapping` from input validation;

- `settings`: the resolved motif extraction settings.

## Details

Motifs are contiguous windows only. No subsequence gaps, edit distances,
statistical tests, or substantive interpretations are introduced.
Consecutive repeated states are used exactly as supplied; any repeat
collapsing should be performed explicitly with
[`prepare_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/prepare_sequence_data.md)
before extraction.

With `overlap = "disallow"`, overlap is resolved independently within
each sequence-motif pair by a deterministic left-to-right greedy rule.
Different motifs and different motif lengths do not compete for
positions.

The collision-resistant `motif_id` and `motif_key` columns are derived
from deterministic state codes. The display separator may therefore also
occur inside a state label without changing motif identity.

## Examples

``` r
sequences <- data.frame(
  id = c(rep("s1", 5L), rep("s2", 4L)),
  position = c(1:5, 1:4),
  state = c("A", "B", "A", "B", "A", "A", "B", "A", "C")
)

ngrams <- extract_sequence_ngrams(
  sequences,
  sequence_id_col = "id",
  order_col = "position",
  state_col = "state",
  min_length = 2,
  max_length = 3,
  overlap = "allow"
)

ngrams$occurrences
#>    sequence_id    motif_id motif_key     motif motif_length start_index
#> 1           s1    L2:S1|S2     S1|S2     A > B            2           1
#> 2           s1 L3:S1|S2|S1  S1|S2|S1 A > B > A            3           1
#> 3           s1    L2:S2|S1     S2|S1     B > A            2           2
#> 4           s1 L3:S2|S1|S2  S2|S1|S2 B > A > B            3           2
#> 5           s1    L2:S1|S2     S1|S2     A > B            2           3
#> 6           s1 L3:S1|S2|S1  S1|S2|S1 A > B > A            3           3
#> 7           s1    L2:S2|S1     S2|S1     B > A            2           4
#> 8           s2    L2:S1|S2     S1|S2     A > B            2           1
#> 9           s2 L3:S1|S2|S1  S1|S2|S1 A > B > A            3           1
#> 10          s2    L2:S2|S1     S2|S1     B > A            2           2
#> 11          s2 L3:S2|S1|S3  S2|S1|S3 B > A > C            3           2
#> 12          s2    L2:S1|S3     S1|S3     A > C            2           3
#>    end_index start_order end_order start_original_row end_original_row
#> 1          2           1         2                  1                2
#> 2          3           1         3                  1                3
#> 3          3           2         3                  2                3
#> 4          4           2         4                  2                4
#> 5          4           3         4                  3                4
#> 6          5           3         5                  3                5
#> 7          5           4         5                  4                5
#> 8          2           1         2                  6                7
#> 9          3           1         3                  6                8
#> 10         3           2         3                  7                8
#> 11         4           2         4                  7                9
#> 12         4           3         4                  8                9
#>    occurrence_index
#> 1                 1
#> 2                 1
#> 3                 1
#> 4                 1
#> 5                 2
#> 6                 2
#> 7                 2
#> 8                 1
#> 9                 1
#> 10                1
#> 11                1
#> 12                1
ngrams$motifs
#>      motif_id motif_key     motif motif_length
#> 1    L2:S1|S2     S1|S2     A > B            2
#> 2    L2:S1|S3     S1|S3     A > C            2
#> 3    L2:S2|S1     S2|S1     B > A            2
#> 4 L3:S1|S2|S1  S1|S2|S1 A > B > A            3
#> 5 L3:S2|S1|S2  S2|S1|S2 B > A > B            3
#> 6 L3:S2|S1|S3  S2|S1|S3 B > A > C            3
```
