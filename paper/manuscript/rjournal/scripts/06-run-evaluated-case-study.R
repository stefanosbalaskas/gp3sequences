find_repo_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (
      file.exists(file.path(current, "DESCRIPTION")) &&
      dir.exists(file.path(current, "paper"))
    ) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not locate the gp3sequences repository root.", call. = FALSE)
    }
    current <- parent
  }
}

write_csv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    x,
    path,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

round_numeric <- function(x, digits = 6L) {
  numeric_columns <- vapply(x, is.numeric, logical(1))
  x[numeric_columns] <- lapply(x[numeric_columns], round, digits = digits)
  x
}

canonical_text_extensions <- c(
  "csv", "txt", "r", "rmd", "md", "bib", "sty", "yml", "yaml", "tex"
)

canonical_content <- function(path) {
  size <- file.info(path)$size
  bytes <- readBin(path, what = "raw", n = size)
  extension <- tolower(tools::file_ext(path))

  if (extension %in% canonical_text_extensions) {
    text <- rawToChar(bytes)
    text <- gsub("\r\n?", "\n", text, perl = TRUE)
    bytes <- charToRaw(text)
  }

  bytes
}

canonical_size <- function(path) {
  length(canonical_content(path))
}

canonical_md5 <- function(path) {
  temporary <- tempfile("gp3sequences-canonical-")
  on.exit(unlink(temporary, force = TRUE), add = TRUE)
  writeBin(canonical_content(path), temporary)
  unname(tools::md5sum(temporary))
}

canonical_hash_policy <- function(path) {
  if (tolower(tools::file_ext(path)) %in% canonical_text_extensions) {
    "lf-normalized-text"
  } else {
    "raw-binary"
  }
}

root <- find_repo_root()
article_dir <- file.path(root, "paper", "manuscript", "rjournal")
data_dir <- file.path(article_dir, "data")
results_dir <- file.path(article_dir, "results", "case-study")
figures_dir <- file.path(article_dir, "figures", "case-study")

dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("devtools", quietly = TRUE)) {
  stop("Install devtools before running the evaluated case study.", call. = FALSE)
}

devtools::load_all(root, quiet = TRUE)

case_data <- utils::read.csv(
  file.path(data_dir, "case-study-sequences.csv"),
  stringsAsFactors = FALSE
)

# The inferential API requires the independent-unit column to remain
# distinct from the core sequence identifier. In this one-sequence-per-unit
# synthetic design, analysis_unit is an explicit metadata copy of sequence_id.
case_data$analysis_unit <- case_data$sequence_id

expected_states <- c("A", "B", "C", "D")

stopifnot(
  nrow(case_data) == 1728L,
  length(unique(case_data$sequence_id)) == 72L,
  setequal(unique(case_data$position), 1:24),
  setequal(unique(case_data$state), expected_states),
  setequal(unique(case_data$group), c("reference", "comparison")),
  identical(case_data$analysis_unit, case_data$sequence_id)
)

# 1. Validation and explicit preparation
validation <- validate_sequence_data(
  case_data,
  sequence_id_col = "sequence_id",
  order_col = "position",
  state_col = "state",
  metadata_cols = c("group", "channel", "weight", "analysis_unit"),
  expected_states = expected_states
)

validation_summary <- data.frame(
  status = validation$status,
  valid = validation$valid,
  n_rows = validation$n_rows,
  n_sequences = validation$n_sequences,
  n_states = length(validation$state_levels),
  n_errors = validation$n_errors,
  n_reviews = validation$n_reviews,
  n_info = validation$n_info,
  stringsAsFactors = FALSE
)

prepared <- prepare_sequence_data(
  case_data,
  sequence_id_col = "sequence_id",
  order_col = "position",
  state_col = "state",
  metadata_cols = c("group", "channel", "weight", "analysis_unit"),
  expected_states = expected_states,
  missing_state_policy = "error",
  duplicate_position_policy = "error",
  repeated_state_policy = "preserve",
  zero_duration_policy = "preserve",
  unknown_state_policy = "error",
  unused_state_levels = "drop"
)

stopifnot(
  !identical(prepared$status, "fail"),
  is.data.frame(prepared$data),
  nrow(prepared$data) == 1728L
)

