test_that("time-varying models are dependency guarded and auditable", {
  grDevices::pdf(tempfile(fileext = ".pdf"))
  on.exit(grDevices::dev.off(), add = TRUE)
  set.seed(101)
  participants <- paste0("p", seq_len(24L))
  data <- do.call(
    rbind,
    lapply(seq_along(participants), function(i) {
      time <- seq_len(12L)
      group <- if (i <= 12L) "g1" else "g2"
      linear_predictor <-
        -0.4 +
        0.06 * time +
        0.35 * (group == "g2") * sin(time / 3)

      data.frame(
        participant_id = participants[i],
        sequence_id = participants[i],
        sequence_order = time,
        state = ifelse(
          stats::runif(length(time)) <
            stats::plogis(linear_predictor),
          "A",
          "B"
        ),
        group = group,
        stringsAsFactors = FALSE
      )
    })
  )
  if (!requireNamespace("mgcv", quietly = TRUE)) {
    expect_error(
      fit_time_varying_sequence_model(
        data,
        group_col = "group",
        participant_id_col = "participant_id",
        target_state = "A",
        k = 3L
      ),
      "mgcv"
    )
    skip("mgcv is not installed")
  }

  fit <- fit_time_varying_sequence_model(
    data,
    group_col = "group",
    participant_id_col = "participant_id",
    target_state = "A",
    k = 3L,
    include_random_effect = FALSE
  )
  expect_s3_class(fit, "gp3_sequence_time_model")
  expect_equal(fit$outcome, "state")
  expect_equal(fit$group_levels, c("g1", "g2"))
  prediction <- predict_time_varying_sequence_model(fit)
  expect_true(all(c("time", "group", "estimate", "lower", "upper") %in% names(prediction)))
  expect_true(all(prediction$estimate >= 0 & prediction$estimate <= 1))
  summary <- summarise_time_varying_sequence_model(fit)
  expect_true(all(c("metadata", "smooth_terms", "converged") %in% names(summary)))
  expect_invisible(plot_time_varying_sequence_model(fit))
})
