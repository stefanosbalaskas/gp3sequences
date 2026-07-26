test_that("distance contract enforces core mathematical invariants", {
  x <- .sequence_test_case("minimal")

  distance <- compute_sequence_distance(
    x,
    method = "levenshtein"
  )
  matrix_distance <- as.matrix(
    distance
  )

  expect_true(
    all(matrix_distance >= 0)
  )
  expect_equal(
    unname(diag(matrix_distance)),
    rep(
      0,
      nrow(matrix_distance)
    )
  )
  expect_equal(
    matrix_distance,
    t(matrix_distance)
  )
  expect_identical(
    rownames(matrix_distance),
    colnames(matrix_distance)
  )

  issues <- .sequence_validate_distance_matrix(
    distance
  )

  expect_equal(
    nrow(issues),
    0L
  )
})

test_that("probability simplex and matrix validators work", {
  expect_true(
    .sequence_check_probability_simplex(
      c(0.2, 0.8)
    )
  )
  expect_false(
    .sequence_check_probability_simplex(
      c(0.2, 0.9)
    )
  )

  valid <- matrix(
    c(
      0.8, 0.2,
      0.3, 0.7
    ),
    2L,
    byrow = TRUE
  )

  invalid <- valid
  invalid[1L, ] <- c(0.8, 0.3)

  expect_equal(
    nrow(
      .sequence_validate_probability_matrix(
        valid
      )
    ),
    0L
  )

  expect_true(
    any(
      .sequence_validate_probability_matrix(
        invalid
      )$code ==
        "probability_rows_not_normalised"
    )
  )
})

test_that("partition labels canonicalise without changing membership", {
  assignments <- c(
    s3 = "beta",
    s1 = "alpha",
    s2 = "alpha",
    s4 = "beta"
  )

  canonical <- .sequence_align_partition_labels(
    assignments
  )

  expect_identical(
    names(canonical),
    names(assignments)
  )
  expect_equal(
    unname(canonical["s1"]),
    unname(canonical["s2"])
  )
  expect_equal(
    unname(canonical["s3"]),
    unname(canonical["s4"])
  )
  expect_false(
    canonical["s1"] ==
      canonical["s3"]
  )
})