prepared_data <- prepared$data

write_csv(validation_summary, file.path(results_dir, "validation-summary.csv"))
write_csv(validation$audit, file.path(results_dir, "validation-audit.csv"))
write_csv(prepared$decisions, file.path(results_dir, "preparation-decisions.csv"))
write_csv(prepared$mapping, file.path(results_dir, "preparation-mapping.csv"))

# 2. State and transition summaries
state_summary <- summarise_sequence_states(
  prepared_data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = "group",
  expected_states = expected_states
)

state_by_group <- stats::aggregate(
  n_observations ~ group + state,
  data = state_summary$by_sequence,
  FUN = sum
)

group_totals <- stats::aggregate(
  n_observations ~ group,
  data = state_by_group,
  FUN = sum
)
names(group_totals)[2L] <- "group_observations"
state_by_group <- merge(state_by_group, group_totals, by = "group", sort = FALSE)
state_by_group$observation_proportion <-
  state_by_group$n_observations / state_by_group$group_observations
state_by_group <- state_by_group[
  order(state_by_group$group, state_by_group$state, method = "radix"),
  ,
  drop = FALSE
]
row.names(state_by_group) <- NULL

transition_summary <- summarise_sequence_transitions(
  prepared_data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = "group",
  expected_states = expected_states,
  include_self = TRUE
)

transition_by_group <- stats::aggregate(
  n_transitions ~ group + from_state + to_state,
  data = transition_summary$by_sequence,
  FUN = sum
)

origin_totals <- stats::aggregate(
  n_transitions ~ group + from_state,
  data = transition_by_group,
  FUN = sum
)
names(origin_totals)[3L] <- "origin_total"
transition_by_group <- merge(
  transition_by_group,
  origin_totals,
  by = c("group", "from_state"),
  sort = FALSE
)
transition_by_group$origin_transition_proportion <-
  transition_by_group$n_transitions / transition_by_group$origin_total
transition_by_group <- transition_by_group[
  order(
    transition_by_group$group,
    transition_by_group$from_state,
    transition_by_group$to_state,
    method = "radix"
  ),
  ,
  drop = FALSE
]
row.names(transition_by_group) <- NULL

write_csv(
  round_numeric(state_by_group),
  file.path(results_dir, "state-summary-by-group.csv")
)
write_csv(
  round_numeric(transition_by_group),
  file.path(results_dir, "transition-summary-by-group.csv")
)

# 3. Contiguous motifs and bounded noncontiguous subsequences
motif_extraction <- extract_sequence_ngrams(
  prepared_data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = "group",
  expected_states = expected_states,
  min_length = 2L,
  max_length = 3L,
  overlap = "allow"
)

motif_summary <- summarise_sequence_motifs(motif_extraction)

motif_by_group <- stats::aggregate(
  n_occurrences ~ group + motif + motif_length,
  data = motif_summary$by_sequence,
  FUN = sum
)

motif_presence <- unique(
  motif_summary$by_sequence[c("group", "sequence_id", "motif", "motif_length")]
)
motif_sequence_count <- stats::aggregate(
  sequence_id ~ group + motif + motif_length,
  data = motif_presence,
  FUN = length
)
names(motif_sequence_count)[4L] <- "sequence_count"
motif_by_group <- merge(
  motif_by_group,
  motif_sequence_count,
  by = c("group", "motif", "motif_length"),
  sort = FALSE
)
motif_group_n <- table(unique(prepared_data[c("sequence_id", "group")])$group)
motif_by_group$sequence_prevalence <-
  motif_by_group$sequence_count / as.numeric(motif_group_n[motif_by_group$group])
motif_by_group <- motif_by_group[
  order(
    motif_by_group$group,
    -motif_by_group$sequence_prevalence,
    -motif_by_group$n_occurrences,
    motif_by_group$motif_length,
    motif_by_group$motif,
    method = "radix"
  ),
  ,
  drop = FALSE
]
row.names(motif_by_group) <- NULL

subsequence_occurrences <- extract_sequence_subsequences(
  prepared_data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = "group",
  min_length = 2L,
  max_length = 2L,
  max_gap = 1L,
  max_span = 3L,
  repeated_state_policy = "preserve",
  max_combinations_per_sequence = 100000L
)

