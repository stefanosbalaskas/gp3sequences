# Getting Started with gp3sequences

## Purpose

`gp3sequences` accepts ordinary long-format ordered categorical data.
This article introduces the complete structural workflow: audit,
preparation, encoding, descriptive summaries, contiguous motifs,
distances, clustering, consensus, group comparison, and transition
structure.

All outputs are structural or statistical. They do not independently
establish attention, cognition, emotion, comprehension, intention,
diagnosis, causality, or other psychological attributes.

## Synthetic long-format data

Each sequence has an identifier, an explicit order, a categorical state,
a positive duration, participant metadata, and an assigned interface
group.

``` r

paths <- list(
  s1 = c("home", "search", "product", "cart", "checkout"),
  s2 = c("home", "search", "product", "cart", "home"),
  s3 = c("home", "category", "product", "cart", "checkout"),
  s4 = c("home", "category", "product", "search", "checkout"),
  s5 = c("home", "category", "search", "product", "checkout"),
  s6 = c("home", "search", "category", "product", "home"),
  s7 = c("home", "category", "product", "cart", "home"),
  s8 = c("home", "search", "product", "checkout", "home")
)

raw_sequences <- do.call(
  rbind,
  lapply(seq_along(paths), function(i) {
    data.frame(
      sequence_id = names(paths)[i],
      sequence_order = seq_along(paths[[i]]),
      state = paths[[i]],
      duration = 80 + 10 * seq_along(paths[[i]]) + i,
      participant_id = sprintf("p%02d", i),
      group = if (i <= 4L) "interface_a" else "interface_b",
      stringsAsFactors = FALSE
    )
  })
)

raw_sequences
#>    sequence_id sequence_order    state duration participant_id       group
#> 1           s1              1     home       91            p01 interface_a
#> 2           s1              2   search      101            p01 interface_a
#> 3           s1              3  product      111            p01 interface_a
#> 4           s1              4     cart      121            p01 interface_a
#> 5           s1              5 checkout      131            p01 interface_a
#> 6           s2              1     home       92            p02 interface_a
#> 7           s2              2   search      102            p02 interface_a
#> 8           s2              3  product      112            p02 interface_a
#> 9           s2              4     cart      122            p02 interface_a
#> 10          s2              5     home      132            p02 interface_a
#> 11          s3              1     home       93            p03 interface_a
#> 12          s3              2 category      103            p03 interface_a
#> 13          s3              3  product      113            p03 interface_a
#> 14          s3              4     cart      123            p03 interface_a
#> 15          s3              5 checkout      133            p03 interface_a
#> 16          s4              1     home       94            p04 interface_a
#> 17          s4              2 category      104            p04 interface_a
#> 18          s4              3  product      114            p04 interface_a
#> 19          s4              4   search      124            p04 interface_a
#> 20          s4              5 checkout      134            p04 interface_a
#> 21          s5              1     home       95            p05 interface_b
#> 22          s5              2 category      105            p05 interface_b
#> 23          s5              3   search      115            p05 interface_b
#> 24          s5              4  product      125            p05 interface_b
#> 25          s5              5 checkout      135            p05 interface_b
#> 26          s6              1     home       96            p06 interface_b
#> 27          s6              2   search      106            p06 interface_b
#> 28          s6              3 category      116            p06 interface_b
#> 29          s6              4  product      126            p06 interface_b
#> 30          s6              5     home      136            p06 interface_b
#> 31          s7              1     home       97            p07 interface_b
#> 32          s7              2 category      107            p07 interface_b
#> 33          s7              3  product      117            p07 interface_b
#> 34          s7              4     cart      127            p07 interface_b
#> 35          s7              5     home      137            p07 interface_b
#> 36          s8              1     home       98            p08 interface_b
#> 37          s8              2   search      108            p08 interface_b
#> 38          s8              3  product      118            p08 interface_b
#> 39          s8              4 checkout      128            p08 interface_b
#> 40          s8              5     home      138            p08 interface_b
```

## Audit, validate, and prepare

