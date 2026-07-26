# Fit a time-varying sequence condition model

Fits a binary generalized additive model for either occupancy of a
target state or occurrence of a target transition over aligned sequence
time. Group specific smooths model time-varying condition differences,
and a participant random-effect smooth accounts for repeated
observations. The optional `mgcv` package is required.

## Usage

``` r
fit_time_varying_sequence_model(
  data,
  group_col,
  participant_id_col,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  time_col = NULL,
  outcome = c("state", "transition"),
  target_state = NULL,
  from_state = NULL,
  to_state = NULL,
  k = 5L,
  method = "REML",
  include_random_effect = TRUE
)
```

## Arguments

- data:

  Long-format sequence data or a prepared result.

- group_col:

  Group or condition column.

- participant_id_col:

  Participant or repeated-unit column.

- sequence_id_col, order_col, state_col:

  Core sequence columns.

- time_col:

  Optional numeric time column; defaults to `order_col`.

- outcome:

  `"state"` or `"transition"`.

- target_state:

  Target state for occupancy models.

- from_state, to_state:

  Target transition for transition models.

- k:

  Basis dimension for time smooths.

- method:

  Smoothing-parameter estimation method passed to
  [`mgcv::gam()`](https://rdrr.io/pkg/mgcv/man/gam.html).

- include_random_effect:

  Include a participant random-effect smooth.

## Value

An object of class `gp3_sequence_time_model`.

## Examples

``` r
set.seed(2026)

n_participants <- 24L
n_positions <- 12L

participant_index <- rep(
  seq_len(n_participants),
  each = n_positions
)

sequence_order <- rep(
  seq_len(n_positions),
  times = n_participants
)

group_by_participant <- rep(
  c("control", "treatment"),
  each = n_participants %/% 2L
)

group <- rep(
  group_by_participant,
  each = n_positions
)

probability <- stats::plogis(
  -0.8 +
    0.08 * sequence_order +
    0.4 * (group == "treatment")
)

observed_b <- stats::rbinom(
  length(probability),
  size = 1L,
  prob = probability
)

sequences <- data.frame(
  participant_id = paste0("p", participant_index),
  sequence_id = paste0("s", participant_index),
  sequence_order = sequence_order,
  state = ifelse(observed_b == 1L, "B", "A"),
  group = group
)

if (requireNamespace("mgcv", quietly = TRUE)) {
  fit <- fit_time_varying_sequence_model(
    sequences,
    group_col = "group",
    participant_id_col = "participant_id",
    target_state = "B",
    k = 4L
  )
}
```
