# Compare subsequence prevalence between groups

Performs transparent contingency-table tests on sequence-level presence.
Multiple testing is adjusted explicitly. Results are associational
unless a randomized design independently justifies causal
interpretation.

## Usage

``` r
compare_sequence_subsequences(
  occurrences,
  group_col,
  test = c("auto", "chisq", "fisher"),
  p_adjust = "BH",
  min_sequence_count = 1L
)
```

## Arguments

- occurrences:

  A non-contiguous subsequence occurrence table.

- group_col:

  Sequence-constant group column retained through `metadata_cols` during
  extraction.

- test:

  `"auto"`, `"chisq"`, or `"fisher"`.

- p_adjust:

  Multiple-testing adjustment method.

- min_sequence_count:

  Minimum total sequence count per subsequence.

## Value

A data frame of prevalence contrasts and adjusted p-values.

## Examples

``` r
data <- data.frame(
  sequence_id = rep(paste0("s", 1:4), each = 4L),
  sequence_order = rep(1:4, 4L),
  state = c("A", "B", "C", "D", "A", "B", "D", "D",
            "D", "C", "B", "A", "D", "C", "A", "A"),
  group = rep(c("g1", "g2"), each = 8L)
)
occurrences <- extract_sequence_subsequences(data, metadata_cols = "group")
compare_sequence_subsequences(occurrences, "group")
#>      subsequence subsequence_length   test statistic df   p_value
#> 1          A > B                  2 fisher        NA NA 0.3333333
#> 2      A > B > D                  3 fisher        NA NA 0.3333333
#> 3          A > D                  2 fisher        NA NA 0.3333333
#> 4          B > D                  2 fisher        NA NA 0.3333333
#> 5          C > A                  2 fisher        NA NA 0.3333333
#> 6          D > A                  2 fisher        NA NA 0.3333333
#> 7          D > C                  2 fisher        NA NA 0.3333333
#> 8      D > C > A                  3 fisher        NA NA 0.3333333
#> 9          A > A                  2 fisher        NA NA 1.0000000
#> 10     A > B > C                  3 fisher        NA NA 1.0000000
#> 11 A > B > C > D                  4 fisher        NA NA 1.0000000
#> 12 A > B > D > D                  4 fisher        NA NA 1.0000000
#> 13         A > C                  2 fisher        NA NA 1.0000000
#> 14     A > C > D                  3 fisher        NA NA 1.0000000
#> 15     A > D > D                  3 fisher        NA NA 1.0000000
#> 16         B > A                  2 fisher        NA NA 1.0000000
#> 17         B > C                  2 fisher        NA NA 1.0000000
#> 18     B > C > D                  3 fisher        NA NA 1.0000000
#> 19     B > D > D                  3 fisher        NA NA 1.0000000
#> 20     C > A > A                  3 fisher        NA NA 1.0000000
#> 21         C > B                  2 fisher        NA NA 1.0000000
#> 22     C > B > A                  3 fisher        NA NA 1.0000000
#> 23         C > D                  2 fisher        NA NA 1.0000000
#> 24     D > A > A                  3 fisher        NA NA 1.0000000
#> 25         D > B                  2 fisher        NA NA 1.0000000
#> 26     D > B > A                  3 fisher        NA NA 1.0000000
#> 27 D > C > A > A                  4 fisher        NA NA 1.0000000
#> 28     D > C > B                  3 fisher        NA NA 1.0000000
#> 29 D > C > B > A                  4 fisher        NA NA 1.0000000
#> 30         D > D                  2 fisher        NA NA 1.0000000
#>    max_prevalence min_prevalence prevalence_range prevalence_g1 n_g1
#> 1             1.0              0              1.0           1.0    2
#> 2             1.0              0              1.0           1.0    2
#> 3             1.0              0              1.0           1.0    2
#> 4             1.0              0              1.0           1.0    2
#> 5             1.0              0              1.0           0.0    2
#> 6             1.0              0              1.0           0.0    2
#> 7             1.0              0              1.0           0.0    2
#> 8             1.0              0              1.0           0.0    2
#> 9             0.5              0              0.5           0.0    2
#> 10            0.5              0              0.5           0.5    2
#> 11            0.5              0              0.5           0.5    2
#> 12            0.5              0              0.5           0.5    2
#> 13            0.5              0              0.5           0.5    2
#> 14            0.5              0              0.5           0.5    2
#> 15            0.5              0              0.5           0.5    2
#> 16            0.5              0              0.5           0.0    2
#> 17            0.5              0              0.5           0.5    2
#> 18            0.5              0              0.5           0.5    2
#> 19            0.5              0              0.5           0.5    2
#> 20            0.5              0              0.5           0.0    2
#> 21            0.5              0              0.5           0.0    2
#> 22            0.5              0              0.5           0.0    2
#> 23            0.5              0              0.5           0.5    2
#> 24            0.5              0              0.5           0.0    2
#> 25            0.5              0              0.5           0.0    2
#> 26            0.5              0              0.5           0.0    2
#> 27            0.5              0              0.5           0.0    2
#> 28            0.5              0              0.5           0.0    2
#> 29            0.5              0              0.5           0.0    2
#> 30            0.5              0              0.5           0.5    2
#>    prevalence_g2 n_g2 prevalence_difference p_adjusted
#> 1            0.0    2                  -1.0          1
#> 2            0.0    2                  -1.0          1
#> 3            0.0    2                  -1.0          1
#> 4            0.0    2                  -1.0          1
#> 5            1.0    2                   1.0          1
#> 6            1.0    2                   1.0          1
#> 7            1.0    2                   1.0          1
#> 8            1.0    2                   1.0          1
#> 9            0.5    2                   0.5          1
#> 10           0.0    2                  -0.5          1
#> 11           0.0    2                  -0.5          1
#> 12           0.0    2                  -0.5          1
#> 13           0.0    2                  -0.5          1
#> 14           0.0    2                  -0.5          1
#> 15           0.0    2                  -0.5          1
#> 16           0.5    2                   0.5          1
#> 17           0.0    2                  -0.5          1
#> 18           0.0    2                  -0.5          1
#> 19           0.0    2                  -0.5          1
#> 20           0.5    2                   0.5          1
#> 21           0.5    2                   0.5          1
#> 22           0.5    2                   0.5          1
#> 23           0.0    2                  -0.5          1
#> 24           0.5    2                   0.5          1
#> 25           0.5    2                   0.5          1
#> 26           0.5    2                   0.5          1
#> 27           0.5    2                   0.5          1
#> 28           0.5    2                   0.5          1
#> 29           0.5    2                   0.5          1
#> 30           0.0    2                  -0.5          1
```
