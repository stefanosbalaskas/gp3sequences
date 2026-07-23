stopifnot(requireNamespace("gp3sequences", quietly = TRUE))

library(gp3sequences)

expected_exports <- c(
  "create_consensus_sequence",
  "summarise_consensus_agreement",
  "format_consensus_sequence",
  "plot_consensus_sequence",
  "compare_sequence_groups",
  "plot_sequence_group_comparison",
  "compute_sequence_distance",
  "summarise_sequence_distance",
  "cluster_sequences",
  "validate_sequence_clusters",
  "extract_representative_sequences",
  "bootstrap_sequence_clusters",
  "summarise_sequence_cluster_stability",
  "create_sequence_cluster_ensemble",
  "create_transition_network",
  "summarise_transition_centrality",
  "detect_transition_communities",
  "fit_higher_order_transition_model",
  "predict_next_state",
  "bootstrap_transition_network",
  "fit_sequence_hmm",
  "fit_sequence_hmm_mixture",
  "decode_sequence_states",
  "summarise_sequence_hmm",
  "compare_sequence_hmms",
  "as_traminer_sequences",
  "as_arules_sequences",
  "as_grpstring_data",
  "as_seqhmm_sequences",
  "as_igraph_transition_network",
  "prepare_gp3tools_sequences"
)
stopifnot(all(vapply(expected_exports, exists, logical(1), mode = "function")))

paths <- list(
  s1 = c("A", "B", "C", "D"),
  s2 = c("A", "B", "C", "C"),
  s3 = c("A", "C", "C", "D"),
  s4 = c("D", "C", "B", "A"),
  s5 = c("D", "C", "A", "A"),
  s6 = c("D", "B", "B", "A")
)
sequence_data <- do.call(rbind, lapply(seq_along(paths), function(i) {
  data.frame(
    sequence_id = names(paths)[i],
    sequence_order = seq_along(paths[[i]]),
    state = paths[[i]],
    group = rep(c("g1", "g2"), each = 3L)[i],
    stringsAsFactors = FALSE
  )
}))

# Consensus and descriptive group comparisons.
consensus <- create_consensus_sequence(sequence_data, group_cols = "group")
stopifnot(inherits(consensus, "gp3_consensus_sequence"))
stopifnot(nrow(summarise_consensus_agreement(consensus, by = "group")) == 2L)
stopifnot(nrow(format_consensus_sequence(consensus)) == 2L)

comparison <- compare_sequence_groups(sequence_data, group_col = "group")
stopifnot(inherits(comparison, "gp3_sequence_group_comparison"))

plot_file <- tempfile(fileext = ".pdf")
grDevices::pdf(plot_file)
plot_consensus_sequence(consensus, group = "g1")
plot_consensus_sequence(consensus, type = "states", group = "g2")
plot_sequence_group_comparison(comparison, component = "state")
plot_sequence_group_comparison(comparison, component = "transition")
plot_sequence_group_comparison(comparison, component = "length")
grDevices::dev.off()
stopifnot(file.exists(plot_file), file.info(plot_file)$size > 0)

# All core distances, clustering, validation, representatives, stability,
# and co-association ensemble.
distances <- setNames(lapply(
  c("levenshtein", "lcs", "optimal_matching", "transition"),
  function(method) compute_sequence_distance(sequence_data, method = method)
), c("levenshtein", "lcs", "optimal_matching", "transition"))
stopifnot(all(vapply(distances, inherits, logical(1), "gp3_sequence_distance")))
stopifnot(nrow(summarise_sequence_distance(distances$lcs)$per_sequence) == 6L)

clustering_lcs <- cluster_sequences(distances$lcs, k = 2L)
clustering_transition <- cluster_sequences(distances$transition, k = 2L)
stopifnot(inherits(clustering_lcs, "gp3_sequence_clustering"))
stopifnot(validate_sequence_clusters(clustering_lcs)$overall$n_clusters == 2L)
stopifnot(nrow(extract_representative_sequences(clustering_lcs)) == 2L)

if (requireNamespace("cluster", quietly = TRUE)) {
  pam_fit <- cluster_sequences(distances$lcs, k = 2L, method = "pam", seed = 18L)
  clara_fit <- cluster_sequences(
    distances$lcs,
    k = 2L,
    method = "clara",
    seed = 18L,
    samples = 4L,
    sampsize = 5L
  )
  stopifnot(length(pam_fit$assignments) == 6L)
  stopifnot(length(clara_fit$assignments) == 6L)
}

