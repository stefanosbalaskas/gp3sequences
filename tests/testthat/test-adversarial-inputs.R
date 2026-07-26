test_that("torture corpus exposes expected validation failures", {
  empty <- .sequence_test_case(
    "empty"
  )
  duplicate <- .sequence_test_case(
    "duplicate_positions"
  )
  negative <- .sequence_test_case(
    "negative_duration"
  )

  empty_check <- validate_sequence_data(
    empty,
    "sequence_id",
    "sequence_order",
    "state",
    duration_col = "duration"
  )
  duplicate_check <- validate_sequence_data(
    duplicate,
    "sequence_id",
    "sequence_order",
    "state",
    duration_col = "duration"
  )
  negative_check <- validate_sequence_data(
    negative,
    "sequence_id",
    "sequence_order",
    "state",
    duration_col = "duration"
  )

  expect_identical(
    empty_check$status,
    "fail"
  )
  expect_identical(
    duplicate_check$status,
    "fail"
  )
  expect_identical(
    negative_check$status,
    "fail"
  )
})

test_that("torture corpus exposes review rather than silent destruction", {
  gaps <- .sequence_test_case(
    "order_gaps"
  )
  zeros <- .sequence_test_case(
    "zero_duration"
  )
  repeats <- .sequence_test_case(
    "high_repetition"
  )

  gap_check <- validate_sequence_data(
    gaps,
    "sequence_id",
    "sequence_order",
    "state",
    duration_col = "duration"
  )
  zero_check <- validate_sequence_data(
    zeros,
    "sequence_id",
    "sequence_order",
    "state",
    duration_col = "duration"
  )
  repeat_check <- validate_sequence_data(
    repeats,
    "sequence_id",
    "sequence_order",
    "state",
    duration_col = "duration"
  )

  expect_true(
    gap_check$status %in% c(
      "review",
      "fail"
    )
  )
  expect_true(
    zero_check$status %in% c(
      "review",
      "fail"
    )
  )
  expect_true(
    repeat_check$status %in% c(
      "review",
      "fail"
    )
  )
})
