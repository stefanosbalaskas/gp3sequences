test_that("all core sequence distances are symmetric and deterministic", {
  data <- make_advanced_sequence_data()
  methods <- c("levenshtein", "lcs", "optimal_matching", "transition")
  for (method in methods) {
    distance <- compute_sequence_distance(data, method = method)
    matrix_distance <- as.matrix(distance)
    expect_s3_class(distance, "gp3_sequence_distance")
    expect_equal(matrix_distance, t(matrix_distance), tolerance = 1e-12)
    expect_equal(unname(diag(matrix_distance)), rep(0, nrow(matrix_distance)))
    expect_true(all(matrix_distance >= 0))
    expect_identical(distance, compute_sequence_distance(data, method = method))
  }
})

test_that("distance normalisation and substitution matrices are explicit", {
  data <- make_advanced_sequence_data()
  states <- sort(unique(data$state))
  costs <- matrix(2, length(states), length(states), dimnames = list(states, states))
  diag(costs) <- 0
  raw <- compute_sequence_distance(data, method = "optimal_matching",
                                   substitution_matrix = costs, normalise = "none")
  norm <- compute_sequence_distance(data, method = "optimal_matching",
                                    substitution_matrix = costs, normalise = "max_length")
  expect_true(all(as.numeric(norm) <= as.numeric(raw)))
  expect_error(compute_sequence_distance(data, method = "optimal_matching",
                                         substitution_matrix = matrix(1, 2, 3)))
})

test_that("distance summaries include overall and per-sequence results", {
  distance <- compute_sequence_distance(make_advanced_sequence_data())
  summary <- summarise_sequence_distance(distance)
  expect_equal(summary$overall$n_sequences, 8L)
  expect_equal(summary$overall$n_pairs, 28L)
  expect_equal(nrow(summary$per_sequence), 8L)
})

test_that("hierarchical clustering and validation are auditable", {
  distance <- compute_sequence_distance(make_advanced_sequence_data(), method = "lcs")
  fit <- cluster_sequences(distance, k = 2L, method = "hierarchical")
  expect_s3_class(fit, "gp3_sequence_clustering")
  expect_equal(length(fit$assignments), 8L)
  expect_equal(length(unique(fit$assignments)), 2L)
  validation <- validate_sequence_clusters(fit)
  expect_equal(validation$overall$n_sequences, 8L)
  expect_true(validation$overall$average_silhouette >= -1)
  expect_true(validation$overall$average_silhouette <= 1)
  representatives <- extract_representative_sequences(fit, n_per_cluster = 2L)
  expect_equal(nrow(representatives), 4L)
})

test_that("PAM is guarded by the optional cluster package", {
  distance <- compute_sequence_distance(make_advanced_sequence_data())
  if (requireNamespace("cluster", quietly = TRUE)) {
    fit <- cluster_sequences(distance, 2L, method = "pam")
    expect_s3_class(fit, "gp3_sequence_clustering")
  } else {
    expect_error(cluster_sequences(distance, 2L, method = "pam"), "Optional package")
  }
})

test_that("bootstrap stability is reproducible", {
  distance <- compute_sequence_distance(make_advanced_sequence_data(), method = "lcs")
  first <- bootstrap_sequence_clusters(distance, k = 2L, n_boot = 8L,
                                       sample_fraction = 0.75, seed = 41L)
  second <- bootstrap_sequence_clusters(distance, k = 2L, n_boot = 8L,
                                        sample_fraction = 0.75, seed = 41L)
  expect_s3_class(first, "gp3_sequence_cluster_bootstrap")
  expect_equal(first$pairwise_stability, second$pairwise_stability)
  summary <- summarise_sequence_cluster_stability(first)
  expect_equal(nrow(summary$clusters), 2L)
  expect_true(summary$overall$mean_pairwise_stability >= 0)
  expect_true(summary$overall$mean_pairwise_stability <= 1)
})

test_that("cluster ensembles use transparent co-association", {
  distance_1 <- compute_sequence_distance(make_advanced_sequence_data(), method = "lcs")
  distance_2 <- compute_sequence_distance(make_advanced_sequence_data(), method = "transition")
  fit_1 <- cluster_sequences(distance_1, 2L)
  fit_2 <- cluster_sequences(distance_2, 2L)
  ensemble <- create_sequence_cluster_ensemble(fit_1, fit_2, k = 2L)
  expect_s3_class(ensemble, "gp3_sequence_cluster_ensemble")
  expect_equal(unname(diag(ensemble$coassociation)), rep(1, 8L))
  expect_true(all(ensemble$coassociation >= 0 & ensemble$coassociation <= 1))
  expect_equal(length(unique(ensemble$assignments)), 2L)
})

test_that("distance and substitution matrices enforce metric structure", {
  data <- make_advanced_sequence_data()
  states <- sort(unique(data$state))
  asymmetric <- matrix(1, length(states), length(states),
                       dimnames = list(states, states))
  diag(asymmetric) <- 0
  asymmetric[1L, 2L] <- 2
  expect_error(
    compute_sequence_distance(
      data,
      method = "optimal_matching",
      substitution_matrix = asymmetric
    ),
    "symmetric"
  )

  invalid_diagonal <- matrix(1, length(states), length(states),
                             dimnames = list(states, states))
  expect_error(
    compute_sequence_distance(
      data,
      method = "optimal_matching",
      substitution_matrix = invalid_diagonal
    ),
    "diagonal"
  )

  distance <- matrix(c(0, 1, 2, 0), 2L, 2L,
                     dimnames = list(c("a", "b"), c("a", "b")))
  expect_error(validate_sequence_clusters(c(a = 1L, b = 2L), distance),
               "symmetric")
})

