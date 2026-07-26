
namespace_lines <- readLines(
  "NAMESPACE",
  warn = FALSE,
  encoding = "UTF-8"
)

exports <- sub(
  "^export\\(([^)]+)\\)$",
  "\\1",
  grep(
    "^export\\(",
    namespace_lines,
    value = TRUE
  )
)

exports <- sort(
  unique(exports),
  method = "radix"
)

family_for <- function(fun) {
  if (
    fun %in% c(
      "sequence_capabilities",
      "audit_sequence_analysis",
      "compare_sequence_analysis_results"
    )
  ) {
    return("Analysis contracts and provenance")
  }

  if (grepl("hmm|hidden|covariate_transition_probabilities", fun)) {
    return("Hidden Markov models")
  }

  if (grepl("cluster|representative|distance", fun)) {
    return("Distances, clustering, and stability")
  }

  if (grepl("transition|network|next_state", fun)) {
    return("Transition networks and higher-order models")
  }

  if (grepl("subsequence", fun)) {
    return("Non-contiguous subsequences")
  }

  if (grepl("motif|ngram", fun)) {
    return("Contiguous motif analysis")
  }

  if (grepl("panel|time_varying", fun)) {
    return("Longitudinal and time-varying extensions")
  }

  if (grepl("group_inference|group_difference|comparison_design", fun)) {
    return("Design-aware inference")
  }

  if (grepl("^as_|^prepare_gp3tools", fun)) {
    return("Optional ecosystem adapters")
  }

  if (grepl("consensus|compare_sequence_groups|group_comparison", fun)) {
    return("Consensus and group comparisons")
  }

  if (grepl("^plot_", fun)) {
    return("Visualisations")
  }

  if (grepl(
    "validate_sequence_data|audit_sequence_data|prepare_sequence_data",
    fun
  )) {
    return("Sequence data contract")
  }

  "Encoding and structural summaries"
}

manual_exists <- vapply(
  exports,
  function(fun) {
    file.exists(
      file.path(
        "man",
        paste0(fun, ".Rd")
      )
    )
  },
  logical(1)
)

foundation <- exports %in% c(
  "sequence_capabilities",
  "audit_sequence_analysis",
  "compare_sequence_analysis_results"
)

ledger <- data.frame(
  "function" = exports,
  family = vapply(
    exports,
    family_for,
    character(1)
  ),
  api_status = ifelse(
    foundation,
    "new-foundation",
    "existing-needs-hardening"
  ),
  contract_tested = foundation,
  adversarial_tested = exports == "audit_sequence_analysis",
  reference_package = NA_character_,
  reference_function = NA_character_,
  reference_tested = FALSE,
  property_tested = FALSE,
  seed_tested = FALSE,
  plot_tested = FALSE,
  example_tested = FALSE,
  article = NA_character_,
  limitations_documented = FALSE,
  status = ifelse(
    foundation,
    "foundation-tested",
    "to-audit"
  ),
  notes = ifelse(
    manual_exists,
    paste0(
      "Manual page present; example execution evidence ",
      "recorded separately."
    ),
    "Manual page missing."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

dir.create(
  "inst/validation",
  recursive = TRUE,
  showWarnings = FALSE
)

utils::write.csv(
  ledger,
  "inst/validation/gp3sequences-validation.csv",
  row.names = FALSE,
  na = ""
)

cat(
  "Wrote ",
  nrow(ledger),
  " rows to inst/validation/gp3sequences-validation.csv\n",
  sep = ""
)
