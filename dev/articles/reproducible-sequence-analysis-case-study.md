# Reproducible Sequence Analysis: A Synthetic Case Study

## Study objective

This synthetic example examines navigation-path structure under two
assigned interface conditions. It demonstrates an auditable workflow
rather than a claim that sequence structure reveals hidden attention,
preference, cognition, emotion, intention, or causality.

## Synthetic study data

The data contain 12 independent participant-level sequences of equal
maximum length. Interface condition is assigned as sequence-level
metadata and all state labels are directly observed navigation
locations.

``` r

paths <- list(
  s01 = c("home", "search", "product", "cart", "checkout", "confirmation"),
  s02 = c("home", "search", "product", "reviews", "cart", "checkout"),
  s03 = c("home", "category", "product", "cart", "checkout", "confirmation"),
  s04 = c("home", "search", "category", "product", "cart", "checkout"),
  s05 = c("home", "category", "product", "reviews", "cart", "checkout"),
  s06 = c("home", "search", "product", "cart", "home", "search"),
  s07 = c("home", "category", "search", "product", "checkout", "confirmation"),
  s08 = c("home", "category", "product", "compare", "cart", "checkout"),
  s09 = c("home", "search", "compare", "product", "checkout", "home"),
  s10 = c("home", "category", "compare", "product", "cart", "checkout"),
  s11 = c("home", "search", "product", "compare", "cart", "checkout"),
  s12 = c("home", "category", "product", "checkout", "confirmation", "home")
)

case_data <- do.call(
  rbind,
  lapply(seq_along(paths), function(i) {
    data.frame(
      sequence_id = names(paths)[i],
      sequence_order = seq_along(paths[[i]]),
      state = paths[[i]],
      duration = 75 + 6 * seq_along(paths[[i]]) + 2 * i,
      participant_id = sprintf("p%02d", i),
      interface = if (i <= 6L) "interface_a" else "interface_b",
      stringsAsFactors = FALSE
    )
  })
)

head(case_data, 12L)
#>    sequence_id sequence_order        state duration participant_id   interface
#> 1          s01              1         home       83            p01 interface_a
#> 2          s01              2       search       89            p01 interface_a
#> 3          s01              3      product       95            p01 interface_a
#> 4          s01              4         cart      101            p01 interface_a
#> 5          s01              5     checkout      107            p01 interface_a
#> 6          s01              6 confirmation      113            p01 interface_a
#> 7          s02              1         home       85            p02 interface_a
#> 8          s02              2       search       91            p02 interface_a
#> 9          s02              3      product       97            p02 interface_a
#> 10         s02              4      reviews      103            p02 interface_a
#> 11         s02              5         cart      109            p02 interface_a
#> 12         s02              6     checkout      115            p02 interface_a
```

## Prespecified preparation

The synthetic input is expected to be complete and uniquely ordered.
Policies therefore refuse missing states and duplicate positions while
preserving repeated states and positive durations.

``` r

case_audit <- audit_sequence_data(
  case_data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  duration_col = "duration",
  metadata_cols = c("participant_id", "interface")
)

case_prepared <- prepare_sequence_data(
  case_data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  duration_col = "duration",
  metadata_cols = c("participant_id", "interface"),
  missing_state_policy = "error",
  duplicate_position_policy = "error",
  repeated_state_policy = "preserve",
  zero_duration_policy = "preserve",
  unknown_state_policy = "preserve",
  unused_state_levels = "preserve"
)

case_audit
#> [1] sequence_id row         column      issue_code  severity    value      
#> [7] message     action     
#> <0 rows> (or 0-length row.names)
case_prepared$status
#> [1] "pass"
case_prepared$decisions
#>                   step             policy affected_rows
#> 1       missing_states              error             0
#> 2       unknown_states           preserve             0
#> 3       zero_durations           preserve             0
#> 4 duplicated_positions              error             0
#> 5            row_order deterministic_sort             0
#> 6  consecutive_repeats           preserve             0
#> 7  unused_state_levels           preserve             0
#> 8       column_mapping       canonicalise            72
#>                                                                       details
#> 1                          Missing states were retained as unresolved errors.
#> 2                                   Unknown states were preserved for review.
#> 3                                          Zero-duration rows were preserved.
#> 4                    Duplicated positions were retained as unresolved errors.
#> 5 Rows were ordered by sequence identifier, sequence order, and original row.
#> 6                                 Consecutive repeated states were preserved.
#> 7                                        Unused factor levels were preserved.
#> 8     Mapped columns were standardised while unmapped columns were preserved.
```

