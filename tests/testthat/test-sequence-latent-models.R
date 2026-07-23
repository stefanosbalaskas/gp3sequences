test_that("single HMM fitting is deterministic and normalised", {
  data <- make_advanced_sequence_data()
  first <- fit_sequence_hmm(data, n_states = 2L, max_iter = 40L,
                            tolerance = 1e-7, seed = 11L)
  second <- fit_sequence_hmm(data, n_states = 2L, max_iter = 40L,
                             tolerance = 1e-7, seed = 11L)
  expect_s3_class(first, "gp3_sequence_hmm")
  expect_equal(first$initial_probs, second$initial_probs)
  expect_equal(first$transition_probs, second$transition_probs)
  expect_equal(first$emission_probs, second$emission_probs)
  expect_equal(sum(first$initial_probs), 1, tolerance = 1e-10)
  expect_equal(unname(rowSums(first$transition_probs)), rep(1, 2L), tolerance = 1e-10)
  expect_equal(unname(rowSums(first$emission_probs)), rep(1, 2L), tolerance = 1e-10)
  expect_true(is.finite(first$log_likelihood))
})

test_that("HMM decoding returns one latent state per observation", {
  data <- make_advanced_sequence_data()
  model <- fit_sequence_hmm(data, n_states = 2L, max_iter = 30L, seed = 5L)
  viterbi <- decode_sequence_states(model, method = "viterbi")
  posterior <- decode_sequence_states(model, method = "posterior")
  expect_equal(nrow(viterbi), nrow(data))
  expect_equal(nrow(posterior), nrow(data))
  expect_true(all(viterbi$posterior_probability >= 0 &
                    viterbi$posterior_probability <= 1))
  expect_true(all(posterior$posterior_probability >= 0 &
                    posterior$posterior_probability <= 1))
})

test_that("HMM summaries and model comparisons are structured", {
  data <- make_advanced_sequence_data()
  model_2 <- fit_sequence_hmm(data, 2L, max_iter = 25L, seed = 3L)
  model_3 <- fit_sequence_hmm(data, 3L, max_iter = 25L, seed = 4L)
  summary <- summarise_sequence_hmm(model_2)
  expect_true(all(c("fit", "initial", "transition", "emission") %in% names(summary)))
  comparison <- compare_sequence_hmms(two = model_2, three = model_3)
  expect_equal(nrow(comparison), 2L)
  expect_true(all(c("delta_aic", "delta_bic", "converged") %in% names(comparison)))
})

test_that("mixture HMM responsibilities are normalised and deterministic", {
  data <- make_advanced_sequence_data()
  first <- fit_sequence_hmm_mixture(data, n_components = 2L, n_states = 2L,
                                    max_iter = 30L, inner_initial_iter = 5L,
                                    seed = 21L)
  second <- fit_sequence_hmm_mixture(data, n_components = 2L, n_states = 2L,
                                     max_iter = 30L, inner_initial_iter = 5L,
                                     seed = 21L)
  expect_s3_class(first, "gp3_sequence_hmm_mixture")
  probs <- as.matrix(first$responsibilities[, c("component_1", "component_2")])
  expect_equal(rowSums(probs), rep(1, nrow(probs)), tolerance = 1e-10)
  expect_equal(first$mixture_weights, second$mixture_weights)
  expect_equal(first$responsibilities, second$responsibilities)
  decoded <- decode_sequence_states(first)
  expect_equal(nrow(decoded), nrow(data))
  expect_true(all(decoded$component %in% 1:2))
})

test_that("HMM inputs reject unsupported symbols and invalid probabilities", {
  data <- make_advanced_sequence_data()
  expect_error(fit_sequence_hmm(data, 2L, symbol_levels = c("A", "B")),
               "does not cover")
  expect_error(fit_sequence_hmm(data, 2L,
                                initial_probs = c(-1, 2)), "Invalid")
})

test_that("HMM initialisation rejects non-finite probabilities", {
  data <- make_advanced_sequence_data()
  expect_error(
    fit_sequence_hmm(data, 2L, initial_probs = c(Inf, 1)),
    "Invalid `initial_probs`"
  )
  expect_error(
    fit_sequence_hmm(
      data,
      2L,
      transition_probs = matrix(c(1, 0, NA, 1), 2L, 2L)
    ),
    "Invalid `transition_probs`"
  )
})

test_that("HMM fitting restores the caller random-number state", {
  set.seed(321L)
  before <- .Random.seed
  fit_sequence_hmm(make_advanced_sequence_data(), 2L,
                   max_iter = 3L, seed = 2L)
  expect_identical(.Random.seed, before)
})

test_that("HMM fit criteria require a common observation basis", {
  data <- make_advanced_sequence_data()
  full <- fit_sequence_hmm(data, 2L, max_iter = 3L, seed = 1L)
  reduced <- fit_sequence_hmm(
    data[data$sequence_id != "s08", , drop = FALSE],
    2L,
    max_iter = 3L,
    seed = 1L
  )
  expect_error(
    compare_sequence_hmms(full = full, reduced = reduced),
    "same number of observations"
  )
})

test_that("HMM symbol levels are unique and exclude unused factor levels", {
  data <- make_advanced_sequence_data()
  expect_error(
    fit_sequence_hmm(data, 2L, symbol_levels = c("A", "A", "B", "C", "D"),
                     max_iter = 2L),
    "unique"
  )
  data$state <- factor(data$state, levels = c("A", "B", "C", "D", "UNUSED"))
  model <- fit_sequence_hmm(data, 2L, max_iter = 2L, seed = 5L)
  expect_false("UNUSED" %in% model$symbol_names)
})

test_that("HMM comparison requires identical sequence identifiers", {
  data <- make_advanced_sequence_data()
  first <- fit_sequence_hmm(data, 2L, max_iter = 2L, seed = 1L)
  renamed <- data
  renamed$sequence_id <- paste0("renamed_", renamed$sequence_id)
  second <- fit_sequence_hmm(renamed, 2L, max_iter = 2L, seed = 1L)
  expect_error(
    compare_sequence_hmms(first = first, second = second),
    "identical training sequences"
  )
})

testthat::test_that("mixture seed offsets remain valid at the integer boundary", {
  data <- make_advanced_sequence_data()

  testthat::expect_error(
    fit_sequence_hmm(data, 2L, max_iter = 1L, seed = -1L),
    "seed"
  )
  testthat::expect_silent(
    fit_sequence_hmm_mixture(
      data,
      n_components = 2L,
      n_states = 1L,
      max_iter = 1L,
      inner_initial_iter = 1L,
      seed = .Machine$integer.max
    )
  )
})

test_that("mixture hidden-state counts reject values outside R integer range", {
  data <- make_advanced_sequence_data()
  expect_error(
    fit_sequence_hmm_mixture(
      data,
      n_components = 2L,
      n_states = c(1, .Machine$integer.max + 1),
      max_iter = 1L,
      inner_initial_iter = 1L
    ),
    "positive integer"
  )
})
