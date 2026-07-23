# Prepare common gp3tools-style sequence outputs

This optional compatibility helper recognises ordinary data frames or
lists containing a data-frame component and maps common sequence-column
names to the neutral gp3sequences contract. It does not require a
gp3tools class.

## Usage

``` r
prepare_gp3tools_sequences(
  data,
  sequence_id_col = NULL,
  order_col = NULL,
  state_col = NULL,
  duration_col = NULL,
  metadata_cols = NULL,
  ...
)
```

## Arguments

- data:

  A data frame or list with a data-frame `data` component.

- sequence_id_col, order_col, state_col:

  Optional explicit mappings.

- duration_col:

  Optional duration mapping.

- metadata_cols:

  Optional constant-within-sequence metadata columns.

- ...:

  Additional arguments passed to
  [`prepare_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/prepare_sequence_data.md).

## Value

A standard gp3sequences preparation result.

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
names(sequences)[names(sequences) == "sequence_order"] <- "position"
names(sequences)[names(sequences) == "state"] <- "aoi_label"
prepare_gp3tools_sequences(sequences)
#> $data
#>    sequence_id sequence_order state original_row group
#> 1           s1              1     A            1    g1
#> 2           s1              2     B            2    g1
#> 3           s1              3     C            3    g1
#> 4           s1              4     D            4    g1
#> 5           s2              1     A            5    g1
#> 6           s2              2     B            6    g1
#> 7           s2              3     C            7    g1
#> 8           s2              4     C            8    g1
#> 9           s3              1     D            9    g2
#> 10          s3              2     C           10    g2
#> 11          s3              3     B           11    g2
#> 12          s3              4     A           12    g2
#> 13          s4              1     D           13    g2
#> 14          s4              2     C           14    g2
#> 15          s4              3     A           15    g2
#> 16          s4              4     A           16    g2
#> 
#> $audit
#>    stage sequence_id row    column                 issue_code severity value
#> 1  input          s2   8 aoi_label consecutive_repeated_state   review     C
#> 2  input          s4  16 aoi_label consecutive_repeated_state   review     A
#> 3 output          s2   8     state consecutive_repeated_state   review     C
#> 4 output          s4  16     state consecutive_repeated_state   review     A
#>                                                message
#> 1 The state repeats consecutively within the sequence.
#> 2 The state repeats consecutively within the sequence.
#> 3 The state repeats consecutively within the sequence.
#> 4 The state repeats consecutively within the sequence.
#>                                                     action
#> 1 Preserve or collapse repeats through an explicit policy.
#> 2 Preserve or collapse repeats through an explicit policy.
#> 3 Preserve or collapse repeats through an explicit policy.
#> 4 Preserve or collapse repeats through an explicit policy.
#> 
#> $decisions
#>                   step             policy affected_rows
#> 1       missing_states              error             0
#> 2       unknown_states           preserve             0
#> 3       zero_durations           preserve             0
#> 4 duplicated_positions              error             0
#> 5            row_order deterministic_sort             0
#> 6  consecutive_repeats           preserve             0
#> 7  unused_state_levels           preserve             0
#> 8       column_mapping       canonicalise            16
#>                                                                       details
#> 1                          Missing states were retained as unresolved errors.
#> 2                                   Unknown states were preserved for review.
#> 3                                          Zero-duration rows were preserved.
#> 4                    Duplicated positions were retained as unresolved errors.
#> 5 Rows were ordered by sequence identifier, sequence order, and original row.
#> 6                                 Consecutive repeated states were preserved.
#> 7                                        Unused factor levels were preserved.
#> 8     Mapped columns were standardised while unmapped columns were preserved.
#> 
#> $mapping
#>             role source_column
#> 1    sequence_id   sequence_id
#> 2 sequence_order      position
#> 3          state     aoi_label
#> 
#> $status
#> [1] "review"
#> 
#> $original_n_rows
#> [1] 16
#> 
#> $prepared_n_rows
#> [1] 16
#> 
#> $state_levels
#> [1] "A" "B" "C" "D"
#> 
```
