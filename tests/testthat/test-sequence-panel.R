test_that("sequence panels are prepared and summarised", {
  data <- make_extension_panel_data()
  panel <- prepare_sequence_panel(
    data,
    panel_id_col = "participant_id",
    occasion_col = "occasion"
  )
  expect_s3_class(panel, "gp3_sequence_panel")
  expect_equal(nrow(panel$index), 16L)
  expect_equal(length(unique(panel$index$panel_id)), 8L)
  expect_equal(sort(unique(panel$index$occasion_rank)), 1:2)

  summary <- summarise_sequence_panel(panel)
  expect_equal(summary$n_panels, 8L)
  expect_equal(summary$n_occasions, 2L)
  expect_true(all(c("occasions", "states") %in% names(summary)))
})

test_that("panel changes are deterministic", {
  grDevices::pdf(tempfile(fileext = ".pdf"))
  on.exit(grDevices::dev.off(), add = TRUE)
  panel <- prepare_sequence_panel(
    make_extension_panel_data(), "participant_id", "occasion"
  )
  changes <- compare_sequence_panel_changes(panel, method = "lcs")
  expect_s3_class(changes, "gp3_sequence_panel_changes")
  expect_equal(nrow(changes), 8L)
  expect_true(all(changes$distance >= 0))
  expect_silent(plot_sequence_panel_changes(changes, type = "summary"))

  zero_error_changes <- changes
  zero_error_changes$distance <- 1
  expect_silent(
    plot_sequence_panel_changes(
      zero_error_changes,
      metric = "distance",
      type = "summary"
    )
  )
})

test_that("duplicated panel occasions fail explicitly", {
  data <- make_extension_panel_data()
  data$occasion[data$sequence_id == "s01_w2"] <- 1L
  expect_error(
    prepare_sequence_panel(data, "participant_id", "occasion"),
    "More than one sequence"
  )
})
