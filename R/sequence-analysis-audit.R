.sequence_package_version <- function() {
  description <- tryCatch(
    utils::packageDescription("gp3sequences"),
    error = function(e) NULL
  )

  if (
    is.list(description) &&
      !is.null(description$Version)
  ) {
    return(
      as.character(description$Version)
    )
  }

  if (file.exists("DESCRIPTION")) {
    description_file <- tryCatch(
      read.dcf("DESCRIPTION"),
      error = function(e) NULL
    )

    if (
      !is.null(description_file) &&
        "Version" %in% colnames(description_file)
    ) {
      return(
        as.character(
          description_file[1L, "Version"]
        )
      )
    }
  }

  NA_character_
}

.sequence_analysis_identifiers <- function(x) {
  ids <- attr(
    x,
    "sequence_ids",
    exact = TRUE
  )

  if (
    is.null(ids) &&
      is.list(x)
  ) {
    ids <- x$sequence_ids
  }

  if (
    is.null(ids) &&
      is.list(x) &&
      !is.null(x$assignments)
  ) {
    ids <- names(x$assignments)
  }

  if (
    is.null(ids) &&
      inherits(x, "dist")
  ) {
    ids <- attr(
      x,
      "Labels"
    )
  }

  if (
    is.null(ids) &&
      is.matrix(x)
  ) {
    ids <- rownames(x)
  }

  if (is.null(ids)) {
    return(character())
  }

  unique(
    as.character(ids)
  )
}

.sequence_analysis_state_levels <- function(x) {
  states <- attr(
    x,
    "state_levels",
    exact = TRUE
  )

  if (
    is.null(states) &&
      is.list(x)
  ) {
    states <- x$state_levels
  }

  if (
    is.null(states) &&
      is.list(x)
  ) {
    states <- x$symbol_names
  }

  if (is.null(states)) {
    return(character())
  }

  as.character(states)
}

.sequence_analysis_method <- function(x) {
  method <- attr(
    x,
    "method",
    exact = TRUE
  )

  if (
    is.null(method) &&
      is.list(x)
  ) {
    method <- x$method
  }

  if (
    is.null(method) &&
      inherits(x, "gp3_sequence_hmm")
  ) {
    method <- "categorical_hmm"
  }

  if (
    is.null(method) &&
      inherits(x, "gp3_transition_network")
  ) {
    method <- "transition_network"
  }

  if (is.null(method)) {
    return(NA_character_)
  }

  as.character(method)[1L]
}

.sequence_analysis_settings <- function(x) {
  settings <- attr(
    x,
    "settings",
    exact = TRUE
  )

  if (
    is.null(settings) &&
      is.list(x)
  ) {
    settings <- x$settings
  }

  if (
    is.null(settings) &&
      is.list(x)
  ) {
    candidates <- intersect(
      c(
        "k",
        "linkage",
        "seed",
        "order",
        "smoothing",
        "backoff",
        "tolerance",
        "pseudocount",
        "iterations",
        "converged"
      ),
      names(x)
    )

    if (length(candidates) > 0L) {
      settings <- x[candidates]
    }
  }

  if (is.null(settings)) {
    list()
  } else {
    settings
  }
}

.sequence_analysis_seed <- function(x) {
  provenance <- attr(
    x,
    "gp3sequences_provenance",
    exact = TRUE
  )

  if (
    is.list(provenance) &&
      !is.null(provenance$seed)
  ) {
    return(provenance$seed)
  }

  if (
    is.list(x) &&
      !is.null(x$seed)
  ) {
    return(x$seed)
  }

  NA_integer_
}

.sequence_analysis_provenance <- function(x) {
  provenance <- attr(
    x,
    "gp3sequences_provenance",
    exact = TRUE
  )

  if (is.null(provenance)) {
    provenance <- list()
  }

  if (is.null(provenance$package)) {
    provenance$package <- "gp3sequences"
  }

  if (is.null(provenance$package_version)) {
    provenance$package_version <- .sequence_package_version()
  }

  if (is.null(provenance$contract_version)) {
    provenance$contract_version <- .sequence_contract_version()
  }

  if (is.null(provenance$family)) {
    provenance$family <- .sequence_object_family(x)
  }

  if (is.null(provenance$method)) {
    provenance$method <- .sequence_analysis_method(x)
  }

  if (is.null(provenance$sequence_ids)) {
    provenance$sequence_ids <- .sequence_analysis_identifiers(x)
  }

  if (is.null(provenance$state_levels)) {
    provenance$state_levels <- .sequence_analysis_state_levels(x)
  }

  if (is.null(provenance$seed)) {
    provenance$seed <- .sequence_analysis_seed(x)
  }

  if (is.null(provenance$settings)) {
    provenance$settings <- .sequence_analysis_settings(x)
  }

  provenance
}

