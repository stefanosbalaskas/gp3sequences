test_that("covariate HMM fits with explicit design matrices", {
  data <- make_extension_sequence_data()
  fit <- fit_covariate_sequence_hmm(
    data,
    n_states = 2L,
    initial_covariate_cols = "condition_numeric",
    transition_covariate_cols = "condition_numeric",
    max_iter = 3L,
    inner_maxit = 10L,
    seed = 12L
  )
  expect_s3_class(fit, "gp3_covariate_sequence_hmm")
  expect_equal(dim(fit$emission_probs), c(2L, 4L))
  expect_true(is.finite(fit$log_likelihood))
  newdata <- data.frame(condition_numeric = c(0, 1))
  prediction <- predict_covariate_transition_probabilities(fit, newdata)
  expect_true(all(c("row", "from_state", "to_state", "probability") %in% names(prediction)))
  expect_equal(nrow(prediction), 8L)
  decoded <- decode_covariate_sequence_states(fit)
  expect_equal(nrow(decoded), nrow(data))
  summary <- summarise_covariate_sequence_hmm(fit)
  expect_true(all(c("fit", "initial_coefficients", "transition_coefficients", "emission") %in% names(summary)))
})
