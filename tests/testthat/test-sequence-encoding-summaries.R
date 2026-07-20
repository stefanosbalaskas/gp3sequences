make_encoding_summary_data <- function() {
  data.frame(
    id = c(
      rep("s1", 4L),
      rep("s2", 3L)
    ),
    position = c(1:4, 1:3),
    state = c(
      "A", "B", "A", "C",
      "B", "C", "A"
    ),
    duration_ms = c(
      1, 2, 3, 4,
      2, 2, 6
    ),
    group = c(
      rep("g1", 4L),
      rep("g2", 3L)
    ),
    stringsAsFactors = FALSE
  )
}

test_that("state encoding is deterministic across row order", {
  data <- make_encoding_summary_data()
  shuffled <- data[c(7, 2, 5, 1, 4, 3, 6), ]

  first <- encode_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  second <- encode_sequence_data(
    shuffled,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  expect_identical(first$status, "pass")
  expect_identical(first$dictionary, second$dictionary)

  expect_identical(
    first$dictionary$state,
    c("A", "B", "C")
  )

  expect_identical(
    first$dictionary$state_index,
    1:3
  )

  expect_identical(
    first$dictionary$state_code,
    c("S1", "S2", "S3")
  )

  comparable <- c(
    "sequence_id",
    "sequence_order",
    "state",
    "state_index",
    "state_code"
  )

  expect_identical(
    first$data[comparable],
    second$data[comparable]
  )
})

test_that("custom encoding levels and labels are respected", {
  data <- make_encoding_summary_data()

  encoded <- encode_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    state_levels = c("C", "B", "A", "Z"),
    prefix = "Q",
    width = 2
  )

  expect_identical(
    encoded$dictionary$state,
    c("C", "B", "A", "Z")
  )

  expect_identical(
    encoded$dictionary$state_code,
    c("Q01", "Q02", "Q03", "Q04")
  )

  expect_identical(
    encoded$dictionary$observed,
    c(TRUE, TRUE, TRUE, FALSE)
  )

  expect_identical(encoded$settings$width, 2L)

  expect_error(
    encode_sequence_data(
      data,
      sequence_id_col = "id",
      order_col = "position",
      state_col = "state",
      state_levels = c("A", "B")
    ),
    "omits observed states"
  )
})

