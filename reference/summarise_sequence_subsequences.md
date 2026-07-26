# Summarise non-contiguous subsequences

Summarise non-contiguous subsequences

## Usage

``` r
summarise_sequence_subsequences(occurrences)
```

## Arguments

- occurrences:

  A result from
  [`extract_sequence_subsequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/extract_sequence_subsequences.md).

## Value

A data frame with occurrence counts, sequence prevalence, and span
diagnostics.

## Examples

``` r
data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
                   sequence_order = rep(1:4, 2L),
                   state = c("A", "B", "C", "D", "A", "C", "B", "D"))
summarise_sequence_subsequences(extract_sequence_subsequences(data))
#>      subsequence subsequence_length occurrence_count sequence_count
#> 1          A > B                  2                2              2
#> 2          A > C                  2                2              2
#> 3          A > D                  2                2              2
#> 4          B > D                  2                2              2
#> 5          C > D                  2                2              2
#> 6      A > B > D                  3                2              2
#> 7      A > C > D                  3                2              2
#> 8          B > C                  2                1              1
#> 9          C > B                  2                1              1
#> 10     A > B > C                  3                1              1
#> 11     A > C > B                  3                1              1
#> 12     B > C > D                  3                1              1
#> 13     C > B > D                  3                1              1
#> 14 A > B > C > D                  4                1              1
#> 15 A > C > B > D                  4                1              1
#>    sequence_prevalence mean_span median_span mean_max_gap
#> 1                  1.0       1.5         1.5          0.5
#> 2                  1.0       1.5         1.5          0.5
#> 3                  1.0       3.0         3.0          2.0
#> 4                  1.0       1.5         1.5          0.5
#> 5                  1.0       1.5         1.5          0.5
#> 6                  1.0       3.0         3.0          1.0
#> 7                  1.0       3.0         3.0          1.0
#> 8                  0.5       1.0         1.0          0.0
#> 9                  0.5       1.0         1.0          0.0
#> 10                 0.5       2.0         2.0          0.0
#> 11                 0.5       2.0         2.0          0.0
#> 12                 0.5       2.0         2.0          0.0
#> 13                 0.5       2.0         2.0          0.0
#> 14                 0.5       3.0         3.0          0.0
#> 15                 0.5       3.0         3.0          0.0
```