## Structural summaries

``` r

state_summary <- summarise_sequence_states(
  case_prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  duration_col = "duration",
  metadata_cols = c("participant_id", "interface")
)

transition_summary <- summarise_sequence_transitions(
  case_prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = c("participant_id", "interface"),
  include_self = TRUE
)

path_summary <- format_sequence_paths(
  case_prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = c("participant_id", "interface")
)

state_summary$overall
#>          state n_sequences sequence_proportion n_observations
#> 1         home          12           1.0000000             15
#> 2       search           7           0.5833333              8
#> 3      product          12           1.0000000             12
#> 4         cart           9           0.7500000              9
#> 5     checkout          11           0.9166667             11
#> 6 confirmation           4           0.3333333              4
#> 7      reviews           2           0.1666667              2
#> 8     category           7           0.5833333              7
#> 9      compare           4           0.3333333              4
#>   observation_proportion duration_sum duration_proportion mean_duration
#> 1             0.20833333         1509          0.19227829      100.6000
#> 2             0.11111111          818          0.10423038      102.2500
#> 3             0.16666667         1296          0.16513761      108.0000
#> 4             0.12500000         1027          0.13086137      114.1111
#> 5             0.15277778         1329          0.16934251      120.8182
#> 6             0.05555556          484          0.06167176      121.0000
#> 7             0.02777778          212          0.02701325      106.0000
#> 8             0.09722222          713          0.09085117      101.8571
#> 9             0.05555556          460          0.05861366      115.0000
head(transition_summary$overall)
#>   from_state     to_state n_sequences sequence_proportion n_transitions
#> 1       home       search           6           0.5000000             7
#> 2     search      product           5           0.4166667             5
#> 3    product         cart           5           0.4166667             5
#> 4       cart     checkout           8           0.6666667             8
#> 5   checkout confirmation           4           0.3333333             4
#> 6    product      reviews           2           0.1666667             2
#>   transition_proportion origin_transition_proportion
#> 1            0.11666667                    0.5384615
#> 2            0.08333333                    0.7142857
#> 3            0.08333333                    0.4166667
#> 4            0.13333333                    0.8888889
#> 5            0.06666667                    0.8000000
#> 6            0.03333333                    0.1666667
path_summary$paths
#>    sequence_id participant_id   interface n_observations n_states
#> 1          s01            p01 interface_a              6        6
#> 2          s02            p02 interface_a              6        6
#> 3          s03            p03 interface_a              6        6
#> 4          s04            p04 interface_a              6        6
#> 5          s05            p05 interface_a              6        6
#> 6          s06            p06 interface_a              6        6
#> 7          s07            p07 interface_b              6        6
#> 8          s08            p08 interface_b              6        6
#> 9          s09            p09 interface_b              6        6
#> 10         s10            p10 interface_b              6        6
#> 11         s11            p11 interface_b              6        6
#> 12         s12            p12 interface_b              6        6
#>    n_unique_states start_state    end_state
#> 1                6        home confirmation
#> 2                6        home     checkout
#> 3                6        home confirmation
#> 4                6        home     checkout
#> 5                6        home     checkout
#> 6                4        home       search
#> 7                6        home confirmation
#> 8                6        home     checkout
#> 9                5        home         home
#> 10               6        home     checkout
#> 11               6        home     checkout
#> 12               5        home         home
#>                                                            path
#> 1      home > search > product > cart > checkout > confirmation
#> 2           home > search > product > reviews > cart > checkout
#> 3    home > category > product > cart > checkout > confirmation
#> 4          home > search > category > product > cart > checkout
#> 5         home > category > product > reviews > cart > checkout
#> 6                home > search > product > cart > home > search
#> 7  home > category > search > product > checkout > confirmation
#> 8         home > category > product > compare > cart > checkout
#> 9           home > search > compare > product > checkout > home
#> 10        home > category > compare > product > cart > checkout
#> 11          home > search > product > compare > cart > checkout
#> 12   home > category > product > checkout > confirmation > home
```

