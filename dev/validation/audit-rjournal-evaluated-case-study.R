setwd("C:/Users/Stefanos-PC/Documents/Rstudio/gp3sequences")

article_dir <- file.path("paper", "manuscript", "rjournal")
results_dir <- file.path(article_dir, "results", "case-study")
figures_dir <- file.path(article_dir, "figures", "case-study")

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

required <- c(
  file.path(article_dir, "scripts", "06-run-evaluated-case-study.R"),
  file.path(results_dir, c(
    "validation-summary.csv",
    "validation-audit.csv",
    "preparation-decisions.csv",
    "preparation-mapping.csv",
    "state-summary-by-group.csv",
    "transition-summary-by-group.csv",
    "motif-summary-by-group.csv",
    "subsequence-summary-by-group.csv",
    "distance-summary.csv",
    "cluster-validation.csv",
    "cluster-sizes.csv",
    "cluster-assignments.csv",
    "cluster-composition.csv",
    "transition-network-by-group.csv",
    "transition-centrality.csv",
    "group-inference.csv",
    "session-info.txt",
    "case-study-manifest.csv"
  )),
  file.path(figures_dir, c(
    "state-distribution-by-group.png",
    "cluster-silhouette.png",
    "state-a-prevalence-by-group.png"
  ))
)

missing <- required[!file.exists(required)]
stopifnot(length(missing) == 0L)

parse(
  file.path(article_dir, "scripts", "06-run-evaluated-case-study.R"),
  keep.source = TRUE
)

validation <- read.csv(
  file.path(results_dir, "validation-summary.csv"),
  stringsAsFactors = FALSE
)
states <- read.csv(
  file.path(results_dir, "state-summary-by-group.csv"),
  stringsAsFactors = FALSE
)
transitions <- read.csv(
  file.path(results_dir, "transition-summary-by-group.csv"),
  stringsAsFactors = FALSE
)
motifs <- read.csv(
  file.path(results_dir, "motif-summary-by-group.csv"),
  stringsAsFactors = FALSE
)
subsequences <- read.csv(
  file.path(results_dir, "subsequence-summary-by-group.csv"),
  stringsAsFactors = FALSE
)
cluster_validation <- read.csv(
  file.path(results_dir, "cluster-validation.csv"),
  stringsAsFactors = FALSE
)
cluster_assignments <- read.csv(
  file.path(results_dir, "cluster-assignments.csv"),
  stringsAsFactors = FALSE
)
cluster_composition <- read.csv(
  file.path(results_dir, "cluster-composition.csv"),
  stringsAsFactors = FALSE
)
inference <- read.csv(
  file.path(results_dir, "group-inference.csv"),
  stringsAsFactors = FALSE
)
manifest <- read.csv(
  file.path(results_dir, "case-study-manifest.csv"),
  stringsAsFactors = FALSE
)

session_snapshot <- readLines(
  file.path(results_dir, "session-info.txt"),
  warn = FALSE,
  encoding = "UTF-8"
)

stopifnot(
  length(session_snapshot) > 0L,
  !any(grepl("[ 	]+$", session_snapshot, perl = TRUE))
)

manifest_files <- file.path(article_dir, manifest$output)

stopifnot(all(file.exists(manifest_files)))

observed_sizes <- vapply(
  manifest_files,
  canonical_size,
  numeric(1)
)
observed_md5 <- vapply(
  manifest_files,
  canonical_md5,
  character(1)
)
observed_policy <- vapply(
  manifest_files,
  canonical_hash_policy,
  character(1)
)

analysis_script_path <- file.path(
  article_dir,
  "scripts",
  "06-run-evaluated-case-study.R"
)

stopifnot(
  identical(unname(observed_sizes), as.numeric(manifest$bytes)),
  identical(unname(observed_md5), manifest$md5),
  identical(unname(observed_policy), manifest$hash_policy),
  all(
    manifest$analysis_script_md5 ==
      canonical_md5(analysis_script_path)
  )
)

