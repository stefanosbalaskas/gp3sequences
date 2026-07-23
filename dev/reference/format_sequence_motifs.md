# Format Sequence Motif Summaries

Produces a stable, report-ready table from motif extraction, summary, or
filtered-motif output.

## Usage

``` r
format_sequence_motifs(
  x,
  digits = 3L,
  prevalence = c("proportion", "percent"),
  include_rank = TRUE,
  rank_by = c("sequence_prevalence", "n_occurrences", "n_sequences"),
  ties = c("min", "first"),
  include_ids = TRUE
)
```

## Arguments

- x:

  A motif extraction, motif summary, or filtered-motif object.

- digits:

  Whole number from 0 to 15 controlling numeric rounding.

- prevalence:

  Character value specifying whether prevalence and occurrence share are
  shown as `"proportion"`s or `"percent"`ages.

- include_rank:

  Logical value indicating whether to add a rank column.

- rank_by:

  Metric used to order and rank motifs: one of `"sequence_prevalence"`,
  `"n_occurrences"`, or `"n_sequences"`.

- ties:

  Character value specifying `"min"` shared ranks or deterministic
  `"first"` ranks.

- include_ids:

  Logical value indicating whether `motif_id` and `motif_key` should be
  included in the formatted table.

## Value

A named list containing `table`, validation metadata, and formatting
settings. The table contains only structural motif measurements.

## Details

Formatting changes display precision and units only. It does not change
the underlying motif counts or introduce substantive interpretation.

## Examples

``` r
sequences <- data.frame(
  id = c(rep("s1", 5L), rep("s2", 4L)),
  position = c(1:5, 1:4),
  state = c("A", "B", "A", "B", "A", "A", "B", "A", "C")
)

extracted <- extract_sequence_ngrams(
  sequences,
  sequence_id_col = "id",
  order_col = "position",
  state_col = "state"
)

formatted <- format_sequence_motifs(
  extracted,
  prevalence = "percent",
  digits = 1
)

formatted$table
#>   rank    motif_id motif_key     motif motif_length n_occurrences n_sequences
#> 1    1    L2:S1|S2     S1|S2     A > B            2             3           2
#> 2    1    L2:S2|S1     S2|S1     B > A            2             3           2
#> 3    1 L3:S1|S2|S1  S1|S2|S1 A > B > A            3             3           2
#> 4    4    L2:S1|S3     S1|S3     A > C            2             1           1
#> 5    4 L3:S2|S1|S2  S2|S1|S2 B > A > B            3             1           1
#> 6    4 L3:S2|S1|S3  S2|S1|S3 B > A > C            3             1           1
#>   sequence_prevalence_percent occurrence_share_percent
#> 1                         100                     25.0
#> 2                         100                     25.0
#> 3                         100                     25.0
#> 4                          50                      8.3
#> 5                          50                      8.3
#> 6                          50                      8.3
#>   mean_occurrences_per_sequence mean_occurrences_when_present
#> 1                           1.5                           1.5
#> 2                           1.5                           1.5
#> 3                           1.5                           1.5
#> 4                           0.5                           1.0
#> 5                           0.5                           1.0
#> 6                           0.5                           1.0
```