#' Audit a gp3sequences analysis object
#'
#' Inspects supported gp3sequences objects for structural contract validity,
#' recoverable provenance, identifiers, state levels, method settings, and
#' randomness metadata. The audit does not reinterpret sequence structure as a
#' psychological, diagnostic, cognitive, emotional, or causal construct.
#'
#' @param x A gp3sequences analysis result or supported structural object.
#' @param strict Logical; if `TRUE`, fail when the audit status is `"fail"`.
#' @param tolerance Numerical tolerance used for matrix/probability checks.
#'
#' @return An object of class `gp3_sequence_analysis_audit` containing
#' `summary`, `issues`, `provenance`, `contract`, and `status`.
#'
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3"), each = 3L),
#'   sequence_order = rep(1:3, times = 3L),
#'   state = c(
#'     "A", "B", "C",
#'     "A", "B", "B",
#'     "C", "B", "A"
#'   )
#' )
#' distance <- compute_sequence_distance(
#'   sequences,
#'   method = "levenshtein"
#' )
#' audit_sequence_analysis(distance)
#'
#' @export
audit_sequence_analysis <- function(
  x,
  strict = FALSE,
  tolerance = 1e-8
) {
  if (
    !is.logical(strict) ||
      length(strict) != 1L ||
      is.na(strict)
  ) {
    stop(
      "`strict` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  if (
    !is.numeric(tolerance) ||
      length(tolerance) != 1L ||
      is.na(tolerance) ||
      !is.finite(tolerance) ||
      tolerance <= 0
  ) {
    stop(
      "`tolerance` must be one positive finite number.",
      call. = FALSE
    )
  }

  contract <- .sequence_object_contract(x)
  issues <- .sequence_validate_sequence_result(
    x,
    tolerance = tolerance
  )
  provenance <- .sequence_analysis_provenance(x)

  if (
    length(provenance$sequence_ids) == 0L &&
      contract$family %in% c(
        "distance",
        "clustering",
        "cluster_bootstrap",
        "cluster_ensemble",
        "hmm",
        "hmm_mixture"
      )
  ) {
    issues <- .sequence_contract_bind_issues(
      issues,
      .sequence_contract_issue(
        "sequence_ids_not_recoverable",
        "review",
        "sequence_ids",
        paste0(
          "Sequence identifiers could not be recovered from this ",
          "analysis object."
        )
      )
    )
  }

  status <- .sequence_contract_status(issues)

  summary <- data.frame(
    family = contract$family,
    primary_class = contract$primary_class,
    package_version = as.character(
      provenance$package_version
    ),
    contract_version = as.character(
      provenance$contract_version
    ),
    method = if (
      is.null(provenance$method)
    ) {
      NA_character_
    } else {
      as.character(provenance$method)[1L]
    },
    n_sequence_ids = length(
      provenance$sequence_ids
    ),
    n_state_levels = length(
      provenance$state_levels
    ),
    seed_recorded = !is.null(provenance$seed) &&
      length(provenance$seed) == 1L &&
      !is.na(provenance$seed),
    n_issues = nrow(issues),
    status = status,
    stringsAsFactors = FALSE
  )

  result <- list(
    summary = summary,
    issues = issues,
    provenance = provenance,
    contract = contract,
    status = status
  )

  class(result) <- c(
    "gp3_sequence_analysis_audit",
    "list"
  )

  if (
    strict &&
      identical(status, "fail")
  ) {
    stop(
      "Sequence-analysis audit failed: ",
      paste(
        unique(
          issues$message[
            issues$severity == "error"
          ]
        ),
        collapse = " "
      ),
      call. = FALSE
    )
  }

  result
}

.sequence_comparison_row <- function(
  field,
  x,
  y,
  equal
) {
  data.frame(
    field = field,
    x = paste(x, collapse = " | "),
    y = paste(y, collapse = " | "),
    equal = isTRUE(equal),
    stringsAsFactors = FALSE
  )
}

#' Compare two gp3sequences analysis results
#'
#' Compares structural contracts and recoverable provenance from two analysis
#' objects. This helper is intended for regression checks, sensitivity analyses,
#' and reproducibility audits; it does not select a statistically or
#' substantively "best" analysis.
#'
#' @param x,y Two analysis objects.
#' @param tolerance Numerical comparison tolerance.
#' @param compare_values Logical; when `TRUE`, also run `all.equal()` on the
#' complete objects after structural comparison.
#'
#' @return An object of class `gp3_sequence_analysis_comparison` containing
#' per-field comparisons, both audits, optional whole-object comparison, and
#' an overall equality flag.
#'
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3"), each = 3L),
#'   sequence_order = rep(1:3, times = 3L),
#'   state = c(
#'     "A", "B", "C",
#'     "A", "B", "B",
#'     "C", "B", "A"
#'   )
#' )
#' d1 <- compute_sequence_distance(
#'   sequences,
#'   method = "levenshtein"
#' )
#' d2 <- compute_sequence_distance(
#'   sequences,
#'   method = "levenshtein"
#' )
#' compare_sequence_analysis_results(d1, d2)
#'
#' @export
compare_sequence_analysis_results <- function(
  x,
  y,
  tolerance = 1e-8,
  compare_values = FALSE
) {
  if (
    !is.numeric(tolerance) ||
      length(tolerance) != 1L ||
      is.na(tolerance) ||
      !is.finite(tolerance) ||
      tolerance <= 0
  ) {
    stop(
      "`tolerance` must be one positive finite number.",
      call. = FALSE
    )
  }

  if (
    !is.logical(compare_values) ||
      length(compare_values) != 1L ||
      is.na(compare_values)
  ) {
    stop(
      "`compare_values` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  x_audit <- audit_sequence_analysis(
    x,
    tolerance = tolerance
  )
  y_audit <- audit_sequence_analysis(
    y,
    tolerance = tolerance
  )

  x_provenance <- x_audit$provenance
  y_provenance <- y_audit$provenance

  comparisons <- do.call(
    rbind,
    list(
      .sequence_comparison_row(
        "family",
        x_audit$contract$family,
        y_audit$contract$family,
        identical(
          x_audit$contract$family,
          y_audit$contract$family
        )
      ),
      .sequence_comparison_row(
        "primary_class",
        x_audit$contract$primary_class,
        y_audit$contract$primary_class,
        identical(
          x_audit$contract$primary_class,
          y_audit$contract$primary_class
        )
      ),
      .sequence_comparison_row(
        "method",
        x_provenance$method,
        y_provenance$method,
        isTRUE(
          all.equal(
            x_provenance$method,
            y_provenance$method,
            tolerance = tolerance
          )
        )
      ),
      .sequence_comparison_row(
        "sequence_ids",
        x_provenance$sequence_ids,
        y_provenance$sequence_ids,
        identical(
          as.character(
            x_provenance$sequence_ids
          ),
          as.character(
            y_provenance$sequence_ids
          )
        )
      ),
      .sequence_comparison_row(
        "state_levels",
        x_provenance$state_levels,
        y_provenance$state_levels,
        identical(
          as.character(
            x_provenance$state_levels
          ),
          as.character(
            y_provenance$state_levels
          )
        )
      ),
      .sequence_comparison_row(
        "seed",
        x_provenance$seed,
        y_provenance$seed,
        isTRUE(
          all.equal(
            x_provenance$seed,
            y_provenance$seed,
            tolerance = tolerance
          )
        )
      ),
      .sequence_comparison_row(
        "settings",
        utils::capture.output(
          utils::str(
            x_provenance$settings,
            give.attr = FALSE
          )
        ),
        utils::capture.output(
          utils::str(
            y_provenance$settings,
            give.attr = FALSE
          )
        ),
        isTRUE(
          all.equal(
            x_provenance$settings,
            y_provenance$settings,
            tolerance = tolerance
          )
        )
      )
    )
  )

  row.names(comparisons) <- NULL

  value_comparison <- NULL

  if (compare_values) {
    value_comparison <- all.equal(
      x,
      y,
      tolerance = tolerance,
      check.attributes = TRUE
    )
  }

  result <- list(
    comparisons = comparisons,
    x_audit = x_audit,
    y_audit = y_audit,
    value_comparison = value_comparison,
    all_equal = all(comparisons$equal) &&
      (
        !compare_values ||
          isTRUE(value_comparison)
      )
  )

  class(result) <- c(
    "gp3_sequence_analysis_comparison",
    "list"
  )

  result
}