# Subsequence occurrences retain sequence metadata as an attribute rather
# than repeating it in every occurrence row. Join the declared group once
# at sequence level before group-wise aggregation.
if (!("group" %in% names(subsequence_occurrences))) {
  subsequence_groups <- unique(
    prepared_data[c("sequence_id", "group")]
  )
  subsequence_occurrences <- merge(
    subsequence_occurrences,
    subsequence_groups,
    by = "sequence_id",
    all.x = TRUE,
    sort = FALSE
  )
}

stopifnot(
  "group" %in% names(subsequence_occurrences),
  !anyNA(subsequence_occurrences$group)
)

subsequence_by_group <- stats::aggregate(
  sequence_id ~ group + subsequence + subsequence_length,
  data = subsequence_occurrences,
  FUN = length
)
names(subsequence_by_group)[4L] <- "occurrence_count"

subsequence_presence <- unique(
  subsequence_occurrences[
    c("group", "sequence_id", "subsequence", "subsequence_length")
  ]
)
subsequence_sequence_count <- stats::aggregate(
  sequence_id ~ group + subsequence + subsequence_length,
  data = subsequence_presence,
  FUN = length
)
names(subsequence_sequence_count)[4L] <- "sequence_count"
subsequence_by_group <- merge(
  subsequence_by_group,
  subsequence_sequence_count,
  by = c("group", "subsequence", "subsequence_length"),
  sort = FALSE
)
subsequence_by_group$sequence_prevalence <-
  subsequence_by_group$sequence_count /
  as.numeric(motif_group_n[subsequence_by_group$group])
subsequence_by_group <- subsequence_by_group[
  order(
    subsequence_by_group$group,
    -subsequence_by_group$sequence_prevalence,
    -subsequence_by_group$occurrence_count,
    subsequence_by_group$subsequence,
    method = "radix"
  ),
  ,
  drop = FALSE
]
row.names(subsequence_by_group) <- NULL

write_csv(
  round_numeric(motif_by_group),
  file.path(results_dir, "motif-summary-by-group.csv")
)
write_csv(
  round_numeric(subsequence_by_group),
  file.path(results_dir, "subsequence-summary-by-group.csv")
)

# 4. Dissimilarity, clustering, and descriptive validation
distance <- compute_sequence_distance(
  prepared_data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  method = "levenshtein",
  normalise = "max_length"
)

distance_values <- as.numeric(distance)
distance_summary <- data.frame(
  n_sequences = attr(distance, "Size"),
  n_pairs = length(distance_values),
  minimum = min(distance_values),
  median = stats::median(distance_values),
  mean = mean(distance_values),
  maximum = max(distance_values),
  stringsAsFactors = FALSE
)

clustering <- cluster_sequences(
  distance,
  k = 2L,
  method = "hierarchical",
  linkage = "average",
  seed = 20260807L
)

cluster_validation <- validate_sequence_clusters(clustering)

cluster_assignments <- data.frame(
  sequence_id = names(clustering$assignments),
  cluster = as.character(clustering$assignments),
  stringsAsFactors = FALSE
)

sequence_groups <- unique(prepared_data[c("sequence_id", "group")])
cluster_assignments <- merge(
  cluster_assignments,
  sequence_groups,
  by = "sequence_id",
  sort = FALSE
)
cluster_assignments <- merge(
  cluster_assignments,
  cluster_validation$per_sequence[c("sequence_id", "silhouette")],
  by = "sequence_id",
  sort = FALSE
)
cluster_assignments <- cluster_assignments[
  order(cluster_assignments$cluster, cluster_assignments$sequence_id, method = "radix"),
  ,
  drop = FALSE
]
row.names(cluster_assignments) <- NULL

