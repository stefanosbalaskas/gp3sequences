# Create an aligned-position consensus sequence

Computes a descriptive consensus state at each observed sequence
position. The function does not treat the consensus as a behavioural
norm and does not infer psychological or causal meaning.

## Usage

``` r
create_consensus_sequence(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  group_cols = NULL,
  weight_col = NULL,
  missing_state_policy = c("exclude", "state", "error"),
  missing_state_label = "<MISSING>",
  tie_method = c("first", "last", "missing", "all"),
  state_levels = NULL,
  min_support = 1L
)
```

## Arguments

- data:

  A long-format data frame, a prepared gp3sequences result, or a data
  frame containing canonical columns.

- sequence_id_col, order_col, state_col:

  Column names defining sequences.

- group_cols:

  Optional columns defining independent consensus groups.

- weight_col:

  Optional non-negative row-weight column.

- missing_state_policy:

  One of `"exclude"`, `"state"`, or `"error"`.

- missing_state_label:

  Label used when missing states are retained.

- tie_method:

  Deterministic tie policy: `"first"`, `"last"`, `"missing"`, or
  `"all"`.

- state_levels:

  Optional preferred state ordering used for ties.

- min_support:

  Minimum number of contributing sequences at a position.

## Value

A data frame of class `gp3_consensus_sequence` containing group columns,
sequence position, consensus state, support counts and weights,
agreement proportion, tie count, tied states, and total group sequences.

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
create_consensus_sequence(sequences, group_cols = "group")
#>   group sequence_order consensus_state support_n support_weight agreement tie_n
#> 1    g1              1               A         2              2       1.0     1
#> 2    g1              2               B         2              2       1.0     1
#> 3    g1              3               C         2              2       1.0     1
#> 4    g1              4               C         2              2       0.5     2
#> 5    g2              1               D         2              2       1.0     1
#> 6    g2              2               C         2              2       1.0     1
#> 7    g2              3               A         2              2       0.5     2
#> 8    g2              4               A         2              2       1.0     1
#>   tied_states n_sequences
#> 1           A           2
#> 2           B           2
#> 3           C           2
#> 4       C | D           2
#> 5           D           2
#> 6           C           2
#> 7       A | B           2
#> 8           A           2
```
