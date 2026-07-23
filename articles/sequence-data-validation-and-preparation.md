# Sequence Data Validation and Preparation

## Why preparation is explicit

Ordered categorical data can contain missing states, duplicated
positions, unsorted rows, consecutive repeats, zero durations, unknown
states, and inconsistent metadata. Silent repair can change the
analytical object. `gp3sequences` therefore separates non-modifying
audit and validation from policy-driven preparation.

## A deliberately problematic synthetic input

The example includes an unsorted sequence, a duplicated position, a
missing state, a consecutive repeat, a zero duration, an unexpected
state, and an unused factor level. Participant and group metadata remain
constant within each sequence.

``` r

problem_data <- data.frame(
  sequence_id = c("s2", "s1", "s1", "s1", "s1", "s2", "s2", "s2", "s2"),
  sequence_order = c(2, 2, 1, 2, 3, 1, 2, 3, 4),
  state = factor(
    c("search", "search", "home", "search", NA,
      "home", "home", "product", "other"),
    levels = c("home", "search", "product", "checkout", "other", "unused")
  ),
  duration = c(120, 100, 90, 110, 80, 100, 0, 150, 130),
  participant_id = c("p2", "p1", "p1", "p1", "p1", "p2", "p2", "p2", "p2"),
  group = c("interface_b", "interface_a", "interface_a", "interface_a",
            "interface_a", "interface_b", "interface_b", "interface_b",
            "interface_b"),
  stringsAsFactors = FALSE
)

expected_states <- c("home", "search", "product", "checkout")
problem_data
#>   sequence_id sequence_order   state duration participant_id       group
#> 1          s2              2  search      120             p2 interface_b
#> 2          s1              2  search      100             p1 interface_a
#> 3          s1              1    home       90             p1 interface_a
#> 4          s1              2  search      110             p1 interface_a
#> 5          s1              3    <NA>       80             p1 interface_a
#> 6          s2              1    home      100             p2 interface_b
#> 7          s2              2    home        0             p2 interface_b
#> 8          s2              3 product      150             p2 interface_b
#> 9          s2              4   other      130             p2 interface_b
```

## Audit without modification