cluster_composition <- as.data.frame(
  table(cluster_assignments$cluster, cluster_assignments$group),
  stringsAsFactors = FALSE
)
names(cluster_composition) <- c("cluster", "group", "n_sequences")
cluster_composition <- cluster_composition[cluster_composition$n_sequences > 0L, ]
cluster_totals <- stats::aggregate(
  n_sequences ~ cluster,
  data = cluster_composition,
  FUN = sum
)
names(cluster_totals)[2L] <- "cluster_total"
cluster_composition <- merge(
  cluster_composition,
  cluster_totals,
  by = "cluster",
  sort = FALSE
)
cluster_composition$cluster_proportion <-
  cluster_composition$n_sequences / cluster_composition$cluster_total

write_csv(
  round_numeric(distance_summary),
  file.path(results_dir, "distance-summary.csv")
)
write_csv(
  round_numeric(cluster_validation$overall),
  file.path(results_dir, "cluster-validation.csv")
)
write_csv(
  round_numeric(cluster_validation$cluster_sizes),
  file.path(results_dir, "cluster-sizes.csv")
)
write_csv(
  round_numeric(cluster_assignments),
  file.path(results_dir, "cluster-assignments.csv")
)
write_csv(
  round_numeric(cluster_composition),
  file.path(results_dir, "cluster-composition.csv")
)

# 5. Transition networks and structural centrality
network_by_group <- create_transition_network(
  prepared_data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  group_cols = "group",
  order = 1L,
  include_self = TRUE,
  normalise = "from"
)

network_global <- create_transition_network(
  prepared_data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  order = 1L,
  include_self = TRUE,
  normalise = "from"
)

centrality <- summarise_transition_centrality(
  network_global,
  directed = TRUE
)

write_csv(
  round_numeric(as.data.frame(network_by_group)),
  file.path(results_dir, "transition-network-by-group.csv")
)
write_csv(
  round_numeric(centrality),
  file.path(results_dir, "transition-centrality.csv")
)

# 6. Declared observational group contrast
cat("Stage 6/8: declared observational group contrast.\n")
design <- declare_sequence_comparison_design(
  group_col = "group",
  unit_col = "analysis_unit",
  design = "observational"
)

inference <- test_sequence_group_difference(
  prepared_data,
  design = design,
  metric = "state_prevalence",
  target_state = "A",
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  n_permutations = 999L,
  alternative = "two.sided",
  seed = 20260807L
)

inference <- bootstrap_sequence_group_difference(
  inference,
  n_boot = 999L,
  level = 0.95,
  seed = 20260807L
)

inference_summary <- summarise_sequence_group_inference(inference)
inference_table <- cbind(
  inference_summary$estimate,
  inference_summary$bootstrap_interval[c("lower", "upper", "level", "n_boot")]
)
inference_table$interpretation <- inference_summary$interpretation

write_csv(
  round_numeric(inference_table),
  file.path(results_dir, "group-inference.csv")
)

# 7. Deterministic manuscript figures
state_plot <- reshape(
  state_by_group[c("group", "state", "observation_proportion")],
  idvar = "state",
  timevar = "group",
  direction = "wide"
)
state_plot <- state_plot[match(expected_states, state_plot$state), ]
state_matrix <- as.matrix(state_plot[setdiff(names(state_plot), "state")])
rownames(state_matrix) <- state_plot$state
colnames(state_matrix) <- sub("^observation_proportion\\.", "", colnames(state_matrix))

grDevices::png(
  file.path(figures_dir, "state-distribution-by-group.png"),
  width = 1800L,
  height = 1200L,
  res = 200L
)
graphics::barplot(
  t(state_matrix),
  beside = TRUE,
  ylim = c(0, 0.6),
  xlab = "State",
  ylab = "Observation proportion",
  main = "Synthetic state distributions by declared group",
  legend.text = colnames(state_matrix),
  args.legend = list(x = "topright", bty = "n")
)
grDevices::dev.off()

silhouette_order <- order(
  cluster_assignments$cluster,
  cluster_assignments$silhouette,
  method = "radix"
)

grDevices::png(
  file.path(figures_dir, "cluster-silhouette.png"),
  width = 1800L,
  height = 1200L,
  res = 200L
)
graphics::barplot(
  cluster_assignments$silhouette[silhouette_order],
  names.arg = rep("", nrow(cluster_assignments)),
  ylim = c(min(0, min(cluster_assignments$silhouette)), 1),
  xlab = "Sequences ordered by cluster",
  ylab = "Silhouette value",
  main = "Descriptive two-cluster validation"
)
graphics::abline(h = 0, lty = 2)
grDevices::dev.off()

