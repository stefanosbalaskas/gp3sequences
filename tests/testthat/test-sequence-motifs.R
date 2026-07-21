make_motif_data <- function() {
  data.frame(
    id = c(rep("s1", 5L), rep("s2", 4L)),
    position = c(1:5, 1:4),
    state = c(
      "A", "B", "A", "B", "A",
      "A", "B", "A", "C"
    ),
    group = c(rep("g1", 5L), rep("g2", 4L)),
    stringsAsFactors = FALSE
  )
}

test_that("contiguous n-grams are enumerated with stable positions", {
  data <- make_motif_data()

  result <- extract_sequence_ngrams(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    metadata_cols = "group",
    min_length = 2,
    max_length = 3,
    overlap = "allow"
  )

  expect_identical(result$status, "pass")
  expect_equal(nrow(result$occurrences), 12L)
  expect_identical(
    result$sequences$n_candidate_occurrences,
    c(7L, 5L)
  )
  expect_identical(
    result$sequences$n_retained_occurrences,
    c(7L, 5L)
  )
  expect_true(
    all(
      result$occurrences$end_index -
        result$occurrences$start_index + 1L ==
        result$occurrences$motif_length
    )
  )
  expect_identical(
    result$occurrences$group[
      result$occurrences$sequence_id == "s1"
    ],
    rep("g1", 7L)
  )

  s1_aba <- result$occurrences[
    result$occurrences$sequence_id == "s1" &
      result$occurrences$motif == "A > B > A",
    ,
    drop = FALSE
  ]

  expect_identical(s1_aba$start_index, c(1L, 3L))
  expect_identical(s1_aba$end_index, c(3L, 5L))
  expect_identical(s1_aba$occurrence_index, c(1L, 2L))
})

test_that("overlap policy is explicit and deterministic", {
  data <- make_motif_data()

  allowed <- extract_sequence_ngrams(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    min_length = 3,
    max_length = 3,
    overlap = "allow"
  )

  disallowed <- extract_sequence_ngrams(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    min_length = 3,
    max_length = 3,
    overlap = "disallow"
  )

  allowed_aba <- allowed$occurrences[
    allowed$occurrences$motif == "A > B > A",
    ,
    drop = FALSE
  ]

  disallowed_aba <- disallowed$occurrences[
    disallowed$occurrences$motif == "A > B > A",
    ,
    drop = FALSE
  ]

  expect_equal(nrow(allowed_aba), 3L)
  expect_equal(nrow(disallowed_aba), 2L)
  expect_identical(
    disallowed_aba$start_index,
    c(1L, 1L)
  )
  expect_identical(
    disallowed$settings$overlap_rule,
    "left_to_right_greedy"
  )

  repeated <- data.frame(
    id = rep("s1", 4L),
    position = 1:4,
    state = rep("A", 4L),
    stringsAsFactors = FALSE
  )

  repeated_result <- extract_sequence_ngrams(
    repeated,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    min_length = 2,
    max_length = 2,
    overlap = "disallow"
  )

  expect_identical(repeated_result$status, "review")
  expect_identical(
    repeated_result$occurrences$start_index,
    c(1L, 3L)
  )
})

test_that("row order is corrected while review diagnostics are retained", {
  data <- make_motif_data()
  shuffled <- data[c(7, 2, 9, 1, 6, 4, 3, 8, 5), ]

  ordered <- extract_sequence_ngrams(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    min_length = 2,
    max_length = 3
  )

  reordered <- extract_sequence_ngrams(
    shuffled,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    min_length = 2,
    max_length = 3
  )

  expect_identical(ordered$status, "pass")
  expect_identical(reordered$status, "review")
  expect_true(
    any(reordered$audit$issue_code == "unordered_rows")
  )

  comparison_columns <- c(
    "sequence_id",
    "motif_id",
    "motif",
    "motif_length",
    "start_index",
    "end_index",
    "start_order",
    "end_order",
    "occurrence_index"
  )

  expect_identical(
    ordered$occurrences[comparison_columns],
    reordered$occurrences[comparison_columns]
  )
})