[`audit_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/audit_sequence_data.md)
reports one row per issue using stable issue codes and severity values.
It does not repair the data.

``` r

audit <- audit_sequence_data(
  problem_data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  duration_col = "duration",
  metadata_cols = c("participant_id", "group"),
  expected_states = expected_states
)

audit
#>    sequence_id row         column                 issue_code severity
#> 1           s1   2 sequence_order        duplicated_position    error
#> 2           s1   4 sequence_order        duplicated_position    error
#> 3           s1   5          state              missing_state    error
#> 4           s2   1 sequence_order        duplicated_position    error
#> 5           s2   7 sequence_order        duplicated_position    error
#> 6           s1   2 sequence_order             unordered_rows   review
#> 7           s1   4          state consecutive_repeated_state   review
#> 8           s2   1 sequence_order             unordered_rows   review
#> 9           s2   7       duration              zero_duration   review
#> 10          s2   9          state              unknown_state   review
#> 11        <NA>  NA          state        unused_state_levels     info
#>                value                                              message
#> 1                  2         The sequence contains a duplicated position.
#> 2                  2         The sequence contains a duplicated position.
#> 3               <NA>                   The row has no usable state value.
#> 4                  2         The sequence contains a duplicated position.
#> 5                  2         The sequence contains a duplicated position.
#> 6      2 | 1 | 2 | 3            Rows are not ordered within the sequence.
#> 7             search The state repeats consecutively within the sequence.
#> 8  2 | 1 | 2 | 3 | 4            Rows are not ordered within the sequence.
#> 9                  0                          The duration value is zero.
#> 10             other          The state is absent from `expected_states`.
#> 11 checkout | unused             The factor contains unused state levels.
#>                                                          action
#> 1  Correct the position or apply an explicit first/last policy.
#> 2  Correct the position or apply an explicit first/last policy.
#> 3     Supply a state or apply an explicit missing-state policy.
#> 4  Correct the position or apply an explicit first/last policy.
#> 5  Correct the position or apply an explicit first/last policy.
#> 6                 Sort deterministically by sequence and order.
#> 7      Preserve or collapse repeats through an explicit policy.
#> 8                 Sort deterministically by sequence and order.
#> 9           Preserve, drop, or reject zero duration explicitly.
#> 10         Preserve, drop, or reject unknown states explicitly.
#> 11                   Preserve or drop unused levels explicitly.
as.data.frame(table(audit$severity), stringsAsFactors = FALSE)
#>     Var1 Freq
#> 1  error    5
#> 2   info    1
#> 3 review    5
as.data.frame(table(audit$issue_code), stringsAsFactors = FALSE)
#>                         Var1 Freq
#> 1 consecutive_repeated_state    1
#> 2        duplicated_position    4
#> 3              missing_state    1
#> 4              unknown_state    1
#> 5             unordered_rows    2
#> 6        unused_state_levels    1
#> 7              zero_duration    1
```

## Compact validation contract

A review-level issue does not automatically invalidate an input.
Error-level issues must be resolved through source correction or an
explicit supported policy.

``` r

validation <- validate_sequence_data(
  problem_data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  duration_col = "duration",
  metadata_cols = c("participant_id", "group"),
  expected_states = expected_states
)

validation[c("valid", "status", "n_errors", "n_reviews", "n_info")]
#> $valid
#> [1] FALSE
#> 
#> $status
#> [1] "fail"
#> 
#> $n_errors
#> [1] 5
#> 
#> $n_reviews
#> [1] 5
#> 
#> $n_info
#> [1] 1
validation$mapping
#>                      role  source_column
#> 1             sequence_id    sequence_id
#> 2          sequence_order sequence_order
#> 3                   state          state
#> 4                duration       duration
#> 5 metadata:participant_id participant_id
#> 6          metadata:group          group
```

## Apply explicit preparation policies

This example deliberately chooses to:

- drop rows with missing states;
- retain the first row at duplicated positions;
- collapse consecutive repeated states;
- drop zero-duration rows;
- drop states absent from the declared state set;
- drop unused factor levels.

These are analytical choices, not universal defaults.

``` r

prepared <- prepare_sequence_data(
  problem_data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  duration_col = "duration",
  metadata_cols = c("participant_id", "group"),
  expected_states = expected_states,
  missing_state_policy = "drop",
  duplicate_position_policy = "first",
  repeated_state_policy = "collapse",
  zero_duration_policy = "drop",
  unknown_state_policy = "drop",
  unused_state_levels = "drop"
)

prepared$status
#> [1] "pass"
prepared$decisions
#>                   step             policy affected_rows
#> 1       missing_states               drop             1
#> 2       unknown_states               drop             1
#> 3       zero_durations               drop             1
#> 4 duplicated_positions              first             1
#> 5            row_order deterministic_sort             3
#> 6  consecutive_repeats           collapse             0
#> 7  unused_state_levels               drop             3
#> 8       column_mapping       canonicalise             5
#>                                                                              details
#> 1                                    Rows with missing or blank states were removed.
#> 2                                 States absent from `expected_states` were removed.
#> 3                                              Rows with zero duration were removed.
#> 4              Duplicated positions were resolved by retaining the first occurrence.
#> 5        Rows were ordered by sequence identifier, sequence order, and original row.
#> 6 The first row was retained for each repeated run; available durations were summed.
#> 7                                                 Unused factor levels were removed.
#> 8            Mapped columns were standardised while unmapped columns were preserved.
prepared$data
#>   sequence_id sequence_order   state original_row duration participant_id
#> 1          s1              1    home            3       90             p1
#> 2          s1              2  search            2      100             p1
#> 3          s2              1    home            6      100             p2
#> 4          s2              2  search            1      120             p2
#> 5          s2              3 product            8      150             p2
#>         group
#> 1 interface_a
#> 2 interface_a
#> 3 interface_b
#> 4 interface_b
#> 5 interface_b
prepared$audit
#>    stage sequence_id row         column                 issue_code severity
#> 1  input          s1   2 sequence_order        duplicated_position    error
#> 2  input          s1   4 sequence_order        duplicated_position    error
#> 3  input          s1   5          state              missing_state    error
#> 4  input          s2   1 sequence_order        duplicated_position    error
#> 5  input          s2   7 sequence_order        duplicated_position    error
#> 6  input          s1   2 sequence_order             unordered_rows   review
#> 7  input          s1   4          state consecutive_repeated_state   review
#> 8  input          s2   1 sequence_order             unordered_rows   review
#> 9  input          s2   7       duration              zero_duration   review
#> 10 input          s2   9          state              unknown_state   review
#> 11 input        <NA>  NA          state        unused_state_levels     info
#>                value                                              message
#> 1                  2         The sequence contains a duplicated position.
#> 2                  2         The sequence contains a duplicated position.
#> 3               <NA>                   The row has no usable state value.
#> 4                  2         The sequence contains a duplicated position.
#> 5                  2         The sequence contains a duplicated position.
#> 6      2 | 1 | 2 | 3            Rows are not ordered within the sequence.
#> 7             search The state repeats consecutively within the sequence.
#> 8  2 | 1 | 2 | 3 | 4            Rows are not ordered within the sequence.
#> 9                  0                          The duration value is zero.
#> 10             other          The state is absent from `expected_states`.
#> 11 checkout | unused             The factor contains unused state levels.
#>                                                          action
#> 1  Correct the position or apply an explicit first/last policy.
#> 2  Correct the position or apply an explicit first/last policy.
#> 3     Supply a state or apply an explicit missing-state policy.
#> 4  Correct the position or apply an explicit first/last policy.
#> 5  Correct the position or apply an explicit first/last policy.
#> 6                 Sort deterministically by sequence and order.
#> 7      Preserve or collapse repeats through an explicit policy.
#> 8                 Sort deterministically by sequence and order.
#> 9           Preserve, drop, or reject zero duration explicitly.
#> 10         Preserve, drop, or reject unknown states explicitly.
#> 11                   Preserve or drop unused levels explicitly.
```

## Revalidate the canonical result

The prepared table uses stable canonical columns while preserving
unmapped metadata and original-row provenance.

``` r

revalidation <- validate_sequence_data(
  prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  duration_col = "duration",
  metadata_cols = c("participant_id", "group"),
  expected_states = expected_states
)

revalidation[c("valid", "status", "n_errors", "n_reviews", "n_info")]
#> $valid
#> [1] TRUE
#> 
#> $status
#> [1] "pass"
#> 
#> $n_errors
#> [1] 0
#> 
#> $n_reviews
#> [1] 0
#> 
#> $n_info
#> [1] 0
prepared$mapping
#>                      role  source_column
#> 1             sequence_id    sequence_id
#> 2          sequence_order sequence_order
#> 3                   state          state
#> 4                duration       duration
#> 5 metadata:participant_id participant_id
#> 6          metadata:group          group
prepared$state_levels
#> [1] "home"    "search"  "product"
```

## Errors that require source correction

Some conditions are intentionally not repaired automatically. Examples
include missing sequence identifiers, missing or non-finite order
values, negative or non-finite durations, absent mapped columns,
duplicated column names, invalid column types, and metadata that varies
within a sequence. These conditions require correction or an explicit
redefinition of the sequence unit.

## Reporting recommendations

A reproducible report should record the input mapping, expected states,
every preparation policy, the audit table, the decision log, original
and prepared row counts, and the final state levels. These records
describe data handling; they do not validate a substantive
interpretation of the resulting sequence patterns.
