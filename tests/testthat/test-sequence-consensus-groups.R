test_that("consensus creation is deterministic and reports support", {
  data <- make_advanced_sequence_data()
  consensus <- create_consensus_sequence(data, group_cols = "group", tie_method = "first")
  expect_s3_class(consensus, "gp3_consensus_sequence")
  expect_true(all(c("consensus_state", "support_n", "agreement", "tie_n") %in% names(consensus)))
  expect_equal(nrow(consensus), 10L)
  expect_true(all(consensus$support_n == 4L))
  expect_true(all(consensus$agreement >= 0.5 & consensus$agreement <= 1))
  again <- create_consensus_sequence(data, group_cols = "group", tie_method = "first")
  expect_identical(consensus, again)
})

test_that("consensus tie policies and missing-state policies are explicit", {
  data <- data.frame(sequence_id = c("s1", "s2"), sequence_order = 1,
                     state = c("B", "A"), stringsAsFactors = FALSE)
  first <- create_consensus_sequence(data, tie_method = "first",
                                     state_levels = c("A", "B"))
  last <- create_consensus_sequence(data, tie_method = "last",
                                    state_levels = c("A", "B"))
  missing <- create_consensus_sequence(data, tie_method = "missing",
                                       state_levels = c("A", "B"))
  all <- create_consensus_sequence(data, tie_method = "all",
                                   state_levels = c("A", "B"))
  expect_equal(first$consensus_state, "A")
  expect_equal(last$consensus_state, "B")
  expect_true(is.na(missing$consensus_state))
  expect_equal(all$consensus_state, "A | B")
  data$state[2L] <- NA_character_
  expect_error(create_consensus_sequence(data, missing_state_policy = "error"))
  expect_equal(create_consensus_sequence(data, missing_state_policy = "exclude")$support_n, 1L)
})

test_that("consensus summaries, formatting and plotting work", {
  data <- make_advanced_sequence_data()
  consensus <- create_consensus_sequence(data, group_cols = "group")
  overall <- summarise_consensus_agreement(consensus, by = "overall")
  grouped <- summarise_consensus_agreement(consensus, by = "group")
  formatted <- format_consensus_sequence(consensus, include_agreement = TRUE)
  expect_equal(nrow(overall), 1L)
  expect_equal(nrow(grouped), 2L)
  expect_equal(nrow(formatted), 2L)
  file <- tempfile(fileext = ".pdf")
  grDevices::pdf(file)
  plotted <- plot_consensus_sequence(consensus, group = "g1")
  grDevices::dev.off()
  expect_true(file.exists(file))
  expect_true(is.data.frame(plotted))
})

test_that("descriptive group comparisons return expected components", {
  data <- make_advanced_sequence_data()
  comparison <- compare_sequence_groups(data, "group")
  expect_s3_class(comparison, "gp3_sequence_group_comparison")
  expect_equal(comparison$groups$n_sequences, c(4L, 4L))
  expect_true(all(c("state", "event_share", "sequence_prevalence") %in%
                    names(comparison$state_summary)))
  expect_true(all(c("transition", "occurrence_share") %in%
                    names(comparison$transition_summary)))
  expect_equal(nrow(comparison$length_summary), 2L)
  expect_false(any(grepl("p_value|statistic", names(comparison$state_contrasts))))
})

test_that("group comparison plotting returns plotted data", {
  comparison <- compare_sequence_groups(make_advanced_sequence_data(), "group")
  file <- tempfile(fileext = ".pdf")
  grDevices::pdf(file)
  state_data <- plot_sequence_group_comparison(comparison, "state", top_n = 4)
  length_data <- plot_sequence_group_comparison(comparison, "length")
  grDevices::dev.off()
  expect_true(nrow(state_data) > 0L)
  expect_equal(nrow(length_data), 2L)
})

test_that("grouped consensus requires explicit plot selection", {
  consensus <- create_consensus_sequence(
    make_advanced_sequence_data(),
    group_cols = "group"
  )
  expect_error(
    plot_consensus_sequence(consensus),
    "Select one consensus group"
  )

  ungrouped <- create_consensus_sequence(make_advanced_sequence_data())
  expect_error(
    summarise_consensus_agreement(ungrouped, by = "group"),
    "requires a consensus"
  )
})

test_that("group comparison rejects incomplete grouping metadata", {
  data <- make_advanced_sequence_data()
  data$group[data$sequence_id == "s01"] <- NA_character_
  expect_error(
    compare_sequence_groups(data, "group"),
    "non-missing and non-blank"
  )
})

test_that("advanced metadata mappings cannot duplicate core sequence columns", {
  data <- make_advanced_sequence_data()
  expect_error(
    create_consensus_sequence(data, group_cols = "sequence_id"),
    "must not repeat core sequence columns"
  )
})

test_that("zero-weight rows do not inflate consensus support", {
  data <- data.frame(
    sequence_id = c("s1", "s2"),
    sequence_order = c(1, 1),
    state = c("A", "B"),
    weight = c(1, 0),
    stringsAsFactors = FALSE
  )
  consensus <- create_consensus_sequence(data, weight_col = "weight")
  expect_equal(consensus$consensus_state, "A")
  expect_equal(consensus$support_n, 1L)
  expect_equal(consensus$support_weight, 1)
})

test_that("group comparison transition labels require an unambiguous separator", {
  data <- make_advanced_sequence_data()
  data$state[data$state == "A"] <- "A -> embedded"
  expect_error(
    compare_sequence_groups(data, "group"),
    "must not occur inside"
  )
})

test_that("reference-group contrasts use the reference as denominator", {
  comparison <- compare_sequence_groups(
    make_advanced_sequence_data(),
    "group",
    reference = "g1"
  )
  expect_true(all(comparison$state_contrasts$group_2 == "g1"))
  expect_true(all(comparison$transition_contrasts$group_2 == "g1"))
  expect_true(all(comparison$length_contrasts$group_2 == "g1"))
})

test_that("state plotting represents an unresolved consensus tie explicitly", {
  data <- data.frame(
    sequence_id = c("s1", "s2"),
    sequence_order = c(1, 1),
    state = c("A", "B"),
    stringsAsFactors = FALSE
  )
  consensus <- create_consensus_sequence(data, tie_method = "missing")
  file <- tempfile(fileext = ".pdf")
  grDevices::pdf(file)
  plotted <- plot_consensus_sequence(consensus, type = "states")
  grDevices::dev.off()
  expect_true(file.exists(file))
  expect_true(is.na(plotted$consensus_state))
})

test_that("empty transition comparisons fail clearly when plotted", {
  data <- data.frame(
    sequence_id = c("s1", "s2"),
    sequence_order = c(1, 1),
    state = c("A", "B"),
    group = c("g1", "g2"),
    stringsAsFactors = FALSE
  )
  comparison <- compare_sequence_groups(data, "group")
  expect_error(
    plot_sequence_group_comparison(comparison, component = "transition"),
    "No comparison rows"
  )
})
