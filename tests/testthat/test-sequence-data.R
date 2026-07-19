make_valid_sequence_data <- function() {
  data.frame(
    id = rep(c("s1", "s2"), each = 3L),
    position = rep(1:3, times = 2L),
    state = c(
      "home",
      "search",
      "product",
      "home",
      "category",
      "product"
    ),
    duration_ms = c(100, 200, 300, 120, 180, 260),
    participant = rep(c("p1", "p2"), each = 3L),
    stringsAsFactors = FALSE
  )
}

test_that("audit output has a stable empty contract", {
  data <- make_valid_sequence_data()

  audit <- audit_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    duration_col = "duration_ms",
    metadata_cols = "participant"
  )

  expect_s3_class(audit, "data.frame")
  expect_identical(
    names(audit),
    c(
      "sequence_id",
      "row",
      "column",
      "issue_code",
      "severity",
      "value",
      "message",
      "action"
    )
  )
  expect_equal(nrow(audit), 0L)
})

test_that("validation reports normal and empty inputs", {
  data <- make_valid_sequence_data()

  result <- validate_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  expect_true(result$valid)
  expect_identical(result$status, "pass")
  expect_identical(result$n_sequences, 2L)
  expect_identical(result$n_rows, 6L)

  empty <- data[0, , drop = FALSE]

  empty_result <- validate_sequence_data(
    empty,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  expect_false(empty_result$valid)
  expect_identical(empty_result$status, "fail")
  expect_true(
    "empty_data" %in% empty_result$audit$issue_code
  )
})

test_that("missing columns and states are explicit errors", {
  data <- make_valid_sequence_data()

  missing_column <- validate_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "missing_position",
    state_col = "state"
  )

  expect_false(missing_column$valid)
  expect_true(
    "missing_required_column" %in%
      missing_column$audit$issue_code
  )

  data$state[2L] <- NA_character_

  missing_state <- validate_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  expect_false(missing_state$valid)
  expect_true(
    "missing_state" %in% missing_state$audit$issue_code
  )
})

test_that("ordering, gaps, and duplicated positions are audited", {
  data <- make_valid_sequence_data()
  data <- data[c(2, 1, 3, 4, 5, 6), , drop = FALSE]

  audit <- audit_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  expect_true("unordered_rows" %in% audit$issue_code)

  gap_data <- make_valid_sequence_data()
  gap_data$position[3L] <- 4

  gap_audit <- audit_sequence_data(
    gap_data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  expect_true("missing_positions" %in% gap_audit$issue_code)

  duplicate_data <- rbind(
    make_valid_sequence_data(),
    make_valid_sequence_data()[2L, , drop = FALSE]
  )

  duplicate_audit <- audit_sequence_data(
    duplicate_data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  expect_true(
    "duplicated_position" %in%
      duplicate_audit$issue_code
  )
})

test_that("duration and metadata errors are detected", {
  data <- make_valid_sequence_data()
  data$duration_ms[2L] <- -1

  duration_audit <- audit_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    duration_col = "duration_ms"
  )

  expect_true(
    "negative_duration" %in%
      duration_audit$issue_code
  )

  data <- make_valid_sequence_data()
  data$participant[2L] <- "different"

  metadata_audit <- audit_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    metadata_cols = "participant"
  )

  expect_true(
    "inconsistent_metadata" %in%
      metadata_audit$issue_code
  )
})

test_that("preparation sorts deterministically and preserves identifiers", {
  data <- make_valid_sequence_data()[c(6, 2, 1, 5, 3, 4), ]

  prepared <- prepare_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    duration_col = "duration_ms",
    metadata_cols = "participant"
  )

  expect_identical(prepared$status, "pass")
  expect_s3_class(prepared$data, "data.frame")

  expect_identical(
    names(prepared$data)[1:5],
    c(
      "sequence_id",
      "sequence_order",
      "state",
      "original_row",
      "duration"
    )
  )

  expect_identical(
    as.character(prepared$data$sequence_id),
    rep(c("s1", "s2"), each = 3L)
  )

  expect_identical(
    prepared$data$sequence_order,
    rep(1:3, times = 2L)
  )

  expect_identical(
    prepared$data$original_row,
    c(3L, 2L, 5L, 6L, 4L, 1L)
  )

  expect_true("participant" %in% names(prepared$data))
})

