test_that("bounded non-contiguous subsequences are extracted", {
  data <- make_extension_sequence_data()
  occurrences <- extract_sequence_subsequences(
    data,
    metadata_cols = "group",
    min_length = 2L,
    max_length = 3L,
    max_gap = 2L,
    max_span = 4L
  )
  expect_s3_class(occurrences, "gp3_sequence_subsequences")
  expect_gt(nrow(occurrences), 0L)
  expect_true(all(occurrences$subsequence_length %in% 2:3))
  expect_true(all(occurrences$max_observed_gap <= 2))
  expect_true(all(occurrences$span <= 4))
})

test_that("subsequence summaries and filtering are stable", {
  grDevices::pdf(tempfile(fileext = ".pdf"))
  on.exit(grDevices::dev.off(), add = TRUE)
  occurrences <- extract_sequence_subsequences(
    make_extension_sequence_data(), metadata_cols = "group",
    min_length = 2L, max_length = 3L
  )
  summary <- summarise_sequence_subsequences(occurrences)
  expect_true(all(summary$sequence_prevalence >= 0 & summary$sequence_prevalence <= 1))
  filtered <- filter_sequence_subsequences(summary, min_sequences = 2L,
                                           top_n = 5L, ties = "exclude")
  expect_lte(nrow(filtered), 5L)
  expect_silent(plot_sequence_subsequences(summary, top_n = 3L))
})

test_that("group comparisons adjust multiple tests", {
  occurrences <- extract_sequence_subsequences(
    make_extension_sequence_data(), metadata_cols = "group",
    min_length = 2L, max_length = 2L
  )
  comparison <- compare_sequence_subsequences(occurrences, "group")
  expect_true(all(c("p_value", "p_adjusted") %in% names(comparison)))
  expect_true(all(comparison$p_adjusted >= comparison$p_value - 1e-12))
})

test_that("search-space safety limit is enforced", {
  data <- make_extension_sequence_data()
  expect_error(
    extract_sequence_subsequences(data, max_length = 5L,
                                  max_combinations_per_sequence = 2L),
    "exceeds"
  )
})
