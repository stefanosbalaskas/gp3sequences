test_that("distance is invariant to input row order with explicit order", {
  x <- .sequence_test_case("minimal")

  set.seed(2026)
  shuffled <- x[
    sample(
      seq_len(
        nrow(x)
      )
    ),
    ,
    drop = FALSE
  ]

  original <- compute_sequence_distance(
    x,
    method = "levenshtein"
  )
  permuted <- compute_sequence_distance(
    shuffled,
    method = "levenshtein"
  )

  expect_equal(
    as.matrix(original),
    as.matrix(permuted)
  )
  expect_setequal(
    attr(
      original,
      "state_levels"
    ),
    attr(
      permuted,
      "state_levels"
    )
  )
})

test_that("irrelevant metadata does not change sequence distance", {
  x <- .sequence_test_case("minimal")
  y <- x

  y$irrelevant_metadata <- paste0(
    "row",
    seq_len(
      nrow(y)
    )
  )

  dx <- compute_sequence_distance(
    x,
    method = "lcs"
  )
  dy <- compute_sequence_distance(
    y,
    method = "lcs"
  )

  expect_equal(
    as.matrix(dx),
    as.matrix(dy)
  )
})

test_that("state relabelling preserves Levenshtein geometry", {
  x <- .sequence_test_case("minimal")
  y <- x

  mapping <- c(
    A = "north",
    B = "south",
    C = "east",
    D = "west"
  )

  y$state <- unname(
    mapping[y$state]
  )

  dx <- compute_sequence_distance(
    x,
    method = "levenshtein"
  )
  dy <- compute_sequence_distance(
    y,
    method = "levenshtein"
  )

  expect_equal(
    unname(
      as.matrix(dx)
    ),
    unname(
      as.matrix(dy)
    )
  )
})
