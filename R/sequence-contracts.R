.sequence_contract_version <- function() {
  "0.3.0-contract-1"
}

.sequence_contract_issue_table <- function() {
  data.frame(
    code = character(),
    severity = character(),
    field = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

.sequence_contract_issue <- function(code, severity, field = NA_character_, message) {
  data.frame(
    code = as.character(code),
    severity = as.character(severity),
    field = as.character(field),
    message = as.character(message),
    stringsAsFactors = FALSE
  )
}

.sequence_contract_bind_issues <- function(...) {
  pieces <- Filter(
    function(x) is.data.frame(x) && nrow(x) > 0L,
    list(...)
  )

  if (length(pieces) == 0L) {
    return(.sequence_contract_issue_table())
  }

  out <- do.call(rbind, pieces)
  row.names(out) <- NULL
  severity_rank <- match(out$severity, c("error", "review", "info"))
  out <- out[
    order(severity_rank, out$code, out$field, method = "radix"),
    ,
    drop = FALSE
  ]
  row.names(out) <- NULL
  out
}

.sequence_contract_status <- function(issues) {
  if (nrow(issues) == 0L) {
    return("pass")
  }
  if (any(issues$severity == "error")) {
    return("fail")
  }
  if (any(issues$severity == "review")) {
    return("review")
  }
  "pass"
}

.sequence_check_optional_backend <- function(package) {
  if (
    !is.character(package) ||
      length(package) != 1L ||
      is.na(package) ||
      !nzchar(package)
  ) {
    stop(
      "`package` must be one non-missing package name.",
      call. = FALSE
    )
  }

  requireNamespace(package, quietly = TRUE)
}

.sequence_installed_version <- function(package) {
  if (!.sequence_check_optional_backend(package)) {
    return(NA_character_)
  }

  as.character(utils::packageVersion(package))
}

.sequence_check_seed <- function(seed, allow_null = TRUE) {
  if (allow_null && is.null(seed)) {
    return(invisible(NULL))
  }

  if (
    !is.numeric(seed) ||
      length(seed) != 1L ||
      is.na(seed) ||
      !is.finite(seed) ||
      seed < 0 ||
      seed != floor(seed) ||
      seed > .Machine$integer.max
  ) {
    stop(
      "`seed` must be one non-negative finite integer or `NULL`.",
      call. = FALSE
    )
  }

  invisible(as.integer(seed))
}

.sequence_check_probability_simplex <- function(x, tolerance = 1e-8) {
  if (
    !is.numeric(x) ||
      length(x) == 0L ||
      anyNA(x) ||
      any(!is.finite(x))
  ) {
    return(FALSE)
  }

  if (any(x < -tolerance) || any(x > 1 + tolerance)) {
    return(FALSE)
  }

  abs(sum(x) - 1) <= tolerance
}

.sequence_validate_probability_matrix <- function(
  x,
  tolerance = 1e-8,
  field = "probability_matrix"
) {
  issues <- .sequence_contract_issue_table()

  if (
    !is.matrix(x) ||
      !is.numeric(x) ||
      nrow(x) == 0L ||
      ncol(x) == 0L
  ) {
    return(
      .sequence_contract_issue(
        "invalid_probability_matrix",
        "error",
        field,
        "The probability object must be a non-empty numeric matrix."
      )
    )
  }

  if (anyNA(x) || any(!is.finite(x))) {
    issues <- .sequence_contract_bind_issues(
      issues,
      .sequence_contract_issue(
        "non_finite_probability",
        "error",
        field,
        "Probability matrices must contain only finite, non-missing values."
      )
    )
  }

  if (
    any(x < -tolerance, na.rm = TRUE) ||
      any(x > 1 + tolerance, na.rm = TRUE)
  ) {
    issues <- .sequence_contract_bind_issues(
      issues,
      .sequence_contract_issue(
        "probability_out_of_bounds",
        "error",
        field,
        "Probability entries must lie in [0, 1] within tolerance."
      )
    )
  }

  row_sums <- rowSums(x)
  if (any(abs(row_sums - 1) > tolerance, na.rm = TRUE)) {
    issues <- .sequence_contract_bind_issues(
      issues,
      .sequence_contract_issue(
        "probability_rows_not_normalised",
        "error",
        field,
        "Every probability row must sum to one within tolerance."
      )
    )
  }

  issues
}

.sequence_validate_distance_matrix <- function(x, tolerance = 1e-8) {
  matrix_x <- if (inherits(x, "dist")) {
    as.matrix(x)
  } else {
    x
  }

  if (
    !is.matrix(matrix_x) ||
      !is.numeric(matrix_x) ||
      nrow(matrix_x) == 0L ||
      nrow(matrix_x) != ncol(matrix_x)
  ) {
    return(
      .sequence_contract_issue(
        "invalid_distance_matrix",
        "error",
        "distance",
        paste0(
          "A distance result must be a non-empty numeric square matrix ",
          "or `dist` object."
        )
      )
    )
  }

  issues <- .sequence_contract_issue_table()

  if (anyNA(matrix_x) || any(!is.finite(matrix_x))) {
    issues <- .sequence_contract_bind_issues(
      issues,
      .sequence_contract_issue(
        "non_finite_distance",
        "error",
        "distance",
        "Distance matrices must contain finite, non-missing values."
      )
    )
  }

  if (any(matrix_x < -tolerance, na.rm = TRUE)) {
    issues <- .sequence_contract_bind_issues(
      issues,
      .sequence_contract_issue(
        "negative_distance",
        "error",
        "distance",
        "Distances must be non-negative within tolerance."
      )
    )
  }

  if (any(abs(diag(matrix_x)) > tolerance, na.rm = TRUE)) {
    issues <- .sequence_contract_bind_issues(
      issues,
      .sequence_contract_issue(
        "nonzero_distance_diagonal",
        "error",
        "distance",
        "The distance diagonal must be zero within tolerance."
      )
    )
  }

  symmetry_error <- max(abs(matrix_x - t(matrix_x)), na.rm = TRUE)
  if (is.finite(symmetry_error) && symmetry_error > tolerance) {
    issues <- .sequence_contract_bind_issues(
      issues,
      .sequence_contract_issue(
        "asymmetric_distance",
        "error",
        "distance",
        "The distance matrix must be symmetric within tolerance."
      )
    )
  }

  rn <- rownames(matrix_x)
  cn <- colnames(matrix_x)

  if (
    is.null(rn) ||
      is.null(cn) ||
      anyNA(rn) ||
      anyNA(cn) ||
      any(!nzchar(rn)) ||
      any(!nzchar(cn)) ||
      anyDuplicated(rn) ||
      anyDuplicated(cn) ||
      !identical(rn, cn)
  ) {
    issues <- .sequence_contract_bind_issues(
      issues,
      .sequence_contract_issue(
        "distance_identifiers_invalid",
        "review",
        "distance",
        paste0(
          "Distance row/column identifiers should be unique, non-missing, ",
          "and identical."
        )
      )
    )
  }

  issues
}

.sequence_validate_transition_matrix <- function(x, tolerance = 1e-8) {
  if (inherits(x, "gp3_transition_network")) {
    settings <- attr(x, "settings")
    issues <- .sequence_contract_issue_table()
    required <- c("context", "to_state", "count", "weight")
    missing <- setdiff(required, names(x))

    if (length(missing) > 0L) {
      return(
        .sequence_contract_issue(
          "transition_columns_missing",
          "error",
          "network",
          paste(
            "Missing transition-network columns:",
            paste(missing, collapse = ", ")
          )
        )
      )
    }

    if (
      anyNA(x$count) ||
        any(!is.finite(x$count)) ||
        any(x$count < 0)
    ) {
      issues <- .sequence_contract_bind_issues(
        issues,
        .sequence_contract_issue(
          "invalid_transition_counts",
          "error",
          "count",
          "Transition counts must be finite and non-negative."
        )
      )
    }

    if (
      anyNA(x$weight) ||
        any(!is.finite(x$weight)) ||
        any(x$weight < -tolerance)
    ) {
      issues <- .sequence_contract_bind_issues(
        issues,
        .sequence_contract_issue(
          "invalid_transition_weights",
          "error",
          "weight",
          "Transition weights must be finite and non-negative."
        )
      )
    }

    if (
      is.list(settings) &&
        identical(settings$normalise, "from") &&
        nrow(x) > 0L
    ) {
      group_key <- if ("group_key" %in% names(x)) {
        x$group_key
      } else {
        rep("", nrow(x))
      }
      key <- paste(group_key, x$context, sep = "\034")
      sums <- tapply(x$weight, key, sum)

      if (any(abs(sums - 1) > tolerance)) {
        issues <- .sequence_contract_bind_issues(
          issues,
          .sequence_contract_issue(
            "transition_rows_not_normalised",
            "error",
            "weight",
            paste0(
              "Outgoing transition weights must sum to one for ",
              "`normalise = \"from\"`."
            )
          )
        )
      }
    }

    return(issues)
  }

  .sequence_validate_probability_matrix(
    x,
    tolerance = tolerance,
    field = "transition"
  )
}

.sequence_validate_clustering_object <- function(x) {
  if (
    !inherits(
      x,
      c(
        "gp3_sequence_clustering",
        "gp3_sequence_cluster_ensemble"
      )
    )
  ) {
    return(
      .sequence_contract_issue(
        "unsupported_clustering_object",
        "error",
        "class",
        "The object is not a supported gp3sequences clustering result."
      )
    )
  }

  issues <- .sequence_contract_issue_table()
  assignments <- x$assignments

  if (
    is.null(assignments) ||
      length(assignments) == 0L ||
      anyNA(assignments) ||
      is.null(names(assignments)) ||
      anyNA(names(assignments)) ||
      any(!nzchar(names(assignments))) ||
      anyDuplicated(names(assignments))
  ) {
    issues <- .sequence_contract_bind_issues(
      issues,
      .sequence_contract_issue(
        "invalid_cluster_assignments",
        "error",
        "assignments",
        paste0(
          "Cluster assignments must be non-missing and uniquely named ",
          "by sequence ID."
        )
      )
    )
  }

  if (
    !is.null(x$k) &&
      length(assignments) > 0L &&
      length(unique(assignments)) != x$k
  ) {
    issues <- .sequence_contract_bind_issues(
      issues,
      .sequence_contract_issue(
        "cluster_count_mismatch",
        "review",
        "k",
        paste0(
          "The stored `k` does not match the number of observed ",
          "assignment labels."
        )
      )
    )
  }

  issues
}

.sequence_validate_hmm_object <- function(x, tolerance = 1e-8) {
  hmm_classes <- c(
    "gp3_sequence_hmm",
    "gp3_sequence_hmm_mixture",
    "gp3_multichannel_sequence_hmm",
    "gp3_covariate_sequence_hmm"
  )

  if (!inherits(x, hmm_classes)) {
    return(
      .sequence_contract_issue(
        "unsupported_hmm_object",
        "error",
        "class",
        "The object is not a supported gp3sequences HMM result."
      )
    )
  }

  issues <- .sequence_contract_issue_table()

  if (inherits(x, "gp3_sequence_hmm")) {
    if (!.sequence_check_probability_simplex(x$initial_probs, tolerance)) {
      issues <- .sequence_contract_bind_issues(
        issues,
        .sequence_contract_issue(
          "invalid_initial_probabilities",
          "error",
          "initial_probs",
          "Initial probabilities must form a probability simplex."
        )
      )
    }

    issues <- .sequence_contract_bind_issues(
      issues,
      .sequence_validate_probability_matrix(
        x$transition_probs,
        tolerance,
        "transition_probs"
      ),
      .sequence_validate_probability_matrix(
        x$emission_probs,
        tolerance,
        "emission_probs"
      )
    )

    if (!isTRUE(x$converged)) {
      issues <- .sequence_contract_bind_issues(
        issues,
        .sequence_contract_issue(
          "hmm_not_converged",
          "review",
          "converged",
          "The HMM did not report convergence."
        )
      )
    }
  }

  if (inherits(x, "gp3_sequence_hmm_mixture")) {
    if (
      !is.null(x$component_probs) &&
        !.sequence_check_probability_simplex(
          x$component_probs,
          tolerance
        )
    ) {
      issues <- .sequence_contract_bind_issues(
        issues,
        .sequence_contract_issue(
          "invalid_component_probabilities",
          "error",
          "component_probs",
          "Mixture probabilities must form a probability simplex."
        )
      )
    }

    if (!is.null(x$models)) {
      for (model in x$models) {
        issues <- .sequence_contract_bind_issues(
          issues,
          .sequence_validate_hmm_object(
            model,
            tolerance = tolerance
          )
        )
      }
    }

    if (!isTRUE(x$converged)) {
      issues <- .sequence_contract_bind_issues(
        issues,
        .sequence_contract_issue(
          "mixture_not_converged",
          "review",
          "converged",
          "The HMM mixture did not report convergence."
        )
      )
    }
  }

  # Multichannel/covariate models have family-specific structures.
  # The foundation layer checks common matrix fields only when they exist.
  for (
    field in intersect(
      c(
        "transition_probs",
        "transition",
        "emission_probs",
        "emission"
      ),
      names(x)
    )
  ) {
    value <- x[[field]]

    if (is.matrix(value) && is.numeric(value)) {
      issues <- .sequence_contract_bind_issues(
        issues,
        .sequence_validate_probability_matrix(
          value,
          tolerance = tolerance,
          field = field
        )
      )
    }
  }

  issues
}

.sequence_object_family <- function(x) {
  if (inherits(x, "gp3_sequence_distance")) {
    return("distance")
  }
  if (inherits(x, "gp3_sequence_clustering")) {
    return("clustering")
  }
  if (inherits(x, "gp3_sequence_cluster_bootstrap")) {
    return("cluster_bootstrap")
  }
  if (inherits(x, "gp3_sequence_cluster_ensemble")) {
    return("cluster_ensemble")
  }
  if (inherits(x, "gp3_transition_network")) {
    return("transition_network")
  }
  if (inherits(x, "gp3_higher_order_transition_model")) {
    return("higher_order_transition")
  }
  if (inherits(x, "gp3_sequence_hmm")) {
    return("hmm")
  }
  if (inherits(x, "gp3_sequence_hmm_mixture")) {
    return("hmm_mixture")
  }
  if (inherits(x, "gp3_multichannel_sequence_hmm")) {
    return("multichannel_hmm")
  }
  if (inherits(x, "gp3_covariate_sequence_hmm")) {
    return("covariate_hmm")
  }

  if (
    is.list(x) &&
      all(
        c(
          "data",
          "audit",
          "decisions",
          "mapping",
          "status"
        ) %in% names(x)
      )
  ) {
    return("prepared_sequence_data")
  }

  if (
    is.list(x) &&
      all(
        c(
          "valid",
          "status",
          "audit",
          "mapping"
        ) %in% names(x)
      )
  ) {
    return("sequence_validation")
  }

  "generic"
}

.sequence_object_contract <- function(x) {
  family <- .sequence_object_family(x)

  required_fields <- switch(
    family,
    distance = c(
      "method",
      "sequence_ids",
      "state_levels",
      "settings"
    ),
    clustering = c(
      "assignments",
      "k",
      "method",
      "distance",
      "seed"
    ),
    cluster_bootstrap = c(
      "original",
      "pairwise_stability"
    ),
    cluster_ensemble = c(
      "assignments",
      "coassociation",
      "source_assignments"
    ),
    transition_network = c(
      "context",
      "to_state",
      "count",
      "weight"
    ),
    higher_order_transition = c(
      "order",
      "tables",
      "state_levels"
    ),
    hmm = c(
      "initial_probs",
      "transition_probs",
      "emission_probs",
      "state_names",
      "symbol_names",
      "log_likelihood",
      "converged",
      "seed"
    ),
    hmm_mixture = c(
      "models",
      "responsibilities",
      "log_likelihood",
      "converged",
      "seed"
    ),
    prepared_sequence_data = c(
      "data",
      "audit",
      "decisions",
      "mapping",
      "status",
      "state_levels"
    ),
    sequence_validation = c(
      "valid",
      "status",
      "audit",
      "mapping",
      "state_levels"
    ),
    character()
  )

  list(
    contract_version = .sequence_contract_version(),
    family = family,
    primary_class = class(x)[1L],
    required_fields = required_fields
  )
}

.sequence_validate_sequence_result <- function(x, tolerance = 1e-8) {
  family <- .sequence_object_family(x)

  if (identical(family, "distance")) {
    return(
      .sequence_validate_distance_matrix(
        x,
        tolerance = tolerance
      )
    )
  }

  if (family %in% c("clustering", "cluster_ensemble")) {
    return(.sequence_validate_clustering_object(x))
  }

  if (identical(family, "transition_network")) {
    return(
      .sequence_validate_transition_matrix(
        x,
        tolerance = tolerance
      )
    )
  }

  if (
    family %in% c(
      "hmm",
      "hmm_mixture",
      "multichannel_hmm",
      "covariate_hmm"
    )
  ) {
    return(
      .sequence_validate_hmm_object(
        x,
        tolerance = tolerance
      )
    )
  }

  if (identical(family, "prepared_sequence_data")) {
    if (!x$status %in% c("pass", "review", "fail")) {
      return(
        .sequence_contract_issue(
          "invalid_preparation_status",
          "error",
          "status",
          paste0(
            "Prepared sequence data must use status ",
            "pass, review, or fail."
          )
        )
      )
    }

    return(.sequence_contract_issue_table())
  }

  if (identical(family, "sequence_validation")) {
    if (!x$status %in% c("pass", "review", "fail")) {
      return(
        .sequence_contract_issue(
          "invalid_validation_status",
          "error",
          "status",
          paste0(
            "Validation results must use status ",
            "pass, review, or fail."
          )
        )
      )
    }

    return(.sequence_contract_issue_table())
  }

  .sequence_contract_issue(
    "generic_object_contract",
    "review",
    "class",
    paste0(
      "No specialised gp3sequences contract is currently ",
      "registered for this object."
    )
  )
}

.sequence_record_provenance <- function(x, provenance = list()) {
  if (!is.list(provenance)) {
    stop("`provenance` must be a named list.", call. = FALSE)
  }

  if (
    length(provenance) > 0L &&
      (
        is.null(names(provenance)) ||
          any(!nzchar(names(provenance)))
      )
  ) {
    stop(
      "Every provenance field must be named.",
      call. = FALSE
    )
  }

  base <- attr(
    x,
    "gp3sequences_provenance",
    exact = TRUE
  )

  if (is.null(base)) {
    base <- list()
  }

  if (!is.list(base)) {
    base <- list(previous = base)
  }

  if (is.null(provenance$contract_version)) {
    provenance$contract_version <- .sequence_contract_version()
  }

  attr(x, "gp3sequences_provenance") <- utils::modifyList(
    base,
    provenance
  )

  x
}

.sequence_restore_sequence_metadata <- function(x, template) {
  for (
    field in c(
      "method",
      "sequence_ids",
      "state_levels",
      "settings",
      "gp3sequences_provenance"
    )
  ) {
    value <- attr(
      template,
      field,
      exact = TRUE
    )

    if (!is.null(value)) {
      attr(x, field) <- value
    }
  }

  x
}

.sequence_align_state_levels <- function(x, y) {
  x <- as.character(x)
  y <- as.character(y)

  if (
    anyNA(x) ||
      anyNA(y) ||
      any(!nzchar(x)) ||
      any(!nzchar(y))
  ) {
    stop(
      "State levels must be non-missing, non-empty values.",
      call. = FALSE
    )
  }

  unique(c(x, y))
}

.sequence_align_sequence_ids <- function(x, y) {
  x <- as.character(x)
  y <- as.character(y)

  if (
    anyNA(x) ||
      anyNA(y) ||
      any(!nzchar(x)) ||
      any(!nzchar(y)) ||
      anyDuplicated(x) ||
      anyDuplicated(y)
  ) {
    stop(
      "Sequence IDs must be unique, non-missing, and non-empty.",
      call. = FALSE
    )
  }

  if (!setequal(x, y)) {
    stop(
      "Sequence-ID sets do not match.",
      call. = FALSE
    )
  }

  x
}

.sequence_align_partition_labels <- function(assignments) {
  if (
    is.null(names(assignments)) ||
      anyNA(assignments) ||
      anyNA(names(assignments)) ||
      any(!nzchar(names(assignments))) ||
      anyDuplicated(names(assignments))
  ) {
    stop(
      "Assignments must be non-missing and uniquely named.",
      call. = FALSE
    )
  }

  labels <- unique(as.character(assignments))

  order_key <- vapply(
    labels,
    function(label) {
      min(
        names(assignments)[
          as.character(assignments) == label
        ]
      )
    },
    character(1)
  )

  ordered <- labels[
    order(order_key, labels, method = "radix")
  ]

  mapping <- stats::setNames(
    seq_along(ordered),
    ordered
  )

  stats::setNames(
    unname(mapping[as.character(assignments)]),
    names(assignments)
  )
}