## Recurring contiguous motifs

``` r

case_motifs <- extract_sequence_ngrams(
  case_prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = "interface",
  min_length = 2L,
  max_length = 3L,
  overlap = "allow"
)

case_motif_summary <- summarise_sequence_motifs(case_motifs)
case_motif_filter <- filter_sequence_motifs(
  case_motif_summary,
  min_occurrences = 2L,
  min_sequences = 2L,
  min_prevalence = 0.15,
  motif_lengths = c(2L, 3L),
  top_n = 12L,
  rank_by = "sequence_prevalence",
  ties = "include"
)

format_sequence_motifs(
  case_motif_filter,
  prevalence = "percent",
  digits = 1L
)$table
#>    rank    motif_id motif_key                             motif motif_length
#> 1     1    L2:S1|S3     S1|S3                   cart > checkout            2
#> 2     2    L2:S6|S9     S6|S9                     home > search            2
#> 3     2    L2:S6|S2     S6|S2                   home > category            2
#> 4     4    L2:S2|S7     S2|S7                category > product            2
#> 5     4    L2:S7|S1     S7|S1                    product > cart            2
#> 6     4    L2:S9|S7     S9|S7                  search > product            2
#> 7     7    L2:S3|S5     S3|S5           checkout > confirmation            2
#> 8     7 L3:S6|S2|S7  S6|S2|S7         home > category > product            3
#> 9     7 L3:S6|S9|S7  S6|S9|S7           home > search > product            3
#> 10    7 L3:S7|S1|S3  S7|S1|S3         product > cart > checkout            3
#> 11   11    L2:S7|S3     S7|S3                product > checkout            2
#> 12   12    L2:S4|S1     S4|S1                    compare > cart            2
#> 13   12    L2:S4|S7     S4|S7                 compare > product            2
#> 14   12    L2:S7|S4     S7|S4                 product > compare            2
#> 15   12    L2:S7|S8     S7|S8                 product > reviews            2
#> 16   12    L2:S8|S1     S8|S1                    reviews > cart            2
#> 17   12 L3:S1|S3|S5  S1|S3|S5    cart > checkout > confirmation            3
#> 18   12 L3:S2|S7|S1  S2|S7|S1         category > product > cart            3
#> 19   12 L3:S4|S1|S3  S4|S1|S3         compare > cart > checkout            3
#> 20   12 L3:S7|S3|S5  S7|S3|S5 product > checkout > confirmation            3
#> 21   12 L3:S7|S4|S1  S7|S4|S1          product > compare > cart            3
#> 22   12 L3:S7|S8|S1  S7|S8|S1          product > reviews > cart            3
#> 23   12 L3:S8|S1|S3  S8|S1|S3         reviews > cart > checkout            3
#> 24   12 L3:S9|S7|S1  S9|S7|S1           search > product > cart            3
#>    n_occurrences n_sequences sequence_prevalence_percent
#> 1              8           8                        66.7
#> 2              7           6                        50.0
#> 3              6           6                        50.0
#> 4              5           5                        41.7
#> 5              5           5                        41.7
#> 6              5           5                        41.7
#> 7              4           4                        33.3
#> 8              4           4                        33.3
#> 9              4           4                        33.3
#> 10             4           4                        33.3
#> 11             3           3                        25.0
#> 12             2           2                        16.7
#> 13             2           2                        16.7
#> 14             2           2                        16.7
#> 15             2           2                        16.7
#> 16             2           2                        16.7
#> 17             2           2                        16.7
#> 18             2           2                        16.7
#> 19             2           2                        16.7
#> 20             2           2                        16.7
#> 21             2           2                        16.7
#> 22             2           2                        16.7
#> 23             2           2                        16.7
#> 24             2           2                        16.7
#>    occurrence_share_percent mean_occurrences_per_sequence
#> 1                       7.4                           0.7
#> 2                       6.5                           0.6
#> 3                       5.6                           0.5
#> 4                       4.6                           0.4
#> 5                       4.6                           0.4
#> 6                       4.6                           0.4
#> 7                       3.7                           0.3
#> 8                       3.7                           0.3
#> 9                       3.7                           0.3
#> 10                      3.7                           0.3
#> 11                      2.8                           0.2
#> 12                      1.9                           0.2
#> 13                      1.9                           0.2
#> 14                      1.9                           0.2
#> 15                      1.9                           0.2
#> 16                      1.9                           0.2
#> 17                      1.9                           0.2
#> 18                      1.9                           0.2
#> 19                      1.9                           0.2
#> 20                      1.9                           0.2
#> 21                      1.9                           0.2
#> 22                      1.9                           0.2
#> 23                      1.9                           0.2
#> 24                      1.9                           0.2
#>    mean_occurrences_when_present
#> 1                            1.0
#> 2                            1.2
#> 3                            1.0
#> 4                            1.0
#> 5                            1.0
#> 6                            1.0
#> 7                            1.0
#> 8                            1.0
#> 9                            1.0
#> 10                           1.0
#> 11                           1.0
#> 12                           1.0
#> 13                           1.0
#> 14                           1.0
#> 15                           1.0
#> 16                           1.0
#> 17                           1.0
#> 18                           1.0
#> 19                           1.0
#> 20                           1.0
#> 21                           1.0
#> 22                           1.0
#> 23                           1.0
#> 24                           1.0
```

