# Create GrpString-compatible event and string inputs

Create GrpString-compatible event and string inputs

## Usage

``` r
as_grpstring_data(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  alphabet = NULL
)
```

## Arguments

- data:

  Long-format sequence data.

- sequence_id_col, order_col, state_col:

  Sequence columns.

- alphabet:

  Optional single-character symbols. When omitted, printable ASCII
  characters are assigned deterministically.

## Value

A list of class `gp3_grpstring_input` containing a wide event data
frame, event-name vector, character vector, conversion key, and string
vector.

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
as_grpstring_data(sequences)
#> $events
#>    position_1 position_2 position_3 position_4
#> s1          A          B          C          D
#> s2          A          B          C          C
#> s3          D          C          B          A
#> s4          D          C          A          A
#> 
#> $event_names
#> [1] "A" "B" "C" "D"
#> 
#> $characters
#> [1] "A" "B" "C" "D"
#> 
#> $key
#>   event_name character
#> 1          A         A
#> 2          B         B
#> 3          C         C
#> 4          D         D
#> 
#> $strings
#>     s1     s2     s3     s4 
#> "ABCD" "ABCC" "DCBA" "DCAA" 
#> 
#> $sequence_ids
#> [1] "s1" "s2" "s3" "s4"
#> 
#> attr(,"class")
#> [1] "gp3_grpstring_input" "list"               
```
