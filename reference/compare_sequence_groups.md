# Compare sequence groups descriptively

Produces descriptive state, transition and sequence-length comparisons.
No hypothesis tests or causal interpretations are produced.

## Usage

``` r
compare_sequence_groups(
  data,
  group_col,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  reference = NULL,
  metrics = c("state", "transition", "length"),
  include_self = TRUE,
  transition_separator = " -> ",
  zero_policy = c("missing", "infinite")
)
```

## Arguments

- data:

  Long-format sequence data.

- group_col:

  Grouping column that is constant within sequence.

- sequence_id_col, order_col, state_col:

  Sequence columns.

- reference:

  Optional reference group. When supplied, each other group is reported
  as `group_1` and the reference as `group_2`; differences and ratios
  are therefore other-minus-reference and other/reference. When omitted,
  all pairwise group contrasts are returned.

- metrics:

  Any of `"state"`, `"transition"`, and `"length"`.

- include_self:

  Include self-transitions.

- transition_separator:

  Separator used in reported transition labels. It must not occur inside
  an observed state label.

- zero_policy:

  Ratio policy when the reference value is zero.

## Value

A list of class `gp3_sequence_group_comparison` containing group
summaries and pairwise descriptive contrasts.

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
compare_sequence_groups(sequences, group_col = "group")
#> $groups
#>   group n_sequences
#> 1    g1           2
#> 2    g2           2
#> 
#> $state_summary
#>      group state event_count event_share sequence_count sequence_prevalence
#> g1.1    g1     A           2       0.250              2                 1.0
#> g1.2    g1     B           2       0.250              2                 1.0
#> g1.3    g1     C           3       0.375              2                 1.0
#> g1.4    g1     D           1       0.125              1                 0.5
#> g2.1    g2     A           3       0.375              2                 1.0
#> g2.2    g2     B           1       0.125              1                 0.5
#> g2.3    g2     C           2       0.250              2                 1.0
#> g2.4    g2     D           2       0.250              2                 1.0
#> 
#> $state_contrasts
#>   group_1 group_2 state event_share_group_1 event_share_group_2
#> 1      g1      g2     A               0.250               0.375
#> 2      g1      g2     B               0.250               0.125
#> 3      g1      g2     C               0.375               0.250
#> 4      g1      g2     D               0.125               0.250
#>   event_share_difference event_share_ratio sequence_prevalence_group_1
#> 1                 -0.125         0.6666667                         1.0
#> 2                  0.125         2.0000000                         1.0
#> 3                  0.125         1.5000000                         1.0
#> 4                 -0.125         0.5000000                         0.5
#>   sequence_prevalence_group_2 sequence_prevalence_difference
#> 1                         1.0                            0.0
#> 2                         0.5                            0.5
#> 3                         1.0                            0.0
#> 4                         1.0                           -0.5
#>   sequence_prevalence_ratio
#> 1                       1.0
#> 2                       2.0
#> 3                       1.0
#> 4                       0.5
#> 
#> $transition_summary
#>      group transition occurrence_count occurrence_share sequence_count
#> g1.1    g1     A -> B                2        0.3333333              2
#> g1.2    g1     B -> C                2        0.3333333              2
#> g1.3    g1     C -> C                1        0.1666667              1
#> g1.4    g1     C -> D                1        0.1666667              1
#> g2.1    g2     A -> A                1        0.1666667              1
#> g2.2    g2     B -> A                1        0.1666667              1
#> g2.3    g2     C -> A                1        0.1666667              1
#> g2.4    g2     C -> B                1        0.1666667              1
#> g2.5    g2     D -> C                2        0.3333333              2
#>      sequence_prevalence
#> g1.1                 1.0
#> g1.2                 1.0
#> g1.3                 0.5
#> g1.4                 0.5
#> g2.1                 0.5
#> g2.2                 0.5
#> g2.3                 0.5
#> g2.4                 0.5
#> g2.5                 1.0
#> 
#> $transition_contrasts
#>   group_1 group_2 transition occurrence_share_group_1 occurrence_share_group_2
#> 1      g1      g2     A -> B                0.3333333                0.0000000
#> 2      g1      g2     B -> C                0.3333333                0.0000000
#> 3      g1      g2     C -> C                0.1666667                0.0000000
#> 4      g1      g2     C -> D                0.1666667                0.0000000
#> 5      g1      g2     A -> A                0.0000000                0.1666667
#> 6      g1      g2     B -> A                0.0000000                0.1666667
#> 7      g1      g2     C -> A                0.0000000                0.1666667
#> 8      g1      g2     C -> B                0.0000000                0.1666667
#> 9      g1      g2     D -> C                0.0000000                0.3333333
#>   occurrence_share_difference occurrence_share_ratio
#> 1                   0.3333333                     NA
#> 2                   0.3333333                     NA
#> 3                   0.1666667                     NA
#> 4                   0.1666667                     NA
#> 5                  -0.1666667                      0
#> 6                  -0.1666667                      0
#> 7                  -0.1666667                      0
#> 8                  -0.1666667                      0
#> 9                  -0.3333333                      0
#>   sequence_prevalence_group_1 sequence_prevalence_group_2
#> 1                         1.0                         0.0
#> 2                         1.0                         0.0
#> 3                         0.5                         0.0
#> 4                         0.5                         0.0
#> 5                         0.0                         0.5
#> 6                         0.0                         0.5
#> 7                         0.0                         0.5
#> 8                         0.0                         0.5
#> 9                         0.0                         1.0
#>   sequence_prevalence_difference sequence_prevalence_ratio
#> 1                            1.0                        NA
#> 2                            1.0                        NA
#> 3                            0.5                        NA
#> 4                            0.5                        NA
#> 5                           -0.5                         0
#> 6                           -0.5                         0
#> 7                           -0.5                         0
#> 8                           -0.5                         0
#> 9                           -1.0                         0
#> 
#> $length_summary
#>    group n_sequences mean_length median_length min_length max_length sd_length
#> g1    g1           2           4             4          4          4         0
#> g2    g2           2           4             4          4          4         0
#> 
#> $length_contrasts
#>   group_1 group_2 mean_length_group_1 mean_length_group_2
#> 1      g1      g2                   4                   4
#>   mean_length_difference median_length_group_1 median_length_group_2
#> 1                      0                     4                     4
#>   median_length_difference
#> 1                        0
#> 
#> $settings
#> $settings$reference
#> NULL
#> 
#> $settings$metrics
#> [1] "state"      "transition" "length"    
#> 
#> $settings$include_self
#> [1] TRUE
#> 
#> $settings$transition_separator
#> [1] " -> "
#> 
#> $settings$zero_policy
#> [1] "missing"
#> 
#> 
#> attr(,"class")
#> [1] "gp3_sequence_group_comparison" "list"                         
```
