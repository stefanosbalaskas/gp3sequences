# Extract bounded non-contiguous sequence subsequences

Enumerates ordered non-contiguous subsequences under explicit length,
gap, span, and safety limits. The implementation is transparent and
intended for modest sequence collections; specialist mining packages
remain preferable for very large search spaces.

## Usage

``` r
extract_sequence_subsequences(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = NULL,
  min_length = 2L,
  max_length = 5L,
  max_gap = Inf,
  max_span = Inf,
  repeated_state_policy = c("preserve", "collapse"),
  separator = " > ",
  max_combinations_per_sequence = 100000L
)
```

## Arguments

- data:

  Long-format sequence data or a prepared result.

- sequence_id_col, order_col, state_col:

  Core sequence columns.

- metadata_cols:

  Optional sequence-constant metadata retained as attributes.

- min_length, max_length:

  Minimum and maximum subsequence lengths.

- max_gap:

  Maximum number of skipped positions between adjacent selected states.
  Use `Inf` for no restriction.

- max_span:

  Maximum difference between the first and last selected sequence
  positions. Use `Inf` for no restriction.

- repeated_state_policy:

  Preserve or collapse consecutive repeated states before mining.

- separator:

  Separator used in stable motif labels.

- max_combinations_per_sequence:

  Safety limit for the number of index combinations considered for any
  one sequence.

## Value

A data frame of class `gp3_sequence_subsequences`, with one row per
qualifying occurrence.

## Examples

``` r
sequences <- data.frame(
  sequence_id = rep(c("s1", "s2"), each = 5L),
  sequence_order = rep(1:5, times = 2L),
  state = c("A", "B", "C", "D", "E", "A", "C", "B", "D", "E")
)
extract_sequence_subsequences(sequences, min_length = 2L, max_length = 3L,
                              max_gap = 2L)
#>    sequence_id subsequence subsequence_length start_order end_order span
#> 1           s1       A > B                  2           1         2    1
#> 2           s2       A > B                  2           1         3    2
#> 3           s1       A > C                  2           1         3    2
#> 4           s2       A > C                  2           1         2    1
#> 5           s1       A > D                  2           1         4    3
#> 6           s2       A > D                  2           1         4    3
#> 7           s1       B > C                  2           2         3    1
#> 8           s1       B > D                  2           2         4    2
#> 9           s2       B > D                  2           3         4    1
#> 10          s1       B > E                  2           2         5    3
#> 11          s2       B > E                  2           3         5    2
#> 12          s2       C > B                  2           2         3    1
#> 13          s1       C > D                  2           3         4    1
#> 14          s2       C > D                  2           2         4    2
#> 15          s1       C > E                  2           3         5    2
#> 16          s2       C > E                  2           2         5    3
#> 17          s1       D > E                  2           4         5    1
#> 18          s2       D > E                  2           4         5    1
#> 19          s1   A > B > C                  3           1         3    2
#> 20          s1   A > B > D                  3           1         4    3
#> 21          s2   A > B > D                  3           1         4    3
#> 22          s1   A > B > E                  3           1         5    4
#> 23          s2   A > B > E                  3           1         5    4
#> 24          s2   A > C > B                  3           1         3    2
#> 25          s1   A > C > D                  3           1         4    3
#> 26          s2   A > C > D                  3           1         4    3
#> 27          s1   A > C > E                  3           1         5    4
#> 28          s2   A > C > E                  3           1         5    4
#> 29          s1   A > D > E                  3           1         5    4
#> 30          s2   A > D > E                  3           1         5    4
#> 31          s1   B > C > D                  3           2         4    2
#> 32          s1   B > C > E                  3           2         5    3
#> 33          s1   B > D > E                  3           2         5    3
#> 34          s2   B > D > E                  3           3         5    2
#> 35          s2   C > B > D                  3           2         4    2
#> 36          s2   C > B > E                  3           2         5    3
#> 37          s1   C > D > E                  3           3         5    2
#> 38          s2   C > D > E                  3           2         5    3
#>    max_observed_gap selected_positions selected_orders
#> 1                 0                1,2             1,2
#> 2                 1                1,3             1,3
#> 3                 1                1,3             1,3
#> 4                 0                1,2             1,2
#> 5                 2                1,4             1,4
#> 6                 2                1,4             1,4
#> 7                 0                2,3             2,3
#> 8                 1                2,4             2,4
#> 9                 0                3,4             3,4
#> 10                2                2,5             2,5
#> 11                1                3,5             3,5
#> 12                0                2,3             2,3
#> 13                0                3,4             3,4
#> 14                1                2,4             2,4
#> 15                1                3,5             3,5
#> 16                2                2,5             2,5
#> 17                0                4,5             4,5
#> 18                0                4,5             4,5
#> 19                0              1,2,3           1,2,3
#> 20                1              1,2,4           1,2,4
#> 21                1              1,3,4           1,3,4
#> 22                2              1,2,5           1,2,5
#> 23                1              1,3,5           1,3,5
#> 24                0              1,2,3           1,2,3
#> 25                1              1,3,4           1,3,4
#> 26                1              1,2,4           1,2,4
#> 27                1              1,3,5           1,3,5
#> 28                2              1,2,5           1,2,5
#> 29                2              1,4,5           1,4,5
#> 30                2              1,4,5           1,4,5
#> 31                0              2,3,4           2,3,4
#> 32                1              2,3,5           2,3,5
#> 33                1              2,4,5           2,4,5
#> 34                0              3,4,5           3,4,5
#> 35                0              2,3,4           2,3,4
#> 36                1              2,3,5           2,3,5
#> 37                0              3,4,5           3,4,5
#> 38                1              2,4,5           2,4,5
```