test_that("factor levels define the default encoding order", {
  data <- make_encoding_summary_data()

  data$state <- factor(
    data$state,
    levels = c("C", "A", "B", "Z")
  )

  encoded <- encode_sequence_data(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  expect_identical(
    encoded$dictionary$state,
    c("C", "A", "B", "Z")
  )

  expect_false(
    encoded$dictionary$observed[
      encoded$dictionary$state == "Z"
    ]
  )
})

test_that("state summaries return exact counts and proportions", {
  data <- make_encoding_summary_data()

  result <- summarise_sequence_states(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    duration_col = "duration_ms",
    metadata_cols = "group"
  )

  expect_identical(result$status, "pass")

  s1_a <- result$by_sequence[
    result$by_sequence$sequence_id == "s1" &
      result$by_sequence$state == "A",
    ,
    drop = FALSE
  ]

  expect_identical(s1_a$group, "g1")
  expect_identical(s1_a$n_observations, 2L)
  expect_equal(s1_a$observation_proportion, 0.5)
  expect_equal(s1_a$duration_sum, 4)
  expect_equal(s1_a$duration_proportion, 0.4)
  expect_equal(s1_a$mean_duration, 2)

  overall_a <- result$overall[
    result$overall$state == "A",
    ,
    drop = FALSE
  ]

  expect_identical(overall_a$n_sequences, 2L)
  expect_equal(overall_a$sequence_proportion, 1)
  expect_identical(overall_a$n_observations, 3L)
  expect_equal(
    overall_a$observation_proportion,
    3 / 7
  )
  expect_equal(overall_a$duration_sum, 10)
  expect_equal(overall_a$duration_proportion, 0.5)
  expect_equal(overall_a$mean_duration, 10 / 3)
})

test_that("state summaries are deterministic across input order", {
  data <- make_encoding_summary_data()
  shuffled <- data[c(6, 1, 7, 4, 2, 5, 3), ]

  first <- summarise_sequence_states(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  second <- summarise_sequence_states(
    shuffled,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  expect_identical(
    first$by_sequence,
    second$by_sequence
  )

  expect_identical(
    first$overall,
    second$overall
  )
})

test_that("transition summaries return exact adjacent counts", {
  data <- make_encoding_summary_data()

  result <- summarise_sequence_transitions(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    metadata_cols = "group"
  )

  expect_identical(result$status, "pass")

  s1_a_b <- result$by_sequence[
    result$by_sequence$sequence_id == "s1" &
      result$by_sequence$from_state == "A" &
      result$by_sequence$to_state == "B",
    ,
    drop = FALSE
  ]

  expect_identical(s1_a_b$group, "g1")
  expect_identical(s1_a_b$n_transitions, 1L)
  expect_equal(
    s1_a_b$sequence_transition_proportion,
    1 / 3
  )
  expect_equal(
    s1_a_b$origin_transition_proportion,
    0.5
  )

  overall_b_a <- result$overall[
    result$overall$from_state == "B" &
      result$overall$to_state == "A",
    ,
    drop = FALSE
  ]

  expect_identical(overall_b_a$n_sequences, 1L)
  expect_equal(
    overall_b_a$sequence_proportion,
    0.5
  )
  expect_identical(
    overall_b_a$n_transitions,
    1L
  )
  expect_equal(
    overall_b_a$transition_proportion,
    0.2
  )
  expect_equal(
    overall_b_a$origin_transition_proportion,
    0.5
  )
})

test_that("self-transition filtering is explicit", {
  data <- data.frame(
    id = rep("s1", 3L),
    position = 1:3,
    state = c("A", "A", "B"),
    stringsAsFactors = FALSE
  )

  retained <- summarise_sequence_transitions(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    include_self = TRUE
  )

  removed <- summarise_sequence_transitions(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    include_self = FALSE
  )

  expect_identical(retained$status, "review")
  expect_true(
    any(
      retained$overall$from_state == "A" &
        retained$overall$to_state == "A"
    )
  )

  expect_false(
    any(
      removed$overall$from_state ==
        removed$overall$to_state
    )
  )

  expect_identical(
    removed$overall$n_transitions,
    1L
  )
})

test_that("single-state sequences produce stable empty transitions", {
  data <- data.frame(
    id = "s1",
    position = 1,
    state = "A",
    stringsAsFactors = FALSE
  )

  result <- summarise_sequence_transitions(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  expect_identical(result$status, "review")
  expect_equal(nrow(result$by_sequence), 0L)
  expect_equal(nrow(result$overall), 0L)

  expect_identical(
    names(result$overall),
    c(
      "from_state",
      "to_state",
      "n_sequences",
      "sequence_proportion",
      "n_transitions",
      "transition_proportion",
      "origin_transition_proportion"
    )
  )
})

test_that("formatted paths are ordered and retain metadata", {
  data <- make_encoding_summary_data()
  shuffled <- data[c(7, 4, 2, 6, 1, 5, 3), ]

  result <- format_sequence_paths(
    shuffled,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    metadata_cols = "group"
  )

  # The rows are formatted deterministically, but the input audit
  # retains the review-level unordered-row diagnostic.
  expect_identical(result$status, "review")
  expect_true(
    any(
      result$audit$issue_code == "unordered_rows" &
        result$audit$severity == "review"
    )
  )

  expect_identical(
    result$paths$sequence_id,
    c("s1", "s2")
  )

  expect_identical(
    result$paths$group,
    c("g1", "g2")
  )

  expect_identical(
    result$paths$path,
    c(
      "A > B > A > C",
      "B > C > A"
    )
  )

  expect_identical(
    result$paths$n_observations,
    c(4L, 3L)
  )

  expect_identical(
    result$paths$n_states,
    c(4L, 3L)
  )

  ordered_result <- format_sequence_paths(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    metadata_cols = "group"
  )

  expect_identical(ordered_result$status, "pass")
  expect_equal(nrow(ordered_result$audit), 0L)
  expect_identical(
    ordered_result$paths,
    result$paths
  )
})


test_that("path formatting can collapse consecutive repeats", {
  data <- data.frame(
    id = rep("s1", 5L),
    position = 1:5,
    state = c("A", "A", "B", "B", "C"),
    stringsAsFactors = FALSE
  )

  result <- format_sequence_paths(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    separator = "/",
    collapse_repeats = TRUE
  )

  expect_identical(result$status, "review")
  expect_identical(result$paths$n_observations, 5L)
  expect_identical(result$paths$n_states, 3L)
  expect_identical(result$paths$n_unique_states, 3L)
  expect_identical(result$paths$start_state, "A")
  expect_identical(result$paths$end_state, "C")
  expect_identical(result$paths$path, "A/B/C")
})

test_that("summary functions reject unresolved validation errors", {
  data <- make_encoding_summary_data()
  data$position[2L] <- 1

  expect_error(
    encode_sequence_data(
      data,
      sequence_id_col = "id",
      order_col = "position",
      state_col = "state"
    ),
    "failed validation"
  )

  expect_error(
    summarise_sequence_states(
      data,
      sequence_id_col = "id",
      order_col = "position",
      state_col = "state"
    ),
    "failed validation"
  )

  expect_error(
    summarise_sequence_transitions(
      data,
      sequence_id_col = "id",
      order_col = "position",
      state_col = "state"
    ),
    "failed validation"
  )

  expect_error(
    format_sequence_paths(
      data,
      sequence_id_col = "id",
      order_col = "position",
      state_col = "state"
    ),
    "failed validation"
  )
})
