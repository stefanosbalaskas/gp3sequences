# Filter non-contiguous subsequence summaries

Filter non-contiguous subsequence summaries

## Usage

``` r
filter_sequence_subsequences(
  summary,
  min_sequences = 1L,
  min_prevalence = 0,
  max_mean_gap = Inf,
  top_n = NULL,
  ties = c("include", "exclude")
)
```

## Arguments

- summary:

  A data frame from
  [`summarise_sequence_subsequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_subsequences.md).

- min_sequences:

  Minimum sequence count.

- min_prevalence:

  Minimum sequence prevalence.

- max_mean_gap:

  Optional maximum mean gap.

- top_n:

  Optional number of rows retained after deterministic sorting.

- ties:

  Include or exclude ties at the `top_n` boundary.

## Value

A filtered summary data frame.

## Examples

``` r
data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
                   sequence_order = rep(1:4, 2L),
                   state = c("A", "B", "C", "D", "A", "C", "B", "D"))
x <- summarise_sequence_subsequences(extract_sequence_subsequences(data))
filter_sequence_subsequences(x, min_sequences = 2L)
#>   subsequence subsequence_length occurrence_count sequence_count
#> 1       A > B                  2                2              2
#> 2       A > C                  2                2              2
#> 3       A > D                  2                2              2
#> 4       B > D                  2                2              2
#> 5       C > D                  2                2              2
#> 6   A > B > D                  3                2              2
#> 7   A > C > D                  3                2              2
#>   sequence_prevalence mean_span median_span mean_max_gap
#> 1                   1       1.5         1.5          0.5
#> 2                   1       1.5         1.5          0.5
#> 3                   1       3.0         3.0          2.0
#> 4                   1       1.5         1.5          0.5
#> 5                   1       1.5         1.5          0.5
#> 6                   1       3.0         3.0          1.0
#> 7                   1       3.0         3.0          1.0
```