[`audit_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/audit_sequence_data.md)
returns a machine-readable issue table without modifying the input.
[`validate_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/validate_sequence_data.md)
adds a compact status contract.
[`prepare_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/prepare_sequence_data.md)
applies explicit policies and returns canonical data, an audit trail,
and a decision log.

``` r

audit <- audit_sequence_data(
  raw_sequences,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  duration_col = "duration",
  metadata_cols = c("participant_id", "group")
)

validation <- validate_sequence_data(
  raw_sequences,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  duration_col = "duration",
  metadata_cols = c("participant_id", "group")
)

prepared <- prepare_sequence_data(
  raw_sequences,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  duration_col = "duration",
  metadata_cols = c("participant_id", "group"),
  missing_state_policy = "error",
  duplicate_position_policy = "error",
  repeated_state_policy = "preserve",
  zero_duration_policy = "preserve",
  unknown_state_policy = "preserve",
  unused_state_levels = "preserve"
)

validation$status
#> [1] "pass"
prepared$status
#> [1] "pass"
prepared$mapping
#>                      role  source_column
#> 1             sequence_id    sequence_id
#> 2          sequence_order sequence_order
#> 3                   state          state
#> 4                duration       duration
#> 5 metadata:participant_id participant_id
#> 6          metadata:group          group
prepared$decisions
#>                   step             policy affected_rows
#> 1       missing_states              error             0
#> 2       unknown_states           preserve             0
#> 3       zero_durations           preserve             0
#> 4 duplicated_positions              error             0
#> 5            row_order deterministic_sort             0
#> 6  consecutive_repeats           preserve             0
#> 7  unused_state_levels           preserve             0
#> 8       column_mapping       canonicalise            40
#>                                                                       details
#> 1                          Missing states were retained as unresolved errors.
#> 2                                   Unknown states were preserved for review.
#> 3                                          Zero-duration rows were preserved.
#> 4                    Duplicated positions were retained as unresolved errors.
#> 5 Rows were ordered by sequence identifier, sequence order, and original row.
#> 6                                 Consecutive repeated states were preserved.
#> 7                                        Unused factor levels were preserved.
#> 8     Mapped columns were standardised while unmapped columns were preserved.
head(prepared$data)
#>   sequence_id sequence_order    state original_row duration participant_id
#> 1          s1              1     home            1       91            p01
#> 2          s1              2   search            2      101            p01
#> 3          s1              3  product            3      111            p01
#> 4          s1              4     cart            4      121            p01
#> 5          s1              5 checkout            5      131            p01
#> 6          s2              1     home            6       92            p02
#>         group
#> 1 interface_a
#> 2 interface_a
#> 3 interface_a
#> 4 interface_a
#> 5 interface_a
#> 6 interface_a
```

## Encode states and inspect basic structure

State codes are transparent identifiers derived from a deterministic
state ordering. The state, transition, and path helpers describe the
observed structure without assigning substantive meaning to the labels.

``` r

encoded <- encode_sequence_data(
  prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  duration_col = "duration",
  metadata_cols = c("participant_id", "group")
)

state_summary <- summarise_sequence_states(
  prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  duration_col = "duration",
  metadata_cols = c("participant_id", "group")
)

transition_summary <- summarise_sequence_transitions(
  prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = c("participant_id", "group"),
  include_self = TRUE
)

paths_table <- format_sequence_paths(
  prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = c("participant_id", "group")
)

encoded$dictionary
#>      state state_index state_code observed
#> 1     cart           1         S1     TRUE
#> 2 category           2         S2     TRUE
#> 3 checkout           3         S3     TRUE
#> 4     home           4         S4     TRUE
#> 5  product           5         S5     TRUE
#> 6   search           6         S6     TRUE
state_summary$overall
#>      state n_sequences sequence_proportion n_observations
#> 1     home           8               1.000             12
#> 2   search           6               0.750              6
#> 3  product           8               1.000              8
#> 4     cart           4               0.500              4
#> 5 checkout           5               0.625              5
#> 6 category           5               0.625              5
#>   observation_proportion duration_sum duration_proportion mean_duration
#> 1                  0.300         1299           0.2836245      108.2500
#> 2                  0.150          656           0.1432314      109.3333
#> 3                  0.200          936           0.2043668      117.0000
#> 4                  0.100          493           0.1076419      123.2500
#> 5                  0.125          661           0.1443231      132.2000
#> 6                  0.125          535           0.1168122      107.0000
head(transition_summary$overall)
#>   from_state to_state n_sequences sequence_proportion n_transitions
#> 1       home   search           4                0.50             4
#> 2     search  product           4                0.50             4
#> 3    product     cart           4                0.50             4
#> 4       cart checkout           2                0.25             2
#> 5       cart     home           2                0.25             2
#> 6       home category           4                0.50             4
#>   transition_proportion origin_transition_proportion
#> 1                0.1250                    0.5000000
#> 2                0.1250                    0.6666667
#> 3                0.1250                    0.5000000
#> 4                0.0625                    0.5000000
#> 5                0.0625                    0.5000000
#> 6                0.1250                    0.5000000
paths_table$paths
#>   sequence_id participant_id       group n_observations n_states
#> 1          s1            p01 interface_a              5        5
#> 2          s2            p02 interface_a              5        5
#> 3          s3            p03 interface_a              5        5
#> 4          s4            p04 interface_a              5        5
#> 5          s5            p05 interface_b              5        5
#> 6          s6            p06 interface_b              5        5
#> 7          s7            p07 interface_b              5        5
#> 8          s8            p08 interface_b              5        5
#>   n_unique_states start_state end_state
#> 1               5        home  checkout
#> 2               4        home      home
#> 3               5        home  checkout
#> 4               5        home  checkout
#> 5               5        home  checkout
#> 6               4        home      home
#> 7               4        home      home
#> 8               4        home      home
#>                                            path
#> 1     home > search > product > cart > checkout
#> 2         home > search > product > cart > home
#> 3   home > category > product > cart > checkout
#> 4 home > category > product > search > checkout
#> 5 home > category > search > product > checkout
#> 6     home > search > category > product > home
#> 7       home > category > product > cart > home
#> 8     home > search > product > checkout > home
```

## Discover contiguous motifs

Motifs are exact contiguous state windows. Their lengths, overlap rule,
prevalence denominator, filtering thresholds, and tie policy remain
explicit.

``` r

motif_occurrences <- extract_sequence_ngrams(
  prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = "group",
  min_length = 2L,
  max_length = 3L,
  overlap = "allow"
)

motif_summary <- summarise_sequence_motifs(motif_occurrences)

motif_filter <- filter_sequence_motifs(
  motif_summary,
  min_occurrences = 2L,
  min_sequences = 2L,
  min_prevalence = 0.20,
  motif_lengths = c(2L, 3L),
  top_n = 10L,
  rank_by = "sequence_prevalence",
  ties = "include"
)

motif_table <- format_sequence_motifs(
  motif_filter,
  prevalence = "percent",
  digits = 1L
)

motif_table$table
#>    rank    motif_id motif_key                       motif motif_length
#> 1     1    L2:S2|S5     S2|S5          category > product            2
#> 2     1    L2:S4|S2     S4|S2             home > category            2
#> 3     1    L2:S4|S6     S4|S6               home > search            2
#> 4     1    L2:S5|S1     S5|S1              product > cart            2
#> 5     1    L2:S6|S5     S6|S5            search > product            2
#> 6     6 L3:S4|S2|S5  S4|S2|S5   home > category > product            3
#> 7     6 L3:S4|S6|S5  S4|S6|S5     home > search > product            3
#> 8     8    L2:S1|S3     S1|S3             cart > checkout            2
#> 9     8    L2:S1|S4     S1|S4                 cart > home            2
#> 10    8    L2:S5|S3     S5|S3          product > checkout            2
#> 11    8 L3:S2|S5|S1  S2|S5|S1   category > product > cart            3
#> 12    8 L3:S5|S1|S3  S5|S1|S3   product > cart > checkout            3
#> 13    8 L3:S5|S1|S4  S5|S1|S4       product > cart > home            3
#> 14    8 L3:S6|S5|S1  S6|S5|S1     search > product > cart            3
#> 15    8 L3:S6|S5|S3  S6|S5|S3 search > product > checkout            3
#>    n_occurrences n_sequences sequence_prevalence_percent
#> 1              4           4                        50.0
#> 2              4           4                        50.0
#> 3              4           4                        50.0
#> 4              4           4                        50.0
#> 5              4           4                        50.0
#> 6              3           3                        37.5
#> 7              3           3                        37.5
#> 8              2           2                        25.0
#> 9              2           2                        25.0
#> 10             2           2                        25.0
#> 11             2           2                        25.0
#> 12             2           2                        25.0
#> 13             2           2                        25.0
#> 14             2           2                        25.0
#> 15             2           2                        25.0
#>    occurrence_share_percent mean_occurrences_per_sequence
#> 1                       7.1                           0.5
#> 2                       7.1                           0.5
#> 3                       7.1                           0.5
#> 4                       7.1                           0.5
#> 5                       7.1                           0.5
#> 6                       5.4                           0.4
#> 7                       5.4                           0.4
#> 8                       3.6                           0.2
#> 9                       3.6                           0.2
#> 10                      3.6                           0.2
#> 11                      3.6                           0.2
#> 12                      3.6                           0.2
#> 13                      3.6                           0.2
#> 14                      3.6                           0.2
#> 15                      3.6                           0.2
#>    mean_occurrences_when_present
#> 1                              1
#> 2                              1
#> 3                              1
#> 4                              1
#> 5                              1
#> 6                              1
#> 7                              1
#> 8                              1
#> 9                              1
#> 10                             1
#> 11                             1
#> 12                             1
#> 13                             1
#> 14                             1
#> 15                             1
```

## Compare sequences through distances and clustering

Distance choice is part of the analysis specification. This example uses
LCS distance followed by average-linkage hierarchical clustering.
Validation summaries describe the supplied solution; they do not prove
that the clusters are natural or substantively meaningful.

``` r

lcs_distance <- compute_sequence_distance(
  prepared$data,
  method = "lcs",
  normalise = "max_length"
)

cluster_fit <- cluster_sequences(
  lcs_distance,
  k = 2L,
  method = "hierarchical",
  linkage = "average"
)

cluster_validation <- validate_sequence_clusters(cluster_fit)
representatives <- extract_representative_sequences(cluster_fit)

summarise_sequence_distance(lcs_distance)$overall
#>   n_sequences n_pairs mean_distance median_distance min_distance max_distance
#> 1           8      28     0.6142857             0.6          0.4          1.2
cluster_fit$assignments
#> s1 s2 s3 s4 s5 s6 s7 s8 
#>  1  1  2  2  2  1  1  1
cluster_validation$overall
#>   n_sequences n_clusters average_silhouette minimum_silhouette dunn_index
#> 1           8          2          0.3100965         -0.1111111        0.5
#>   within_between_ratio singleton_clusters
#> 1            0.6837607                  0
representatives
#>   cluster rank sequence_id mean_within_distance
#> 1       1    1          s2                  0.4
#> 2       2    1          s3                  0.4
```

## Consensus and descriptive group comparison

Aligned-position consensus and group contrasts remain descriptive. The
consensus is not a behavioural norm, and contrasts do not establish a
causal mechanism.

``` r

consensus <- create_consensus_sequence(
  prepared$data,
  group_cols = "group",
  tie_method = "first",
  state_levels = encoded$dictionary$state
)

group_comparison <- compare_sequence_groups(
  prepared$data,
  group_col = "group"
)

summarise_consensus_agreement(consensus, by = "group")
#>         group n_positions mean_agreement median_agreement min_agreement
#> 1 interface_a           5           0.80             0.75           0.5
#> 2 interface_b           5           0.65             0.50           0.5
#>   max_agreement weighted_agreement n_ties n_below_threshold threshold
#> 1             1               0.80      1                 0       0.5
#> 2             1               0.65      1                 0       0.5
format_consensus_sequence(consensus, include_agreement = TRUE)
#>         group
#> 1 interface_a
#> 2 interface_b
#>                                                                                      path
#> 1 home [1.000] -> category [0.500] -> product [1.000] -> cart [0.750] -> checkout [0.750]
#> 2  home [1.000] -> category [0.500] -> product [0.500] -> product [0.500] -> home [0.750]
#>   n_positions
#> 1           5
#> 2           5
head(group_comparison$state_contrasts)
#>       group_1     group_2    state event_share_group_1 event_share_group_2
#> 1 interface_a interface_b     cart                0.15                0.05
#> 2 interface_a interface_b category                0.10                0.15
#> 3 interface_a interface_b checkout                0.15                0.10
#> 4 interface_a interface_b     home                0.25                0.35
#> 5 interface_a interface_b  product                0.20                0.20
#> 6 interface_a interface_b   search                0.15                0.15
#>   event_share_difference event_share_ratio sequence_prevalence_group_1
#> 1                   0.10         3.0000000                        0.75
#> 2                  -0.05         0.6666667                        0.50
#> 3                   0.05         1.5000000                        0.75
#> 4                  -0.10         0.7142857                        1.00
#> 5                   0.00         1.0000000                        1.00
#> 6                   0.00         1.0000000                        0.75
#>   sequence_prevalence_group_2 sequence_prevalence_difference
#> 1                        0.25                           0.50
#> 2                        0.75                          -0.25
#> 3                        0.50                           0.25
#> 4                        1.00                           0.00
#> 5                        1.00                           0.00
#> 6                        0.75                           0.00
#>   sequence_prevalence_ratio
#> 1                 3.0000000
#> 2                 0.6666667
#> 3                 1.5000000
#> 4                 1.0000000
#> 5                 1.0000000
#> 6                 1.0000000
head(group_comparison$transition_contrasts)
#>       group_1     group_2          transition occurrence_share_group_1
#> 1 interface_a interface_b    cart -> checkout                   0.1250
#> 2 interface_a interface_b        cart -> home                   0.0625
#> 3 interface_a interface_b category -> product                   0.1250
#> 4 interface_a interface_b    home -> category                   0.1250
#> 5 interface_a interface_b      home -> search                   0.1250
#> 6 interface_a interface_b     product -> cart                   0.1875
#>   occurrence_share_group_2 occurrence_share_difference occurrence_share_ratio
#> 1                   0.0000                       0.125                     NA
#> 2                   0.0625                       0.000                      1
#> 3                   0.1250                       0.000                      1
#> 4                   0.1250                       0.000                      1
#> 5                   0.1250                       0.000                      1
#> 6                   0.0625                       0.125                      3
#>   sequence_prevalence_group_1 sequence_prevalence_group_2
#> 1                        0.50                        0.00
#> 2                        0.25                        0.25
#> 3                        0.50                        0.50
#> 4                        0.50                        0.50
#> 5                        0.50                        0.50
#> 6                        0.75                        0.25
#>   sequence_prevalence_difference sequence_prevalence_ratio
#> 1                            0.5                        NA
#> 2                            0.0                         1
#> 3                            0.0                         1
#> 4                            0.0                         1
#> 5                            0.0                         1
#> 6                            0.5                         3
group_comparison$length_contrasts
#>       group_1     group_2 mean_length_group_1 mean_length_group_2
#> 1 interface_a interface_b                   5                   5
#>   mean_length_difference median_length_group_1 median_length_group_2
#> 1                      0                     5                     5
#>   median_length_difference
#> 1                        0
```

## Transition structure

A first-order transition network summarises observed state-to-state
movement. Centrality and community outputs are graph descriptors, not
measures of attention, influence, preference, or intention.

``` r

network <- create_transition_network(
  prepared$data,
  normalise = "from",
  include_self = TRUE
)

network
#>    group_key  context from_state to_state count sequence_count
#> 1    __all__     cart       cart checkout     2              2
#> 2    __all__     cart       cart     home     2              2
#> 3    __all__ category   category  product     4              4
#> 4    __all__ category   category   search     1              1
#> 5    __all__ checkout   checkout     home     1              1
#> 6    __all__     home       home category     4              4
#> 7    __all__     home       home   search     4              4
#> 8    __all__  product    product     cart     4              4
#> 9    __all__  product    product checkout     2              2
#> 10   __all__  product    product     home     1              1
#> 11   __all__  product    product   search     1              1
#> 12   __all__   search     search category     1              1
#> 13   __all__   search     search checkout     1              1
#> 14   __all__   search     search  product     4              4
#>    sequence_prevalence    weight
#> 1                0.250 0.5000000
#> 2                0.250 0.5000000
#> 3                0.500 0.8000000
#> 4                0.125 0.2000000
#> 5                0.125 1.0000000
#> 6                0.500 0.5000000
#> 7                0.500 0.5000000
#> 8                0.500 0.5000000
#> 9                0.250 0.2500000
#> 10               0.125 0.1250000
#> 11               0.125 0.1250000
#> 12               0.125 0.1666667
#> 13               0.125 0.1666667
#> 14               0.500 0.6666667
summarise_transition_centrality(network)
#>      state out_degree in_degree total_degree out_strength in_strength
#> 1     cart          2         1            3            1   0.5000000
#> 2 category          2         2            4            1   0.6666667
#> 3 checkout          1         3            4            1   0.9166667
#> 4     home          2         3            5            1   1.6250000
#> 5  product          4         2            6            1   1.4666667
#> 6   search          3         3            6            1   0.8250000
#>   total_strength closeness betweenness  pagerank
#> 1       1.500000 0.2898551         0.0 0.1162551
#> 2       1.666667 0.2500000         2.5 0.1415007
#> 3       1.916667 0.2857143         0.5 0.1434103
#> 4       2.625000 0.2531646         7.5 0.2191209
#> 5       2.466667 0.2272727         6.0 0.2147178
#> 6       1.825000 0.2272727         4.5 0.1649953
detect_transition_communities(network)
#>      state community
#> 1     cart         1
#> 2 category         2
#> 3 checkout         1
#> 4     home         1
#> 5  product         2
#> 6   search         2
```

## Continue with focused articles

The package website contains focused articles for motif positions,
consensus and groups, distances and clustering, transition networks,
latent models, and optional ecosystem adapters. The method-selection
article provides a compact guide to choosing among them.