test_that("CLARA is guarded and preserves sequence identifiers", {
  distance <- compute_sequence_distance(make_advanced_sequence_data())
  if (requireNamespace("cluster", quietly = TRUE)) {
    fit <- cluster_sequences(distance, 2L, method = "clara", seed = 19L,
                             samples = 3L)
    expect_s3_class(fit, "gp3_sequence_clustering")
    expect_setequal(names(fit$assignments), attr(distance, "Labels"))
  } else {
    expect_error(cluster_sequences(distance, 2L, method = "clara"),
                 "Optional package")
  }
})

test_that("stochastic helpers restore the caller random-number state", {
  distance <- compute_sequence_distance(make_advanced_sequence_data())
  set.seed(777L)
  before <- .Random.seed
  bootstrap_sequence_clusters(distance, 2L, n_boot = 3L,
                              sample_fraction = 0.75, seed = 9L)
  expect_identical(.Random.seed, before)
})

test_that("character cluster assignments are supported", {
  distance <- compute_sequence_distance(make_advanced_sequence_data())
  assignments <- setNames(rep(c("left", "right"), each = 4L),
                          attr(distance, "Labels"))
  validation <- validate_sequence_clusters(assignments, distance)
  expect_equal(validation$overall$n_clusters, 2L)
  expect_setequal(validation$cluster_sizes$cluster, c("left", "right"))
})

test_that("unused factor levels do not become observed distance states", {
  data <- make_advanced_sequence_data()
  data$state <- factor(data$state, levels = c("A", "B", "C", "D", "UNUSED"))
  states <- c("A", "B", "C", "D")
  costs <- matrix(1, 4L, 4L, dimnames = list(states, states))
  diag(costs) <- 0
  distance <- compute_sequence_distance(
    data,
    method = "optimal_matching",
    substitution_matrix = costs
  )
  expect_false("UNUSED" %in% attr(distance, "state_levels"))
})

test_that("ensemble linkage and stability summaries are validated", {
  data <- make_advanced_sequence_data()
  d1 <- compute_sequence_distance(data, method = "lcs")
  d2 <- compute_sequence_distance(data, method = "transition")
  c1 <- cluster_sequences(d1, 2L)
  c2 <- cluster_sequences(d2, 2L)
  expect_error(
    create_sequence_cluster_ensemble(c1, c2, k = 2L, linkage = "unknown"),
    "not a supported"
  )
  boot <- bootstrap_sequence_clusters(d1, 2L, n_boot = 2L,
                                      sample_fraction = 0.5, seed = 4L)
  summary <- summarise_sequence_cluster_stability(boot)
  expect_true("n_evaluated_pairs" %in% names(summary$clusters))
  expect_true(all(summary$clusters$n_evaluated_pairs >= 0L))
})

test_that("optional CLARA clustering restores the caller RNG and is repeatable", {
  if (requireNamespace("cluster", quietly = TRUE)) {
    distance <- compute_sequence_distance(make_advanced_sequence_data(), method = "lcs")
    set.seed(321L)
    before <- .Random.seed
    first <- cluster_sequences(distance, 2L, method = "clara", seed = 12L,
                               samples = 4L, sampsize = 6L)
    expect_identical(.Random.seed, before)
    second <- cluster_sequences(distance, 2L, method = "clara", seed = 12L,
                                samples = 4L, sampsize = 6L)
    expect_identical(first$assignments, second$assignments)
    expect_error(
      cluster_sequences(distance, 2L, method = "clara", rngR = FALSE),
      "rngR = TRUE"
    )
  } else {
    expect_error(
      cluster_sequences(
        compute_sequence_distance(make_advanced_sequence_data()),
        2L,
        method = "clara"
      ),
      "Optional package"
    )
  }
})

test_that("integer controls reject values outside the R integer range", {
  distance <- compute_sequence_distance(make_advanced_sequence_data())
  expect_error(
    cluster_sequences(distance, 2L, seed = .Machine$integer.max + 1),
    "invalid numeric"
  )
})

testthat::test_that("seed validation and bootstrap offsets are safe", {
  data <- make_advanced_sequence_data()
  distance <- compute_sequence_distance(data, method = "lcs")

  testthat::expect_error(
    cluster_sequences(distance, 2L, seed = -1L),
    "seed"
  )
  testthat::expect_silent(
    bootstrap_sequence_clusters(
      distance,
      k = 2L,
      n_boot = 1L,
      sample_fraction = 0.75,
      seed = .Machine$integer.max
    )
  )
})

test_that("additional clustering arguments must be named", {
  distance <- compute_sequence_distance(make_advanced_sequence_data())
  expect_error(
    cluster_sequences(distance, 2L, method = "hierarchical",
                      linkage = "average", seed = 1L, 1),
    "must be named"
  )
})
