test_that("first-order transition networks contain auditable edge measures", {
  data <- make_advanced_sequence_data()
  network <- create_transition_network(data, normalise = "from")
  expect_s3_class(network, "gp3_transition_network")
  expect_true(all(c("from_state", "to_state", "count", "weight",
                    "sequence_count", "sequence_prevalence") %in% names(network)))
  sums <- tapply(network$weight, network$context, sum)
  expect_equal(as.numeric(sums), rep(1, length(sums)), tolerance = 1e-12)
  without_self <- create_transition_network(data, include_self = FALSE)
  expect_false(any(without_self$from_state == without_self$to_state))
})

test_that("higher-order networks and models use explicit contexts", {
  data <- make_advanced_sequence_data()
  network <- create_transition_network(data, order = 2L, normalise = "from")
  expect_true(all(is.na(network$from_state)))
  expect_true(all(grepl(" > ", network$context, fixed = TRUE)))
  model <- fit_higher_order_transition_model(data, order = 3L, smoothing = 0.5,
                                             backoff = TRUE)
  prediction <- predict_next_state(model, c("A", "B", "C"))
  expect_equal(sum(prediction$probability), 1, tolerance = 1e-12)
  expect_true(prediction$used_order[1L] <= 3L)
  unseen <- predict_next_state(model, c("Z"))
  expect_equal(unseen$used_order[1L], 0L)
})

test_that("centrality and communities are deterministic", {
  network <- create_transition_network(make_advanced_sequence_data(), normalise = "count")
  centrality <- summarise_transition_centrality(network)
  expect_true(all(c("state", "total_degree", "total_strength", "closeness",
                    "betweenness", "pagerank") %in% names(centrality)))
  expect_equal(sum(centrality$pagerank), 1, tolerance = 1e-8)
  first <- detect_transition_communities(network, seed = 9L)
  second <- detect_transition_communities(network, seed = 9L)
  expect_identical(first, second)
  components <- detect_transition_communities(network, method = "components")
  expect_equal(nrow(components), length(unique(c(network$from_state, network$to_state))))
})

test_that("network bootstrap is reproducible and bounded", {
  data <- make_advanced_sequence_data()
  first <- bootstrap_transition_network(data, n_boot = 10L, seed = 17L)
  second <- bootstrap_transition_network(data, n_boot = 10L, seed = 17L)
  expect_equal(first, second)
  expect_true(all(first$conf_low <= first$conf_high))
  expect_true(all(first$bootstrap_mean >= 0 & first$bootstrap_mean <= 1))
})

test_that("igraph conversion is optional", {
  network <- create_transition_network(make_advanced_sequence_data())
  if (requireNamespace("igraph", quietly = TRUE)) {
    graph <- as_igraph_transition_network(network)
    expect_true(inherits(graph, "igraph"))
  } else {
    expect_error(as_igraph_transition_network(network), "Optional package")
  }
})

test_that("graph summaries require one selected group", {
  grouped <- create_transition_network(
    make_advanced_sequence_data(),
    group_cols = "group"
  )
  expect_error(
    summarise_transition_centrality(grouped),
    "Filter a grouped transition network"
  )
  expect_error(
    detect_transition_communities(grouped),
    "Filter a grouped transition network"
  )
})

test_that("unseen higher-order contexts return a stable probability schema", {
  model <- fit_higher_order_transition_model(
    make_advanced_sequence_data(),
    order = 2L
  )
  unseen <- predict_next_state(model, "UNSEEN", top_n = 2L)
  expect_true(all(c("order", "context", "next_state", "count",
                    "probability", "used_order", "used_context") %in%
                  names(unseen)))
  expect_equal(unseen$used_order, rep(0L, nrow(unseen)))
  expect_equal(nrow(unseen), 2L)
})

test_that("network bootstrap restores the caller random-number state", {
  set.seed(901L)
  before <- .Random.seed
  bootstrap_transition_network(make_advanced_sequence_data(), n_boot = 3L,
                               seed = 8L)
  expect_identical(.Random.seed, before)
})

test_that("next-state history rejects blank states", {
  model <- fit_higher_order_transition_model(
    make_advanced_sequence_data(),
    order = 2L
  )
  expect_error(predict_next_state(model, c("A", "")), "non-blank")
})

test_that("network context labels require an unambiguous separator", {
  data <- make_advanced_sequence_data()
  data$state[data$state == "A"] <- "A > embedded"
  expect_error(
    create_transition_network(data),
    "must not occur inside"
  )
  expect_error(
    fit_higher_order_transition_model(data),
    "must not occur inside"
  )
})