inference_values <- inference$unit_data$metric
inference_groups <- as.character(inference$unit_data$group)

grDevices::png(
  file.path(figures_dir, "state-a-prevalence-by-group.png"),
  width = 1800L,
  height = 1200L,
  res = 200L
)
graphics::boxplot(
  inference_values ~ inference_groups,
  xlab = "Declared group",
  ylab = "Sequence-level prevalence of state A",
  main = "Observed synthetic group contrast"
)
grDevices::dev.off()

# 8. Freeze environment and provenance
session_lines <- capture.output(sessionInfo())
session_lines <- sub("[ 	]+$", "", session_lines, perl = TRUE)
writeLines(
  session_lines,
  file.path(results_dir, "session-info.txt"),
  useBytes = TRUE
)

description <- read.dcf(file.path(root, "DESCRIPTION"))
base_commit <- system2(
  "git",
  c("rev-parse", "HEAD"),
  stdout = TRUE,
  stderr = TRUE
)

output_files <- c(
  list.files(results_dir, full.names = TRUE, recursive = FALSE),
  list.files(figures_dir, full.names = TRUE, recursive = FALSE)
)
output_files <- output_files[file.info(output_files)$isdir %in% FALSE]
output_files <- output_files[basename(output_files) != "case-study-manifest.csv"]

relative_paths <- substring(
  normalizePath(output_files, winslash = "/", mustWork = TRUE),
  nchar(normalizePath(article_dir, winslash = "/", mustWork = TRUE)) + 2L
)

row_counts <- vapply(output_files, function(path) {
  if (grepl("\\.csv$", path, ignore.case = TRUE)) {
    nrow(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE))
  } else {
    NA_integer_
  }
}, integer(1))

manifest <- data.frame(
  output = relative_paths,
  type = ifelse(
    grepl("\\.csv$", output_files, ignore.case = TRUE),
    "table",
    ifelse(
      grepl("\\.png$", output_files, ignore.case = TRUE),
      "figure",
      "text"
    )
  ),
  rows = row_counts,
  bytes = vapply(output_files, canonical_size, numeric(1)),
  md5 = vapply(output_files, canonical_md5, character(1)),
  hash_policy = vapply(output_files, canonical_hash_policy, character(1)),
  package_version = as.character(description[1L, "Version"]),
  base_commit = base_commit[1L],
  analysis_script_md5 = canonical_md5(file.path(article_dir, "scripts", "06-run-evaluated-case-study.R")),
  analysis_seed = 20260807L,
  stringsAsFactors = FALSE
)
manifest <- manifest[order(manifest$output, method = "radix"), ]
row.names(manifest) <- NULL

write_csv(manifest, file.path(results_dir, "case-study-manifest.csv"))

stopifnot(
  validation$n_errors == 0L,
  validation$n_sequences == 72L,
  nrow(state_by_group) == 6L,
  nrow(cluster_assignments) == 72L,
  nrow(cluster_validation$overall) == 1L,
  nrow(inference_table) == 1L,
  inference_table$p_value <= 0.01,
  all(file.exists(file.path(figures_dir, c(
    "state-distribution-by-group.png",
    "cluster-silhouette.png",
    "state-a-prevalence-by-group.png"
  ))))
)

cat(
  "PASS: evaluated synthetic case study completed.\n",
  "Sequences: ", validation$n_sequences, "\n",
  "Rows: ", validation$n_rows, "\n",
  "State-summary rows: ", nrow(state_by_group), "\n",
  "Motif rows: ", nrow(motif_by_group), "\n",
  "Subsequence rows: ", nrow(subsequence_by_group), "\n",
  "Clusters: ", cluster_validation$overall$n_clusters, "\n",
  "Average silhouette: ",
  format(round(cluster_validation$overall$average_silhouette, 4L), nsmall = 4L),
  "\n",
  "Permutation p-value: ",
  format(round(inference_table$p_value, 4L), nsmall = 4L),
  "\n",
  "Interpretation: associational synthetic contrast only\n",
  sep = ""
)