test_that("motif identity remains stable when labels contain separators", {
  data <- data.frame(
    id = c("single", "pair", "pair"),
    position = c(1, 1, 2),
    state = c("A > B", "A", "B"),
    stringsAsFactors = FALSE
  )

  result <- extract_sequence_ngrams(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    min_length = 1,
    max_length = 2,
    separator = " > "
  )

  same_display <- result$occurrences[
    result$occurrences$motif == "A > B",
    c("motif_id", "motif_key", "motif_length"),
    drop = FALSE
  ]

  expect_equal(nrow(same_display), 2L)
  expect_equal(length(unique(same_display$motif_id)), 2L)
  expect_equal(length(unique(same_display$motif_key)), 2L)
  expect_identical(
    sort(same_display$motif_length),
    c(1L, 2L)
  )
})

test_that("motif summaries return exact counts and prevalence", {
  data <- make_motif_data()

  extracted <- extract_sequence_ngrams(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    min_length = 2,
    max_length = 3
  )

  summary <- summarise_sequence_motifs(extracted)

  aba <- summary$overall[
    summary$overall$motif == "A > B > A",
    ,
    drop = FALSE
  ]

  expect_identical(summary$n_sequences, 2L)
  expect_identical(summary$n_occurrences, 12L)
  expect_identical(aba$n_occurrences, 3L)
  expect_identical(aba$n_sequences, 2L)
  expect_equal(aba$sequence_prevalence, 1)
  expect_equal(aba$occurrence_share, 3 / 12)
  expect_equal(aba$mean_occurrences_per_sequence, 1.5)
  expect_equal(aba$mean_occurrences_when_present, 1.5)

  s1_aba <- summary$by_sequence[
    summary$by_sequence$sequence_id == "s1" &
      summary$by_sequence$motif == "A > B > A",
    ,
    drop = FALSE
  ]

  expect_identical(s1_aba$n_occurrences, 2L)
  expect_identical(s1_aba$first_start_index, 1L)
  expect_identical(s1_aba$last_start_index, 3L)
})

test_that("prevalence denominator includes sequences without eligible windows", {
  data <- rbind(
    make_motif_data(),
    data.frame(
      id = "s3",
      position = 1,
      state = "A",
      group = "g3",
      stringsAsFactors = FALSE
    )
  )

  extracted <- extract_sequence_ngrams(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    metadata_cols = "group",
    min_length = 3,
    max_length = 3
  )

  summary <- summarise_sequence_motifs(extracted)
  aba <- summary$overall[
    summary$overall$motif == "A > B > A",
    ,
    drop = FALSE
  ]

  expect_identical(extracted$status, "review")
  expect_identical(summary$n_sequences, 3L)
  expect_equal(aba$sequence_prevalence, 2 / 3)
  expect_identical(
    extracted$sequences$n_candidate_occurrences,
    c(3L, 2L, 0L)
  )
})

test_that("filters apply count prevalence and length thresholds", {
  data <- make_motif_data()

  summary <- summarise_sequence_motifs(
    extract_sequence_ngrams(
      data,
      sequence_id_col = "id",
      order_col = "position",
      state_col = "state",
      min_length = 2,
      max_length = 3
    )
  )

  filtered <- filter_sequence_motifs(
    summary,
    min_occurrences = 3,
    min_sequences = 2,
    min_prevalence = 1,
    motif_lengths = 2
  )

  expect_identical(
    filtered$motifs$motif,
    c("A > B", "B > A")
  )
  expect_identical(filtered$n_available, 6L)
  expect_identical(filtered$n_retained, 2L)
  expect_true(
    all(
      filtered$by_sequence$motif_id %in%
        filtered$motifs$motif_id
    )
  )
})

test_that("top-n ties are included or resolved deterministically", {
  data <- make_motif_data()

  summary <- summarise_sequence_motifs(
    extract_sequence_ngrams(
      data,
      sequence_id_col = "id",
      order_col = "position",
      state_col = "state",
      min_length = 2,
      max_length = 3
    )
  )

  included <- filter_sequence_motifs(
    summary,
    top_n = 1,
    rank_by = "n_occurrences",
    ties = "include"
  )

  first <- filter_sequence_motifs(
    summary,
    top_n = 1,
    rank_by = "n_occurrences",
    ties = "first"
  )

  expect_identical(included$n_retained, 3L)
  expect_true(all(included$motifs$n_occurrences == 3L))
  expect_identical(first$n_retained, 1L)
  expect_identical(first$motifs$motif, "A > B")
})

