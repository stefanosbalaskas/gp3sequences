test_that("sequence inference records the design and resamples independent units", {
  grDevices::pdf(tempfile(fileext = ".pdf"))
  on.exit(grDevices::dev.off(), add = TRUE)
  data <- make_extension_sequence_data()
  design <- declare_sequence_comparison_design(
    group_col = "group",
    unit_col = "participant_id",
    design = "observational"
  )
  expect_s3_class(design, "gp3_sequence_comparison_design")
  inference <- test_sequence_group_difference(
    data,
    design,
    metric = "state_prevalence",
    target_state = "A",
    n_permutations = 49L,
    seed = 4L
  )
  expect_s3_class(inference, "gp3_sequence_group_inference")
  expect_equal(nrow(inference$unit_data), 8L)
  expect_true(inference$estimate$p_value >= 0 && inference$estimate$p_value <= 1)
  expect_match(inference$interpretation, "Associational")
  inference <- bootstrap_sequence_group_difference(
    inference, n_boot = 49L, seed = 5L
  )
  expect_equal(nrow(inference$bootstrap$interval), 1L)
  summary <- summarise_sequence_group_inference(inference)
  expect_true(all(c("estimate", "bootstrap_interval", "design", "interpretation") %in% names(summary)))
  expect_invisible(plot_sequence_group_inference(inference, type = "group_means"))
})
