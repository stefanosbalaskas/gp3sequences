options(warn = 2)
suppressPackageStartupMessages(library(gp3sequences))

stopifnot(utils::packageVersion("gp3sequences") >= "0.2.0.9000")

make_data <- function() {
  paths <- list(
    s01 = c("A", "B", "C", "D", "D"),
    s02 = c("A", "B", "C", "D", "C"),
    s03 = c("A", "B", "B", "C", "D"),
    s04 = c("A", "C", "C", "D", "D"),
    s05 = c("D", "C", "B", "A", "A"),
    s06 = c("D", "C", "B", "A", "B"),
    s07 = c("D", "C", "C", "B", "A"),
    s08 = c("D", "B", "B", "A", "A")
  )
  do.call(rbind, lapply(seq_along(paths), function(i) {
    data.frame(
      participant_id = paste0("p", i),
      sequence_id = names(paths)[i],
      sequence_order = seq_along(paths[[i]]),
      state = paths[[i]],
      group = rep(c("g1", "g2"), each = 4L)[i],
      condition_numeric = rep(c(0, 1), each = 4L)[i],
      time_scaled = seq(-1, 1, length.out = length(paths[[i]])),
      channel_context = c("x", "x", "y", "y", "z"),
      stringsAsFactors = FALSE
    )
  }))
}

data <- make_data()
panel_data <- rbind(
  transform(data, sequence_id = paste0(sequence_id, "_w1"), occasion = 1L),
  transform(data, sequence_id = paste0(sequence_id, "_w2"), occasion = 2L)
)
panel_data$state[panel_data$occasion == 2L & panel_data$sequence_order == 2L] <- "C"

panel <- prepare_sequence_panel(panel_data, "participant_id", "occasion")
panel_summary <- summarise_sequence_panel(panel)
panel_changes <- compare_sequence_panel_changes(panel)

sub_occ <- extract_sequence_subsequences(data, min_length = 2L, max_length = 3L,
                                         max_gap = 2L, max_span = 4L,
                                         metadata_cols = "group")
sub_summary <- summarise_sequence_subsequences(sub_occ)
sub_filtered <- filter_sequence_subsequences(sub_summary, min_sequences = 2L)
sub_compare <- compare_sequence_subsequences(sub_occ, group_col = "group",
                                             p_adjust = "holm")

multi <- fit_multichannel_sequence_hmm(
  data, n_states = 2L, channel_cols = c("state", "channel_context"),
  max_iter = 4L, seed = 20L
)
multi_decoded <- decode_multichannel_sequence_states(multi)
multi_summary <- summarise_multichannel_sequence_hmm(multi)

covariate <- fit_covariate_sequence_hmm(
  data, n_states = 2L,
  initial_covariate_cols = "condition_numeric",
  transition_covariate_cols = "condition_numeric",
  max_iter = 3L, inner_maxit = 10L, seed = 21L
)
covariate_prediction <- predict_covariate_transition_probabilities(
  covariate, data.frame(condition_numeric = c(0, 1))
)
covariate_decoded <- decode_covariate_sequence_states(covariate)
covariate_summary <- summarise_covariate_sequence_hmm(covariate)

design <- declare_sequence_comparison_design(
  group_col = "group", unit_col = "participant_id", design = "observational"
)
inference <- test_sequence_group_difference(
  data, design, metric = "state_prevalence", target_state = "A",
  n_permutations = 49L, seed = 22L
)
inference <- bootstrap_sequence_group_difference(inference, n_boot = 49L, seed = 23L)
inference_summary <- summarise_sequence_group_inference(inference)

distance <- compute_sequence_distance(data, method = "levenshtein")
clustering <- cluster_sequences(distance, k = 2L, method = "hierarchical")
network <- create_transition_network(data)

plot_file <- tempfile(fileext = ".pdf")
grDevices::pdf(plot_file)
plot_sequence_panel_changes(panel_changes)
plot_sequence_subsequences(sub_filtered)
plot_multichannel_sequence_hmm(multi, channel = "state")
plot_sequence_group_inference(inference)
plot_sequence_index(data)
plot_sequence_state_distribution(data)
plot_sequence_entropy(data)
plot_sequence_distance_heatmap(distance)
plot_transition_network(network)
plot_sequence_cluster_silhouette(clustering, distance)
grDevices::dev.off()
stopifnot(file.exists(plot_file))

if (requireNamespace("mgcv", quietly = TRUE)) {
  set.seed(202)
  time_participants <- paste0("tp", seq_len(24L))
  time_data <- do.call(
    rbind,
    lapply(seq_along(time_participants), function(i) {
      time <- seq_len(12L)
      group <- if (i <= 12L) "g1" else "g2"
      linear_predictor <-
        -0.4 +
        0.06 * time +
        0.35 * (group == "g2") * sin(time / 3)

      data.frame(
        participant_id = time_participants[i],
        sequence_id = time_participants[i],
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

  time_model <- fit_time_varying_sequence_model(
    time_data,
    group_col = "group",
    participant_id_col = "participant_id",
    target_state = "A",
    k = 4L,
    include_random_effect = FALSE
  )
  time_prediction <- predict_time_varying_sequence_model(time_model)
  time_summary <- summarise_time_varying_sequence_model(time_model)
  grDevices::pdf(tempfile(fileext = ".pdf"))
  plot_time_varying_sequence_model(time_model)
  grDevices::dev.off()
  stopifnot(nrow(time_prediction) > 0L, is.list(time_summary))
} else {
  message("OPTIONAL: mgcv unavailable; time-varying model branch dependency-guarded.")
}

stopifnot(
  inherits(panel, "gp3_sequence_panel"),
  is.list(panel_summary),
  inherits(panel_changes, "gp3_sequence_panel_changes"),
  inherits(sub_occ, "gp3_sequence_subsequences"),
  nrow(sub_summary) > 0L,
  is.data.frame(sub_compare),
  inherits(multi, "gp3_multichannel_sequence_hmm"),
  nrow(multi_decoded) == nrow(data),
  is.list(multi_summary),
  inherits(covariate, "gp3_covariate_sequence_hmm"),
  nrow(covariate_prediction) == 8L,
  nrow(covariate_decoded) == nrow(data),
  is.list(covariate_summary),
  inherits(inference, "gp3_sequence_group_inference"),
  is.list(inference_summary)
)

cat("ADVANCED EXTENSIONS SMOKE TEST: PASS\n")
