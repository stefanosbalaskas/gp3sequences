setwd("C:/Users/Stefanos-PC/Documents/Rstudio/gp3sequences")

required <- c(
  "paper/comparator-source-registry.csv",
  "paper/comparison-inventory.csv",
  "paper/comparator-classification-definitions.csv",
  "paper/feature-comparison-matrix.csv",
  "paper/results/manuscript-comparison-table.csv",
  "paper/manuscript/comparator-evidence.md"
)

missing <- required[!file.exists(required)]
stopifnot(length(missing) == 0L)

sources <- read.csv(
  "paper/comparator-source-registry.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

inventory <- read.csv(
  "paper/comparison-inventory.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

definitions <- read.csv(
  "paper/comparator-classification-definitions.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

matrix <- read.csv(
  "paper/feature-comparison-matrix.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

manuscript <- read.csv(
  "paper/results/manuscript-comparison-table.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

expected_packages <- c(
  "gp3sequences", "TraMineR", "seqHMM", "arulesSequences",
  "WeightedCluster", "ClickClust", "PST", "march"
)

expected_features <- c(
  "neutral_long_format_input",
  "explicit_preprocessing_policy",
  "state_sequence_summaries",
  "motif_or_pattern_mining",
  "bounded_noncontiguous_subsequences",
  "sequence_distances",
  "clustering",
  "cluster_stability",
  "transition_networks",
  "higher_order_markov",
  "categorical_hmm",
  "mixture_hmm",
  "multichannel_hmm",
  "covariate_hmm",
  "longitudinal_panel_workflow",
  "time_varying_models",
  "design_aware_inference",
  "machine_readable_diagnostics",
  "analysis_contracts",
  "provenance_comparison",
  "specialist_interoperability"
)

allowed <- c(
  "native", "native_specialist", "optional_adapter",
  "via_dependency", "partial", "not_documented", "outside_scope"
)

required_inventory_columns <- c(
  "package", "current_version", "availability_status",
  "status_note", "verification_status", "primary_source_ids",
  "verified_on"
)

stopifnot(
  setequal(sources$package, expected_packages),
  setequal(inventory$package, expected_packages),
  setequal(manuscript$Package, expected_packages),
  setequal(matrix$package, expected_packages),
  setequal(matrix$feature, expected_features),
  all(required_inventory_columns %in% names(inventory)),
  nrow(matrix) == length(expected_packages) * length(expected_features),
  !anyDuplicated(matrix[c("package", "feature")]),
  all(matrix$classification %in% allowed),
  setequal(definitions$classification, allowed),
  all(nzchar(matrix$source_ids)),
  all(nzchar(matrix$evidence_note)),
  all(nzchar(matrix$verified_on)),
  all(inventory$verification_status == "verified from primary sources"),
  !any(grepl("not yet assessed", matrix$classification, fixed = TRUE)),
  !any(grepl("not yet assessed", matrix$evidence_note, fixed = TRUE)),
  !file.exists("paper/feature-comparison-template.csv")
)

matrix_ids <- unique(
  unlist(strsplit(matrix$source_ids, ";", fixed = TRUE))
)
matrix_ids <- trimws(matrix_ids)

inventory_ids <- unique(
  unlist(strsplit(inventory$primary_source_ids, ";", fixed = TRUE))
)
inventory_ids <- trimws(inventory_ids)

stopifnot(
  all(matrix_ids %in% sources$source_id),
  all(inventory_ids %in% sources$source_id),
  !any(grepl("pst-manual", matrix$source_ids, fixed = TRUE)),
  "pst-archive" %in% sources$source_id
)

pst <- inventory[inventory$package == "PST", , drop = FALSE]
stopifnot(
  nrow(pst) == 1L,
  identical(pst$current_version, "0.94.1"),
  identical(pst$availability_status, "archived from CRAN"),
  grepl("2025-11-27", pst$status_note, fixed = TRUE)
)

seq_cov <- matrix[
  matrix$package == "seqHMM" & matrix$feature == "covariate_hmm",
  ,
  drop = FALSE
]

seq_time <- matrix[
  matrix$package == "seqHMM" & matrix$feature == "time_varying_models",
  ,
  drop = FALSE
]

stopifnot(
  nrow(seq_cov) == 1L,
  identical(seq_cov$classification, "native_specialist"),
  nrow(seq_time) == 1L,
  identical(seq_time$classification, "partial")
)

gp3 <- matrix[matrix$package == "gp3sequences", , drop = FALSE]
stopifnot(
  nrow(gp3) == length(expected_features),
  all(gp3$classification %in% c("native", "optional_adapter")),
  identical(
    gp3$classification[gp3$feature == "specialist_interoperability"],
    "optional_adapter"
  )
)

cat(
  "PASS: comparator matrix is complete, current, and evidence-backed.\n",
  "Packages: ", length(expected_packages), "\n",
  "Features: ", length(expected_features), "\n",
  "Cells: ", nrow(matrix), "\n",
  "Primary sources: ", nrow(sources), "\n",
  "Archived comparators: ",
  sum(inventory$availability_status == "archived from CRAN"),
  "\n",
  sep = ""
)
