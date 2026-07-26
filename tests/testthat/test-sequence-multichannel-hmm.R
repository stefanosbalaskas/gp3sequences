test_that("multichannel HMM fits, decodes, and summarises", {
  grDevices::pdf(tempfile(fileext = ".pdf"))
  on.exit(grDevices::dev.off(), add = TRUE)
  data <- make_extension_sequence_data()
  fit <- fit_multichannel_sequence_hmm(
    data,
    n_states = 2L,
    channel_cols = c("state", "channel_context"),
    max_iter = 4L,
    seed = 11L
  )
  expect_s3_class(fit, "gp3_multichannel_sequence_hmm")
  expect_equal(dim(fit$transition_probs), c(2L, 2L))
  expect_length(fit$emission_probs, 2L)
  expect_true(is.finite(fit$log_likelihood))
  decoded <- decode_multichannel_sequence_states(fit)
  expect_equal(nrow(decoded), nrow(data))
  expect_true(all(c("sequence_id", "sequence_order", "latent_state") %in% names(decoded)))
  summary <- summarise_multichannel_sequence_hmm(fit)
  expect_true(all(c("fit", "initial", "transition", "emission") %in% names(summary)))
  expect_invisible(plot_multichannel_sequence_hmm(fit, channel = "state"))
})