test_that("formatted motif tables use explicit units and rank ties", {
  data <- make_motif_data()

  summary <- summarise_sequence_motifs(
    extract_sequence_ngrams(
      data,
      sequence_id_col = "id",
      order_col = "position",
      state_col = "state",
      min_length = 2,
      max_length = 3
    )
  )

  formatted <- format_sequence_motifs(
    summary,
    prevalence = "percent",
    digits = 1,
    rank_by = "n_occurrences",
    ties = "min"
  )

  expect_true("sequence_prevalence_percent" %in% names(formatted$table))
  expect_true("occurrence_share_percent" %in% names(formatted$table))
  expect_identical(
    formatted$table$rank[1:3],
    c(1L, 1L, 1L)
  )
  expect_equal(
    formatted$table$sequence_prevalence_percent[1:3],
    rep(100, 3L)
  )

  no_ids <- format_sequence_motifs(
    summary,
    include_ids = FALSE,
    include_rank = FALSE
  )

  expect_false("motif_id" %in% names(no_ids$table))
  expect_false("motif_key" %in% names(no_ids$table))
  expect_false("rank" %in% names(no_ids$table))
})

test_that("empty motif outputs retain stable schemas", {
  data <- make_motif_data()

  extracted <- extract_sequence_ngrams(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    min_length = 6,
    max_length = 6
  )

  summary <- summarise_sequence_motifs(extracted)
  filtered <- filter_sequence_motifs(summary, min_occurrences = 2)
  formatted <- format_sequence_motifs(filtered)

  expect_equal(nrow(extracted$occurrences), 0L)
  expect_equal(nrow(extracted$motifs), 0L)
  expect_equal(nrow(summary$by_sequence), 0L)
  expect_equal(nrow(summary$overall), 0L)
  expect_equal(nrow(filtered$motifs), 0L)
  expect_equal(nrow(formatted$table), 0L)
  expect_true("rank" %in% names(formatted$table))
  expect_true("sequence_prevalence" %in% names(formatted$table))
})

test_that("factor levels define deterministic motif codes", {
  data <- make_motif_data()
  data$state <- factor(
    data$state,
    levels = c("C", "A", "B", "Z")
  )

  result <- extract_sequence_ngrams(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    min_length = 2,
    max_length = 2
  )

  expect_identical(
    result$state_dictionary$state,
    c("C", "A", "B", "Z")
  )
  expect_false(
    result$state_dictionary$observed[
      result$state_dictionary$state == "Z"
    ]
  )

  ab <- result$motifs[result$motifs$motif == "A > B", , drop = FALSE]
  expect_identical(ab$motif_key, "S2|S3")
})

test_that("invalid settings and unresolved input errors are rejected", {
  data <- make_motif_data()

  expect_error(
    extract_sequence_ngrams(
      data,
      sequence_id_col = "id",
      order_col = "position",
      state_col = "state",
      min_length = 3,
      max_length = 2
    ),
    "max_length"
  )

  expect_error(
    extract_sequence_ngrams(
      data,
      sequence_id_col = "id",
      order_col = "position",
      state_col = "state",
      overlap = "sometimes"
    ),
    "overlap"
  )

  duplicated <- data
  duplicated$position[2L] <- 1

  expect_error(
    extract_sequence_ngrams(
      duplicated,
      sequence_id_col = "id",
      order_col = "position",
      state_col = "state"
    ),
    "failed validation"
  )

  extracted <- extract_sequence_ngrams(
    data,
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state"
  )

  expect_error(
    filter_sequence_motifs(extracted, min_prevalence = 1.1),
    "between 0 and 1"
  )

  expect_error(
    filter_sequence_motifs(extracted, motif_lengths = c(2, 2.5)),
    "positive whole numbers"
  )

  expect_error(
    format_sequence_motifs(extracted, digits = 16),
    "must not exceed 15"
  )
})
