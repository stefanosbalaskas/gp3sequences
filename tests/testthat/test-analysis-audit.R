test_that("analysis audit recognises a native distance object", {
  x <- .sequence_test_case("minimal")

  distance <- compute_sequence_distance(
    x,
    method = "levenshtein"
  )

  audit <- audit_sequence_analysis(
    distance
  )

  expect_s3_class(
    audit,
    "gp3_sequence_analysis_audit"
  )
  expect_identical(
    audit$contract$family,
    "distance"
  )
  expect_identical(
    audit$status,
    "pass"
  )
  expect_equal(
    audit$summary$n_sequence_ids,
    4L
  )
  expect_true(
    audit$summary$n_state_levels >= 4L
  )
})

test_that("analysis audit catches malformed distances", {
  x <- .sequence_test_case("minimal")

  distance <- compute_sequence_distance(
    x,
    method = "levenshtein"
  )

  matrix_distance <- as.matrix(
    distance
  )

  matrix_distance[1L, 2L] <-
    matrix_distance[1L, 2L] + 1

  issues <- .sequence_validate_distance_matrix(
    matrix_distance
  )

  expect_true(
    any(
      issues$code == "asymmetric_distance"
    )
  )
  expect_true(
    any(
      issues$severity == "error"
    )
  )
})

test_that("analysis-result comparison separates structure from values", {
  x <- .sequence_test_case("minimal")

  d1 <- compute_sequence_distance(
    x,
    method = "levenshtein"
  )
  d2 <- compute_sequence_distance(
    x,
    method = "levenshtein"
  )
  d3 <- compute_sequence_distance(
    x,
    method = "lcs"
  )

  same <- compare_sequence_analysis_results(
    d1,
    d2,
    compare_values = TRUE
  )
  different <- compare_sequence_analysis_results(
    d1,
    d3
  )

  expect_s3_class(
    same,
    "gp3_sequence_analysis_comparison"
  )
  expect_true(
    same$all_equal
  )
  expect_false(
    different$all_equal
  )
  expect_false(
    different$comparisons$equal[
      different$comparisons$field == "method"
    ]
  )
})