stability <- bootstrap_sequence_clusters(
  distances$lcs,
  k = 2L,
  n_boot = 5L,
  sample_fraction = 0.8,
  seed = 101L
)
stopifnot(inherits(stability, "gp3_sequence_cluster_bootstrap"))
stopifnot(nrow(summarise_sequence_cluster_stability(stability)$clusters) == 2L)

ensemble <- create_sequence_cluster_ensemble(
  clustering_lcs,
  clustering_transition,
  k = 2L
)
stopifnot(inherits(ensemble, "gp3_sequence_cluster_ensemble"))

# Transition networks and higher-order prediction.
network <- create_transition_network(sequence_data, normalise = "from")
stopifnot(inherits(network, "gp3_transition_network"))
stopifnot(nrow(summarise_transition_centrality(network)) > 0L)
stopifnot(nrow(detect_transition_communities(network)) > 0L)
stopifnot(nrow(detect_transition_communities(network, method = "components")) > 0L)

higher_order <- fit_higher_order_transition_model(sequence_data, order = 2L)
next_state <- predict_next_state(higher_order, c("A", "B"))
stopifnot(abs(sum(next_state$probability) - 1) < 1e-8)

network_boot <- bootstrap_transition_network(sequence_data, n_boot = 5L, seed = 7L)
stopifnot(nrow(network_boot) > 0L)

# Single and mixture categorical HMMs.
hmm_1 <- fit_sequence_hmm(sequence_data, n_states = 1L, max_iter = 20L, seed = 14L)
hmm_2 <- fit_sequence_hmm(sequence_data, n_states = 2L, max_iter = 30L, seed = 15L)
stopifnot(inherits(hmm_2, "gp3_sequence_hmm"))
stopifnot(nrow(decode_sequence_states(hmm_2, method = "viterbi")) == nrow(sequence_data))
stopifnot(nrow(decode_sequence_states(hmm_2, method = "posterior")) == nrow(sequence_data))
stopifnot(nrow(summarise_sequence_hmm(hmm_2)$fit) == 1L)
stopifnot(nrow(compare_sequence_hmms(one = hmm_1, two = hmm_2)) == 2L)

mixture <- fit_sequence_hmm_mixture(
  sequence_data,
  n_components = 2L,
  n_states = 2L,
  max_iter = 20L,
  inner_initial_iter = 3L,
  seed = 16L
)
stopifnot(inherits(mixture, "gp3_sequence_hmm_mixture"))
stopifnot(nrow(mixture$responsibilities) == 6L)
stopifnot(nrow(decode_sequence_states(mixture)) == nrow(sequence_data))
stopifnot(nrow(summarise_sequence_hmm(mixture)$fit) == 1L)

# Dependency-free and optional ecosystem adapters.
grpstring_input <- as_grpstring_data(sequence_data)
stopifnot(inherits(grpstring_input, "gp3_grpstring_input"))
stopifnot(length(grpstring_input$strings) == 6L)

renamed <- sequence_data
names(renamed)[names(renamed) == "sequence_order"] <- "position"
names(renamed)[names(renamed) == "state"] <- "aoi_label"
prepared <- prepare_gp3tools_sequences(renamed, metadata_cols = "group")
stopifnot(is.list(prepared), is.data.frame(prepared$data))

if (requireNamespace("TraMineR", quietly = TRUE)) {
  stopifnot(inherits(as_traminer_sequences(sequence_data), "stslist"))
} else {
  stopifnot(inherits(try(as_traminer_sequences(sequence_data), silent = TRUE), "try-error"))
}

if (requireNamespace("TraMineR", quietly = TRUE) &&
    requireNamespace("seqHMM", quietly = TRUE)) {
  stopifnot(inherits(as_seqhmm_sequences(sequence_data), "stslist"))
} else {
  stopifnot(inherits(try(as_seqhmm_sequences(sequence_data), silent = TRUE), "try-error"))
}

if (requireNamespace("arules", quietly = TRUE) &&
    requireNamespace("arulesSequences", quietly = TRUE)) {
  transactions <- as_arules_sequences(sequence_data)
  info <- arules::transactionInfo(transactions)
  stopifnot(all(c("sequenceID", "eventID") %in% names(info)))
} else {
  stopifnot(inherits(try(as_arules_sequences(sequence_data), silent = TRUE), "try-error"))
}

if (requireNamespace("igraph", quietly = TRUE)) {
  stopifnot(inherits(as_igraph_transition_network(network), "igraph"))
} else {
  stopifnot(inherits(try(as_igraph_transition_network(network), silent = TRUE), "try-error"))
}

cat("ADVANCED ROADMAP SMOKE TEST: PASS\n")
cat("All 31 new public functions were exercised or dependency-guarded.\n")