test_that("explicit policies drop missing and unknown states", {
  data <- make_valid_sequence_data()
  data$state[2L] <- NA_character_
  data$state[5L] <- "unknown"

  prepared <- prepare_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    expected_states = c(
      "home",
      "search",
      "category",
      "product"
    ),
    missing_state_policy = "drop",
    unknown_state_policy = "drop"
  )

  expect_identical(prepared$status, "review")
  expect_false(anyNA(prepared$data$state))
  expect_false("unknown" %in% prepared$data$state)
  expect_identical(prepared$prepared_n_rows, 4L)
})

test_that("duplicate and repeated-state policies are deterministic", {
  data <- data.frame(
    id = rep("s1", 5L),
    position = c(1, 2, 2, 3, 4),
    state = c("A", "B", "C", "C", "D"),
    duration_ms = c(1, 2, 3, 4, 5),
    stringsAsFactors = FALSE
  )

  prepared <- prepare_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    duration_col = "duration_ms",
    duplicate_position_policy = "last",
    repeated_state_policy = "collapse"
  )

  # Position 3 is removed during the explicit repeated-state collapse.
  # The preserved source positions are therefore 1, 2, and 4, which
  # correctly produces a review-level missing-position diagnostic.
  expect_identical(prepared$status, "review")
  expect_s3_class(prepared$data, "data.frame")

  expect_identical(
    as.character(prepared$data$state),
    c("A", "C", "D")
  )
  expect_identical(
    prepared$data$sequence_order,
    c(1, 2, 4)
  )
  expect_identical(
    prepared$data$duration,
    c(1, 7, 5)
  )
  expect_identical(
    prepared$data$original_row,
    c(1L, 3L, 5L)
  )

  expect_true(
    any(
      prepared$audit$stage == "output" &
        prepared$audit$issue_code == "missing_positions" &
        prepared$audit$severity == "review"
    )
  )

  duplicate_decision <- prepared$decisions[
    prepared$decisions$step == "duplicated_positions",
    ,
    drop = FALSE
  ]

  repeat_decision <- prepared$decisions[
    prepared$decisions$step == "consecutive_repeats",
    ,
    drop = FALSE
  ]

  expect_identical(duplicate_decision$policy, "last")
  expect_identical(duplicate_decision$affected_rows, 1L)
  expect_identical(repeat_decision$policy, "collapse")
  expect_identical(repeat_decision$affected_rows, 1L)
})


test_that("unresolved policy errors suppress prepared data", {
  data <- make_valid_sequence_data()
  data$duration_ms[2L] <- 0

  zero_error <- prepare_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    duration_col = "duration_ms",
    zero_duration_policy = "error"
  )

  expect_identical(zero_error$status, "fail")
  expect_null(zero_error$data)
  expect_true(
    "zero_duration_disallowed" %in%
      zero_error$audit$issue_code
  )

  data <- make_valid_sequence_data()
  data$duration_ms[2L] <- -1

  negative <- prepare_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    duration_col = "duration_ms"
  )

  expect_identical(negative$status, "fail")
  expect_null(negative$data)
  expect_true(
    "negative_duration" %in% negative$audit$issue_code
  )
})

test_that("single-state and unused levels remain reviewable", {
  data <- data.frame(
    id = "s1",
    position = 1,
    state = factor("A", levels = c("A", "B"))
  )

  validation <- validate_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  expect_true(validation$valid)
  expect_identical(validation$status, "review")
  expect_true(
    "single_state_sequence" %in%
      validation$audit$issue_code
  )
  expect_true(
    "unused_state_levels" %in%
      validation$audit$issue_code
  )
})