## Consensus and condition contrasts

``` r

state_order <- sort(unique(case_prepared$data$state), method = "radix")

case_consensus <- create_consensus_sequence(
  case_prepared$data,
  group_cols = "interface",
  tie_method = "first",
  state_levels = state_order
)

case_comparison <- compare_sequence_groups(
  case_prepared$data,
  group_col = "interface"
)

format_consensus_sequence(case_consensus, include_agreement = TRUE)
#>     interface
#> 1 interface_a
#> 2 interface_b
#>                                                                                                         path
#> 1      home [1.000] -> search [0.667] -> product [0.833] -> cart [0.500] -> cart [0.500] -> checkout [0.500]
#> 2 home [1.000] -> category [0.667] -> product [0.500] -> product [0.500] -> cart [0.500] -> checkout [0.500]
#>   n_positions
#> 1           6
#> 2           6
summarise_consensus_agreement(case_consensus, by = "group")
#>     interface n_positions mean_agreement median_agreement min_agreement
#> 1 interface_a           6      0.6666667        0.5833333           0.5
#> 2 interface_b           6      0.6111111        0.5000000           0.5
#>   max_agreement weighted_agreement n_ties n_below_threshold threshold
#> 1             1          0.6666667      0                 0       0.5
#> 2             1          0.6111111      0                 0       0.5
head(case_comparison$state_contrasts)
#>       group_1     group_2        state event_share_group_1 event_share_group_2
#> 1 interface_a interface_b         cart          0.16666667          0.08333333
#> 2 interface_a interface_b     category          0.08333333          0.11111111
#> 3 interface_a interface_b     checkout          0.13888889          0.16666667
#> 4 interface_a interface_b      compare          0.00000000          0.11111111
#> 5 interface_a interface_b confirmation          0.05555556          0.05555556
#> 6 interface_a interface_b         home          0.19444444          0.22222222
#>   event_share_difference event_share_ratio sequence_prevalence_group_1
#> 1             0.08333333         2.0000000                   1.0000000
#> 2            -0.02777778         0.7500000                   0.5000000
#> 3            -0.02777778         0.8333333                   0.8333333
#> 4            -0.11111111         0.0000000                   0.0000000
#> 5             0.00000000         1.0000000                   0.3333333
#> 6            -0.02777778         0.8750000                   1.0000000
#>   sequence_prevalence_group_2 sequence_prevalence_difference
#> 1                   0.5000000                      0.5000000
#> 2                   0.6666667                     -0.1666667
#> 3                   1.0000000                     -0.1666667
#> 4                   0.6666667                     -0.6666667
#> 5                   0.3333333                      0.0000000
#> 6                   1.0000000                      0.0000000
#>   sequence_prevalence_ratio
#> 1                 2.0000000
#> 2                 0.7500000
#> 3                 0.8333333
#> 4                 0.0000000
#> 5                 1.0000000
#> 6                 1.0000000
head(case_comparison$transition_contrasts)
#>       group_1     group_2               transition occurrence_share_group_1
#> 1 interface_a interface_b         cart -> checkout               0.16666667
#> 2 interface_a interface_b             cart -> home               0.03333333
#> 3 interface_a interface_b      category -> product               0.10000000
#> 4 interface_a interface_b checkout -> confirmation               0.06666667
#> 5 interface_a interface_b         home -> category               0.06666667
#> 6 interface_a interface_b           home -> search               0.16666667
#>   occurrence_share_group_2 occurrence_share_difference occurrence_share_ratio
#> 1               0.10000000                  0.06666667               1.666667
#> 2               0.00000000                  0.03333333                     NA
#> 3               0.06666667                  0.03333333               1.500000
#> 4               0.06666667                  0.00000000               1.000000
#> 5               0.13333333                 -0.06666667               0.500000
#> 6               0.06666667                  0.10000000               2.500000
#>   sequence_prevalence_group_1 sequence_prevalence_group_2
#> 1                   0.8333333                   0.5000000
#> 2                   0.1666667                   0.0000000
#> 3                   0.5000000                   0.3333333
#> 4                   0.3333333                   0.3333333
#> 5                   0.3333333                   0.6666667
#> 6                   0.6666667                   0.3333333
#>   sequence_prevalence_difference sequence_prevalence_ratio
#> 1                      0.3333333                  1.666667
#> 2                      0.1666667                        NA
#> 3                      0.1666667                  1.500000
#> 4                      0.0000000                  1.000000
#> 5                     -0.3333333                  0.500000
#> 6                      0.3333333                  2.000000
case_comparison$length_contrasts
#>       group_1     group_2 mean_length_group_1 mean_length_group_2
#> 1 interface_a interface_b                   6                   6
#>   mean_length_difference median_length_group_1 median_length_group_2
#> 1                      0                     6                     6
#>   median_length_difference
#> 1                        0
```

