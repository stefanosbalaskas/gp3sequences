# Fit a higher-order transition model

Fit a higher-order transition model

## Usage

``` r
fit_higher_order_transition_model(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  order = 2L,
  smoothing = 0.5,
  backoff = TRUE,
  context_separator = " > "
)
```

## Arguments

- data:

  Long-format sequence data.

- sequence_id_col, order_col, state_col:

  Sequence columns.

- order:

  Context order.

- smoothing:

  Additive smoothing over observed next states.

- backoff:

  Retain lower-order context tables for prediction backoff.

- context_separator:

  Context separator.

## Value

An object of class `gp3_higher_order_transition_model`.

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
fit_higher_order_transition_model(sequences, order = 2L)
#> $order
#> [1] 2
#> 
#> $tables
#> $tables$order_1
#>    order context next_state count probability
#> 1      1       A          A     1       0.300
#> 2      1       A          B     2       0.500
#> 3      1       A          C     0       0.100
#> 4      1       A          D     0       0.100
#> 5      1       B          A     1       0.300
#> 6      1       B          B     0       0.100
#> 7      1       B          C     2       0.500
#> 8      1       B          D     0       0.100
#> 9      1       C          A     1       0.250
#> 10     1       C          B     1       0.250
#> 11     1       C          C     1       0.250
#> 12     1       C          D     1       0.250
#> 13     1       D          A     0       0.125
#> 14     1       D          B     0       0.125
#> 15     1       D          C     2       0.625
#> 16     1       D          D     0       0.125
#> 
#> $tables$order_2
#>    order context next_state count probability
#> 1      2   A > B          A     0   0.1250000
#> 2      2   A > B          B     0   0.1250000
#> 3      2   A > B          C     2   0.6250000
#> 4      2   A > B          D     0   0.1250000
#> 5      2   B > C          A     0   0.1250000
#> 6      2   B > C          B     0   0.1250000
#> 7      2   B > C          C     1   0.3750000
#> 8      2   B > C          D     1   0.3750000
#> 9      2   C > A          A     1   0.5000000
#> 10     2   C > A          B     0   0.1666667
#> 11     2   C > A          C     0   0.1666667
#> 12     2   C > A          D     0   0.1666667
#> 13     2   C > B          A     1   0.5000000
#> 14     2   C > B          B     0   0.1666667
#> 15     2   C > B          C     0   0.1666667
#> 16     2   C > B          D     0   0.1666667
#> 17     2   D > C          A     1   0.3750000
#> 18     2   D > C          B     1   0.3750000
#> 19     2   D > C          C     0   0.1250000
#> 20     2   D > C          D     0   0.1250000
#> 
#> 
#> $state_levels
#> [1] "A" "B" "C" "D"
#> 
#> $smoothing
#> [1] 0.5
#> 
#> $backoff
#> [1] TRUE
#> 
#> $context_separator
#> [1] " > "
#> 
#> attr(,"class")
#> [1] "gp3_higher_order_transition_model" "list"                             
```
