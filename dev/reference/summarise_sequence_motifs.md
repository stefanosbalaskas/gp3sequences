# Summarise Contiguous Sequence Motifs

Aggregates extracted contiguous motif occurrences by sequence and
overall.

## Usage

``` r
summarise_sequence_motifs(x)
```

## Arguments

- x:

  An object returned by
  [`extract_sequence_ngrams()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/extract_sequence_ngrams.md).

## Value

A named list containing:

- `by_sequence`: occurrence counts for each sequence-motif pair;

- `overall`: total occurrence counts, sequence counts, sequence
  prevalence, occurrence share, and mean occurrence rates;

- `sequences` and `state_dictionary` from extraction;

- `audit`, `status`, `mapping`, and extraction settings;

- scalar counts for sequences, occurrences, and distinct motifs.

## Details

Sequence prevalence uses every validated sequence in the extraction
object as its denominator, including sequences too short to contain a
requested motif. Results are sorted deterministically by sequence
prevalence, occurrence count, motif length, and motif key.

The function reports structural recurrence only. It does not perform
significance testing or infer psychological, cognitive, emotional, or
diagnostic attributes.

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
  state_col = "state",
  min_length = 2,
  max_length = 3
)

summaries <- summarise_sequence_motifs(extracted)
summaries$by_sequence
#>   sequence_id    motif_id motif_key     motif motif_length n_occurrences
#> 1          s1    L2:S1|S2     S1|S2     A > B            2             2
#> 2          s2    L2:S1|S2     S1|S2     A > B            2             1
#> 3          s1    L2:S2|S1     S2|S1     B > A            2             2
#> 4          s2    L2:S2|S1     S2|S1     B > A            2             1
#> 5          s1 L3:S1|S2|S1  S1|S2|S1 A > B > A            3             2
#> 6          s2 L3:S1|S2|S1  S1|S2|S1 A > B > A            3             1
#> 7          s2    L2:S1|S3     S1|S3     A > C            2             1
#> 8          s1 L3:S2|S1|S2  S2|S1|S2 B > A > B            3             1
#> 9          s2 L3:S2|S1|S3  S2|S1|S3 B > A > C            3             1
#>   first_start_index last_start_index
#> 1                 1                3
#> 2                 1                1
#> 3                 2                4
#> 4                 2                2
#> 5                 1                3
#> 6                 1                1
#> 7                 3                3
#> 8                 2                2
#> 9                 2                2
summaries$overall
#>      motif_id motif_key     motif motif_length n_occurrences n_sequences
#> 1    L2:S1|S2     S1|S2     A > B            2             3           2
#> 2    L2:S2|S1     S2|S1     B > A            2             3           2
#> 3 L3:S1|S2|S1  S1|S2|S1 A > B > A            3             3           2
#> 4    L2:S1|S3     S1|S3     A > C            2             1           1
#> 5 L3:S2|S1|S2  S2|S1|S2 B > A > B            3             1           1
#> 6 L3:S2|S1|S3  S2|S1|S3 B > A > C            3             1           1
#>   sequence_prevalence occurrence_share mean_occurrences_per_sequence
#> 1                 1.0       0.25000000                           1.5
#> 2                 1.0       0.25000000                           1.5
#> 3                 1.0       0.25000000                           1.5
#> 4                 0.5       0.08333333                           0.5
#> 5                 0.5       0.08333333                           0.5
#> 6                 0.5       0.08333333                           0.5
#>   mean_occurrences_when_present
#> 1                           1.5
#> 2                           1.5
#> 3                           1.5
#> 4                           1.0
#> 5                           1.0
#> 6                           1.0
```