## Distance, clustering, and representatives

The clustering layer is declared in advance as normalised LCS distance,
two-cluster average-linkage hierarchical clustering, and standard
structural validation summaries.

``` r

case_distance <- compute_sequence_distance(
  case_prepared$data,
  method = "lcs",
  normalise = "max_length"
)

case_cluster <- cluster_sequences(
  case_distance,
  k = 2L,
  method = "hierarchical",
  linkage = "average"
)

case_cluster_validation <- validate_sequence_clusters(case_cluster)
case_representatives <- extract_representative_sequences(case_cluster)

summarise_sequence_distance(case_distance)$overall
#>   n_sequences n_pairs mean_distance median_distance min_distance max_distance
#> 1          12      66     0.6060606       0.6666667    0.3333333            1
case_cluster$assignments
#> s01 s02 s03 s04 s05 s06 s07 s08 s09 s10 s11 s12 
#>   1   1   1   1   1   2   1   1   2   1   1   1
case_cluster_validation$overall
#>   n_sequences n_clusters average_silhouette minimum_silhouette dunn_index
#> 1          12          2          0.3251621          0.1304348  0.6666667
#>   within_between_ratio singleton_clusters
#> 1            0.6299911                  0
case_representatives
#>   cluster rank sequence_id mean_within_distance
#> 1       1    1         s03            0.4074074
#> 2       2    1         s06            0.6666667
```

## Transition network and recent-context model

