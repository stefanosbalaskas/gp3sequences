# Filter Sequence Motif Summaries

Applies transparent count, prevalence, length, and top-ranking filters
to sequence motif summaries.

## Usage

``` r
filter_sequence_motifs(
  x,
  min_occurrences = 1L,
  min_sequences = 1L,
  min_prevalence = 0,
  motif_lengths = NULL,
  top_n = NULL,
  rank_by = c("sequence_prevalence", "n_occurrences", "n_sequences"),
  ties = c("include", "first")
)
```

## Arguments

- x:

  A motif extraction, motif summary, or filtered-motif object.

- min_occurrences:

  Non-negative whole number giving the minimum total occurrence count.

- min_sequences:

  Non-negative whole number giving the minimum number of sequences
  containing the motif.

- min_prevalence:

  Minimum sequence prevalence between 0 and 1.

- motif_lengths:

  Optional vector of positive whole-number motif lengths to retain.

- top_n:

  Optional positive whole number giving the requested number of
  highest-ranked motifs.

- rank_by:

  Metric used for deterministic top-ranking: one of
  `"sequence_prevalence"`, `"n_occurrences"`, or `"n_sequences"`.

- ties:

  Character value controlling the top-`n` boundary. `"include"` retains
  every motif tied on `rank_by` with the final selected motif; `"first"`
  retains exactly `top_n` motifs after deterministic secondary sorting.

## Value

A named list containing the filtered `motifs` table, the matching
sequence-level rows in `by_sequence`, sequence and state dictionaries,
validation metadata, filter settings, and counts before and after
filtering.

## Details

Filtering is descriptive and deterministic. When `ties = "first"`, ties
are resolved by sequence prevalence, occurrence count, sequence count,
shorter motif length, and finally the collision-resistant motif key.

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

filtered <- filter_sequence_motifs(
  extracted,
  min_sequences = 2,
  top_n = 5,
  ties = "include"
)

filtered$motifs
#>      motif_id motif_key     motif motif_length n_occurrences n_sequences
#> 1    L2:S1|S2     S1|S2     A > B            2             3           2
#> 2    L2:S2|S1     S2|S1     B > A            2             3           2
#> 3 L3:S1|S2|S1  S1|S2|S1 A > B > A            3             3           2
#>   sequence_prevalence occurrence_share mean_occurrences_per_sequence
#> 1                   1             0.25                           1.5
#> 2                   1             0.25                           1.5
#> 3                   1             0.25                           1.5
#>   mean_occurrences_when_present
#> 1                           1.5
#> 2                           1.5
#> 3                           1.5
```