state_key <- paste(states$group, states$state, sep = "::")
state_lookup <- stats::setNames(states$observation_proportion, state_key)

stopifnot(
  nrow(validation) == 1L,
  validation$n_errors == 0L,
  validation$n_rows == 1728L,
  validation$n_sequences == 72L,
  nrow(states) == 6L,
  identical(unname(state_lookup[["comparison::A"]]), 0.5),
  identical(unname(state_lookup[["comparison::C"]]), 0.5),
  identical(unname(state_lookup[["reference::A"]]), 0.25),
  identical(unname(state_lookup[["reference::B"]]), 0.25),
  identical(unname(state_lookup[["reference::C"]]), 0.25),
  identical(unname(state_lookup[["reference::D"]]), 0.25),
  nrow(transitions) >= 8L,
  nrow(motifs) >= 8L,
  nrow(subsequences) >= 4L,
  nrow(cluster_validation) == 1L,
  cluster_validation$n_sequences == 72L,
  cluster_validation$n_clusters == 2L,
  nrow(cluster_assignments) == 72L,
  nrow(cluster_composition) >= 2L,
  nrow(inference) == 1L,
  inference$p_value <= 0.01,
  grepl("Associational", inference$interpretation, fixed = TRUE),
  nrow(manifest) >= 20L,
  all(nzchar(manifest$md5)),
  all(c(
    "base_commit",
    "analysis_script_md5",
    "hash_policy",
    "analysis_seed"
  ) %in% names(manifest)),
  length(unique(manifest$base_commit)) == 1L,
  length(unique(manifest$analysis_script_md5)) == 1L,
  all(nzchar(manifest$base_commit)),
  all(nzchar(manifest$analysis_script_md5)),
  all(manifest$analysis_seed == 20260807L),
  all(file.info(file.path(figures_dir, c(
    "state-distribution-by-group.png",
    "cluster-silhouette.png",
    "state-a-prevalence-by-group.png"
  )))$size > 1000L)
)

rmd <- readLines(
  file.path(article_dir, "gp3sequences.Rmd"),
  warn = FALSE,
  encoding = "UTF-8"
)

required_headings <- c(
  "## Validation and explicit preparation",
  "## State and transition structure",
  "## Recurring motifs and bounded subsequences",
  "## Dissimilarity and descriptive clustering",
  "## Transition network and declared group contrast",
  "## Reproducibility and interpretation boundary"
)

stopifnot(
  all(required_headings %in% rmd),
  !any(rmd == "## Planned package analysis"),
  any(grepl("results/case-study/group-inference.csv", rmd, fixed = TRUE)),
  any(grepl("figures/case-study/cluster-silhouette.png", rmd, fixed = TRUE))
)

git_status <- system2(
  "git",
  c("status", "--porcelain=v1", "-uall"),
  stdout = TRUE,
  stderr = TRUE
)

status_paths <- if (length(git_status) > 0L) {
  trimws(sub("^..", "", git_status))
} else {
  character()
}

stopifnot(!any(grepl(
  "^(R/|man/|tests/|NAMESPACE$|DESCRIPTION$)",
  status_paths
)))

cat(
  "PASS: evaluated R Journal case study is complete and frozen.\n",
  "Sequences: ", validation$n_sequences, "\n",
  "Rows: ", validation$n_rows, "\n",
  "State rows: ", nrow(states), "\n",
  "Transition rows: ", nrow(transitions), "\n",
  "Motif rows: ", nrow(motifs), "\n",
  "Subsequence rows: ", nrow(subsequences), "\n",
  "Clusters: ", cluster_validation$n_clusters, "\n",
  "Average silhouette: ", cluster_validation$average_silhouette, "\n",
  "Permutation p-value: ", inference$p_value, "\n",
  "Frozen outputs: ", nrow(manifest), "\n",
  "Public API changes: none\n",
  sep = ""
)