``` r

case_network <- create_transition_network(
  case_prepared$data,
  normalise = "from",
  include_self = TRUE
)

case_centrality <- summarise_transition_centrality(case_network)
case_communities <- detect_transition_communities(case_network)

case_order2 <- fit_higher_order_transition_model(
  case_prepared$data,
  order = 2L,
  smoothing = 0.5,
  backoff = TRUE
)

case_network
#>    group_key      context   from_state     to_state count sequence_count
#> 1    __all__         cart         cart     checkout     8              8
#> 2    __all__         cart         cart         home     1              1
#> 3    __all__     category     category      compare     1              1
#> 4    __all__     category     category      product     5              5
#> 5    __all__     category     category       search     1              1
#> 6    __all__     checkout     checkout confirmation     4              4
#> 7    __all__     checkout     checkout         home     1              1
#> 8    __all__      compare      compare         cart     2              2
#> 9    __all__      compare      compare      product     2              2
#> 10   __all__ confirmation confirmation         home     1              1
#> 11   __all__         home         home     category     6              6
#> 12   __all__         home         home       search     7              6
#> 13   __all__      product      product         cart     5              5
#> 14   __all__      product      product     checkout     3              3
#> 15   __all__      product      product      compare     2              2
#> 16   __all__      product      product      reviews     2              2
#> 17   __all__      reviews      reviews         cart     2              2
#> 18   __all__       search       search     category     1              1
#> 19   __all__       search       search      compare     1              1
#> 20   __all__       search       search      product     5              5
#>    sequence_prevalence    weight
#> 1           0.66666667 0.8888889
#> 2           0.08333333 0.1111111
#> 3           0.08333333 0.1428571
#> 4           0.41666667 0.7142857
#> 5           0.08333333 0.1428571
#> 6           0.33333333 0.8000000
#> 7           0.08333333 0.2000000
#> 8           0.16666667 0.5000000
#> 9           0.16666667 0.5000000
#> 10          0.08333333 1.0000000
#> 11          0.50000000 0.4615385
#> 12          0.50000000 0.5384615
#> 13          0.41666667 0.4166667
#> 14          0.25000000 0.2500000
#> 15          0.16666667 0.1666667
#> 16          0.16666667 0.1666667
#> 17          0.16666667 1.0000000
#> 18          0.08333333 0.1428571
#> 19          0.08333333 0.1428571
#> 20          0.41666667 0.7142857
case_centrality
#>          state out_degree in_degree total_degree out_strength in_strength
#> 1         cart          2         3            5            1   1.9166667
#> 2     category          3         2            5            1   0.6043956
#> 3     checkout          2         2            4            1   1.1388889
#> 4      compare          2         3            5            1   0.4523810
#> 5 confirmation          1         1            2            1   0.8000000
#> 6         home          2         3            5            1   1.3111111
#> 7      product          4         3            7            1   1.9285714
#> 8      reviews          1         1            2            1   0.1666667
#> 9       search          3         2            5            1   0.6813187
#>   total_strength closeness betweenness   pagerank
#> 1       2.916667 0.1627828   13.833333 0.13158721
#> 2       1.604396 0.1782730   10.000000 0.08945518
#> 3       2.138889 0.1664850    9.166667 0.14945405
#> 4       1.452381 0.2017715    3.166667 0.06173321
#> 5       1.800000 0.1745409    0.000000 0.11829542
#> 6       2.311111 0.1744186   26.000000 0.15505264
#> 7       2.928571 0.1816167   18.833333 0.15701618
#> 8       1.166667 0.1797224    0.000000 0.03891063
#> 9       1.681319 0.1782730   10.000000 0.09849548
case_communities
#>          state community
#> 1         cart         1
#> 2     category         3
#> 3     checkout         2
#> 4      compare         3
#> 5 confirmation         2
#> 6         home         2
#> 7      product         3
#> 8      reviews         1
#> 9       search         3
predict_next_state(case_order2, c("home", "search"))
#>   order       context   next_state count probability used_order  used_context
#> 1     2 home > search      product     4  0.42857143          2 home > search
#> 2     2 home > search     category     1  0.14285714          2 home > search
#> 3     2 home > search      compare     1  0.14285714          2 home > search
#> 4     2 home > search         cart     0  0.04761905          2 home > search
#> 5     2 home > search     checkout     0  0.04761905          2 home > search
#> 6     2 home > search confirmation     0  0.04761905          2 home > search
#> 7     2 home > search         home     0  0.04761905          2 home > search
#> 8     2 home > search      reviews     0  0.04761905          2 home > search
#> 9     2 home > search       search     0  0.04761905          2 home > search
predict_next_state(case_order2, c("unseen"))
#>   order  context   next_state count probability used_order used_context
#> 1     0 <unseen>         cart     0   0.1111111          0     <unseen>
#> 2     0 <unseen>     category     0   0.1111111          0     <unseen>
#> 3     0 <unseen>     checkout     0   0.1111111          0     <unseen>
#> 4     0 <unseen>      compare     0   0.1111111          0     <unseen>
#> 5     0 <unseen> confirmation     0   0.1111111          0     <unseen>
#> 6     0 <unseen>         home     0   0.1111111          0     <unseen>
#> 7     0 <unseen>      product     0   0.1111111          0     <unseen>
#> 8     0 <unseen>      reviews     0   0.1111111          0     <unseen>
#> 9     0 <unseen>       search     0   0.1111111          0     <unseen>
```

