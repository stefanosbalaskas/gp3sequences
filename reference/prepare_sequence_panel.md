# Prepare longitudinal or panel sequence data

Validates a collection of sequences observed repeatedly for the same
panel units and creates an auditable panel index. Each sequence must map
to exactly one panel unit and one occasion.

## Usage

``` r
prepare_sequence_panel(
  data,
  panel_id_col,
  occasion_col,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = NULL,
  require_unique_occasions = TRUE
)
```

## Arguments

- data:

  Long-format sequence data or a prepared gp3sequences result.

- panel_id_col:

  Column identifying the repeatedly observed unit.

- occasion_col:

  Column identifying the wave, visit, or occasion.

- sequence_id_col, order_col, state_col:

  Core sequence columns.

- metadata_cols:

  Optional columns that must remain constant within each sequence.

- require_unique_occasions:

  Require at most one sequence per panel unit and occasion.

## Value

An object of class `gp3_sequence_panel` containing canonical data, a
panel index, state levels, and mapping information.

## Examples

``` r
panel <- data.frame(
  participant_id = rep(c("p1", "p2"), each = 8L),
  occasion = rep(rep(c(1, 2), each = 4L), times = 2L),
  sequence_id = rep(c("p1_w1", "p1_w2", "p2_w1", "p2_w2"), each = 4L),
  sequence_order = rep(1:4, times = 4L),
  state = c("A", "B", "C", "D", "A", "C", "C", "D",
            "D", "C", "B", "A", "D", "B", "B", "A")
)
prepare_sequence_panel(panel, "participant_id", "occasion")
#> $data
#>    participant_id occasion sequence_id sequence_order state
#> 1              p1        1       p1_w1              1     A
#> 2              p1        1       p1_w1              2     B
#> 3              p1        1       p1_w1              3     C
#> 4              p1        1       p1_w1              4     D
#> 5              p1        2       p1_w2              1     A
#> 6              p1        2       p1_w2              2     C
#> 7              p1        2       p1_w2              3     C
#> 8              p1        2       p1_w2              4     D
#> 9              p2        1       p2_w1              1     D
#> 10             p2        1       p2_w1              2     C
#> 11             p2        1       p2_w1              3     B
#> 12             p2        1       p2_w1              4     A
#> 13             p2        2       p2_w2              1     D
#> 14             p2        2       p2_w2              2     B
#> 15             p2        2       p2_w2              3     B
#> 16             p2        2       p2_w2              4     A
#>    .gp3_adv_original_row
#> 1                      1
#> 2                      2
#> 3                      3
#> 4                      4
#> 5                      5
#> 6                      6
#> 7                      7
#> 8                      8
#> 9                      9
#> 10                    10
#> 11                    11
#> 12                    12
#> 13                    13
#> 14                    14
#> 15                    15
#> 16                    16
#> 
#> $index
#>   sequence_id panel_id occasion occasion_rank sequence_length transition_count
#> 1       p1_w1       p1        1             1               4                3
#> 2       p1_w2       p1        2             2               4                3
#> 3       p2_w1       p2        1             1               4                3
#> 4       p2_w2       p2        2             2               4                3
#> 
#> $sequences
#> $sequences$p1_w1
#> [1] "A" "B" "C" "D"
#> 
#> $sequences$p1_w2
#> [1] "A" "C" "C" "D"
#> 
#> $sequences$p2_w1
#> [1] "D" "C" "B" "A"
#> 
#> $sequences$p2_w2
#> [1] "D" "B" "B" "A"
#> 
#> 
#> $orders
#> $orders$p1_w1
#> [1] 1 2 3 4
#> 
#> $orders$p1_w2
#> [1] 1 2 3 4
#> 
#> $orders$p2_w1
#> [1] 1 2 3 4
#> 
#> $orders$p2_w2
#> [1] 1 2 3 4
#> 
#> 
#> $state_levels
#> [1] "A" "B" "C" "D"
#> 
#> $columns
#> $columns$panel_id
#> [1] "participant_id"
#> 
#> $columns$occasion
#> [1] "occasion"
#> 
#> $columns$sequence_id
#> [1] "sequence_id"
#> 
#> $columns$order
#> [1] "sequence_order"
#> 
#> $columns$state
#> [1] "state"
#> 
#> $columns$metadata
#> [1] "participant_id" "occasion"      
#> 
#> 
#> $settings
#> $settings$require_unique_occasions
#> [1] TRUE
#> 
#> 
#> $call
#> prepare_sequence_panel(data = panel, panel_id_col = "participant_id", 
#>     occasion_col = "occasion")
#> 
#> attr(,"class")
#> [1] "gp3_sequence_panel" "list"              
```
