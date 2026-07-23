test_that("GrpString adapter creates deterministic strings and key", {
  data <- make_advanced_sequence_data()
  adapted <- as_grpstring_data(data)
  expect_s3_class(adapted, "gp3_grpstring_input")
  expect_equal(length(adapted$strings), 8L)
  expect_equal(nrow(adapted$key), 4L)
  expect_true(all(nchar(adapted$strings) == 5L))
  expect_identical(adapted, as_grpstring_data(data))
})

test_that("gp3tools compatibility helper maps common columns", {
  data <- make_advanced_sequence_data()
  names(data)[names(data) == "sequence_order"] <- "position"
  names(data)[names(data) == "state"] <- "aoi_label"
  prepared <- prepare_gp3tools_sequences(data, metadata_cols = c("group", "participant_id"))
  expect_true(prepared$status %in% c("pass", "review"))
  expect_true(all(c("sequence_id", "sequence_order", "state") %in% names(prepared$data)))
})

test_that("TraMineR and seqHMM adapters are guarded", {
  data <- make_advanced_sequence_data()
  if (requireNamespace("TraMineR", quietly = TRUE)) {
    object <- as_traminer_sequences(data)
    expect_true(inherits(object, "stslist"))
  } else {
    expect_error(as_traminer_sequences(data), "Optional package")
  }
  if (requireNamespace("TraMineR", quietly = TRUE) &&
      requireNamespace("seqHMM", quietly = TRUE)) {
    object <- as_seqhmm_sequences(data)
    expect_true(inherits(object, "stslist"))
  } else {
    expect_error(as_seqhmm_sequences(data), "Optional package")
  }
})

test_that("arules adapter is guarded or returns sequential metadata", {
  data <- make_advanced_sequence_data()
  if (requireNamespace("arules", quietly = TRUE) &&
      requireNamespace("arulesSequences", quietly = TRUE)) {
    transactions <- as_arules_sequences(data)
    info <- arules::transactionInfo(transactions)
    expect_true(all(c("sequenceID", "eventID") %in% names(info)))
    expect_true(all(info$sequenceID > 0L))
    expect_true(all(info$eventID > 0L))
  } else {
    expect_error(as_arules_sequences(data), "Optional package")
  }
})


test_that("igraph adapter refuses unresolved grouped networks", {
  data <- make_advanced_sequence_data()
  grouped <- create_transition_network(data, group_cols = "group")
  if (requireNamespace("igraph", quietly = TRUE)) {
    expect_error(
      as_igraph_transition_network(grouped),
      "Select one network group"
    )
  } else {
    expect_error(as_igraph_transition_network(grouped), "Optional package")
  }
})

test_that("gp3tools compatibility helper refuses ambiguous inferred mappings", {
  data <- make_advanced_sequence_data()
  data$trial_id <- data$sequence_id
  expect_error(
    prepare_gp3tools_sequences(data, order_col = "sequence_order", state_col = "state"),
    "Multiple candidate sequence identifier"
  )

  data <- make_advanced_sequence_data()
  data$fixation_duration <- 100
  data$event_duration <- 100
  expect_error(
    prepare_gp3tools_sequences(data),
    "Multiple candidate duration"
  )
})