## Compact categorical HMM sensitivity description

The native HMM is included as a compact statistical summary, not as a
source of substantive state labels. A one-state and two-state model are
compared descriptively using the same observations and symbol coding.

``` r

one_state <- fit_sequence_hmm(
  case_prepared$data,
  n_states = 1L,
  max_iter = 30L,
  seed = 42L
)

two_state <- fit_sequence_hmm(
  case_prepared$data,
  n_states = 2L,
  max_iter = 50L,
  seed = 42L
)

summarise_sequence_hmm(two_state)$fit
#>   log_likelihood      aic      bic n_parameters n_observations iterations
#> 1      -122.9066 283.8132 327.0699           19             72         47
#>   converged
#> 1      TRUE
head(decode_sequence_states(two_state, method = "viterbi"))
#>   sequence_id sequence_order observed_state component latent_state
#> 1         s01              1           home         1     latent_1
#> 2         s01              2         search         1     latent_2
#> 3         s01              3        product         1     latent_2
#> 4         s01              4           cart         1     latent_2
#> 5         s01              5       checkout         1     latent_2
#> 6         s01              6   confirmation         1     latent_2
#>   posterior_probability decoding_method
#> 1             1.0000000         viterbi
#> 2             1.0000000         viterbi
#> 3             1.0000000         viterbi
#> 4             1.0000000         viterbi
#> 5             1.0000000         viterbi
#> 6             0.9999999         viterbi
compare_sequence_hmms(one_state = one_state, two_state = two_state)
#>       model            class log_likelihood      aic      bic n_parameters
#> 2 two_state gp3_sequence_hmm      -122.9066 283.8132 327.0699           19
#> 1 one_state gp3_sequence_hmm      -148.5949 313.1898 331.4031            8
#>   n_observations converged delta_aic delta_bic
#> 2             72      TRUE   0.00000  0.000000
#> 1             72      TRUE  29.37656  4.333237
```

## Assemble report-ready evidence

``` r

case_evidence <- list(
  preparation_status = case_prepared$status,
  preparation_decisions = case_prepared$decisions,
  state_summary = state_summary$overall,
  motif_summary = case_motif_filter$motifs,
  consensus = format_consensus_sequence(
    case_consensus,
    include_agreement = TRUE
  ),
  group_state_contrasts = case_comparison$state_contrasts,
  distance_summary = summarise_sequence_distance(case_distance)$overall,
  cluster_validation = case_cluster_validation$overall,
  representatives = case_representatives,
  network = case_network,
  centrality = case_centrality,
  hmm_comparison = compare_sequence_hmms(
    one_state = one_state,
    two_state = two_state
  )
)

names(case_evidence)
#>  [1] "preparation_status"    "preparation_decisions" "state_summary"        
#>  [4] "motif_summary"         "consensus"             "group_state_contrasts"
#>  [7] "distance_summary"      "cluster_validation"    "representatives"      
#> [10] "network"               "centrality"            "hmm_comparison"
```

## Interpretation boundary

The workflow documents recurring paths, aligned-position support,
descriptive condition contrasts, dissimilarity, clustering
reproducibility, transition structure, recent-context probabilities, and
latent statistical summaries. None of these outputs independently
identifies attention, preference, comprehension, emotion, cognition,
intention, diagnosis, deception, or causal mechanisms. Such
interpretation requires an appropriate design, external measurement, and
independent validation.
