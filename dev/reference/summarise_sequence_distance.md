# Summarise a sequence-distance object

Summarise a sequence-distance object

## Usage

``` r
summarise_sequence_distance(distance)
```

## Arguments

- distance:

  A distance object returned by
  [`compute_sequence_distance()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/compute_sequence_distance.md).

## Value

A list containing an overall summary and per-sequence mean, median,
minimum, and maximum distances.

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
distance <- compute_sequence_distance(sequences)
summarise_sequence_distance(distance)
#> $overall
#>   n_sequences n_pairs mean_distance median_distance min_distance max_distance
#> 1           4       6             3               4            1            4
#> 
#> $per_sequence
#>   sequence_id mean_distance median_distance min_distance max_distance
#> 1          s1             3               4            1            4
#> 2          s2             3               4            1            4
#> 3          s3             3               4            1            4
#> 4          s4             3               4            1            4
#> 
#> $method
#> [1] "levenshtein"
#> 
#> $settings
#> $settings$indel_cost
#> [1] 1
#> 
#> $settings$substitution_cost
#> [1] 1
#> 
#> $settings$substitution_matrix
#> NULL
#> 
#> $settings$transition_smoothing
#> [1] 0
#> 
#> $settings$normalise
#> [1] "none"
#> 
#> 
```
