.sequence_assert_column_argument <- function(
    value,
    argument,
    allow_null = FALSE
) {
  if (allow_null && is.null(value)) {
    return(invisible(NULL))
  }

  if (
    !is.character(value) ||
    length(value) != 1L ||
    is.na(value) ||
    !nzchar(value)
  ) {
    stop(
      "`",
      argument,
      "` must be a single non-missing column name.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.sequence_assert_character_vector <- function(
    value,
    argument,
    allow_null = TRUE
) {
  if (allow_null && is.null(value)) {
    return(invisible(NULL))
  }

  if (
    !is.character(value) ||
    anyNA(value) ||
    any(!nzchar(value)) ||
    anyDuplicated(value)
  ) {
    stop(
      "`",
      argument,
      "` must contain unique, non-missing character values.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.sequence_missing_value <- function(value) {
  missing <- is.na(value)

  if (is.character(value) || is.factor(value)) {
    missing <- missing | trimws(as.character(value)) == ""
  }

  missing
}

.sequence_value_text <- function(value) {
  if (length(value) == 0L) {
    return(NA_character_)
  }

  value <- as.character(value)
  value[is.na(value)] <- "<NA>"

  paste(utils::head(value, 5L), collapse = " | ")
}

.sequence_empty_audit <- function() {
  data.frame(
    sequence_id = character(),
    row = integer(),
    column = character(),
    issue_code = character(),
    severity = character(),
    value = character(),
    message = character(),
    action = character(),
    stringsAsFactors = FALSE
  )
}

.sequence_issue_row <- function(
    sequence_id = NA_character_,
    row = NA_integer_,
    column = NA_character_,
    issue_code,
    severity,
    value = NA_character_,
    message,
    action
) {
  data.frame(
    sequence_id = as.character(sequence_id),
    row = as.integer(row),
    column = as.character(column),
    issue_code = as.character(issue_code),
    severity = as.character(severity),
    value = as.character(value),
    message = as.character(message),
    action = as.character(action),
    stringsAsFactors = FALSE
  )
}

.sequence_sort_audit <- function(audit) {
  if (nrow(audit) == 0L) {
    return(.sequence_empty_audit())
  }

  severity_rank <- match(
    audit$severity,
    c("error", "review", "info")
  )

  sequence_sort <- audit$sequence_id
  sequence_sort[is.na(sequence_sort)] <- "\U10FFFF"

  row_sort <- audit$row
  row_sort[is.na(row_sort)] <- .Machine$integer.max

  audit <- audit[
    order(
      severity_rank,
      sequence_sort,
      row_sort,
      audit$issue_code,
      method = "radix"
    ),
    ,
    drop = FALSE
  ]

  row.names(audit) <- NULL
  audit
}

.sequence_status <- function(audit) {
  if (any(audit$severity == "error")) {
    return("fail")
  }

  if (any(audit$severity == "review")) {
    return("review")
  }

  "pass"
}

.sequence_mapping <- function(
    sequence_id_col,
    order_col,
    state_col,
    duration_col = NULL,
    metadata_cols = NULL
) {
  roles <- c(
    "sequence_id",
    "sequence_order",
    "state"
  )

  columns <- c(
    sequence_id_col,
    order_col,
    state_col
  )

  if (!is.null(duration_col)) {
    roles <- c(roles, "duration")
    columns <- c(columns, duration_col)
  }

  if (length(metadata_cols) > 0L) {
    roles <- c(
      roles,
      paste0("metadata:", metadata_cols)
    )
    columns <- c(columns, metadata_cols)
  }

  data.frame(
    role = roles,
    source_column = columns,
    stringsAsFactors = FALSE
  )
}

.sequence_stage_audit <- function(audit, stage) {
  if (nrow(audit) == 0L) {
    return(
      data.frame(
        stage = character(),
        .sequence_empty_audit(),
        stringsAsFactors = FALSE
      )
    )
  }

  data.frame(
    stage = rep(stage, nrow(audit)),
    audit,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.sequence_empty_decisions <- function() {
  data.frame(
    step = character(),
    policy = character(),
    affected_rows = integer(),
    details = character(),
    stringsAsFactors = FALSE
  )
}

.sequence_prepare_result <- function(
    data,
    audit,
    decisions,
    mapping,
    status,
    original_n_rows,
    prepared_n_rows,
    state_levels
) {
  list(
    data = data,
    audit = audit,
    decisions = decisions,
    mapping = mapping,
    status = status,
    original_n_rows = as.integer(original_n_rows),
    prepared_n_rows = as.integer(prepared_n_rows),
    state_levels = as.character(state_levels)
  )
}

#' Audit Long-Format Sequence Data
#'
#' Examines a long-format data frame against the neutral `gp3sequences`
#' sequence-data contract without modifying the input.
#'
#' @param data A data frame containing ordered state observations.
#' @param sequence_id_col Name of the sequence identifier column.
#' @param order_col Name of the numeric sequence-order column.
#' @param state_col Name of the categorical state column.
#' @param duration_col Optional name of a numeric duration column.
#' @param metadata_cols Optional character vector naming columns that should
#'   remain constant within each sequence.
#' @param expected_states Optional vector of known or permitted state values.
#'
#' @return A data frame with one row per detected issue and the stable columns
#'   `sequence_id`, `row`, `column`, `issue_code`, `severity`, `value`,
#'   `message`, and `action`. Severity values are `error`, `review`, and
#'   `info`.
#'
#' @details
#' The audit checks column mappings, empty inputs, missing identifiers,
#' missing or non-numeric order values, duplicated positions, integer order
#' gaps, unordered rows, missing states, consecutive repeated states,
#' single-row sequences, invalid durations, inconsistent metadata, unexpected
#' states, and unused factor levels.
#'
#' The function reports structural properties only. It does not infer
#' psychological, cognitive, emotional, or diagnostic states.
#'
#' @examples
#' sequences <- data.frame(
#'   id = rep(c("s1", "s2"), each = 3L),
#'   position = rep(1:3, times = 2L),
#'   state = c("home", "search", "product", "home", "category", "product")
#' )
#'
#' audit_sequence_data(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state"
#' )
#'
#' @export
audit_sequence_data <- function(
    data,
    sequence_id_col,
    order_col,
    state_col,
    duration_col = NULL,
    metadata_cols = NULL,
    expected_states = NULL
) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  .sequence_assert_column_argument(
    sequence_id_col,
    "sequence_id_col"
  )
  .sequence_assert_column_argument(order_col, "order_col")
  .sequence_assert_column_argument(state_col, "state_col")
  .sequence_assert_column_argument(
    duration_col,
    "duration_col",
    allow_null = TRUE
  )
  .sequence_assert_character_vector(
    metadata_cols,
    "metadata_cols"
  )

  if (!is.null(expected_states) && !is.atomic(expected_states)) {
    stop(
      "`expected_states` must be an atomic vector or `NULL`.",
      call. = FALSE
    )
  }

  mapped_core <- c(
    sequence_id_col,
    order_col,
    state_col,
    duration_col
  )
  mapped_core <- mapped_core[!is.na(mapped_core)]

  if (anyDuplicated(mapped_core)) {
    stop(
      "Required column mappings must refer to distinct columns.",
      call. = FALSE
    )
  }

  if (
    length(metadata_cols) > 0L &&
    any(metadata_cols %in% mapped_core)
  ) {
    stop(
      "`metadata_cols` must not repeat required mapped columns.",
      call. = FALSE
    )
  }

  issues <- list()

  add_issue <- function(...) {
    issues[[length(issues) + 1L]] <<- .sequence_issue_row(...)
    invisible(NULL)
  }

  if (anyDuplicated(names(data))) {
    add_issue(
      issue_code = "duplicate_column_names",
      severity = "error",
      value = .sequence_value_text(
        names(data)[duplicated(names(data))]
      ),
      message = "The data frame contains duplicated column names.",
      action = "Rename duplicated columns before validation."
    )

    return(.sequence_sort_audit(do.call(rbind, issues)))
  }

  required_mapping <- c(
    sequence_id = sequence_id_col,
    sequence_order = order_col,
    state = state_col
  )

  if (!is.null(duration_col)) {
    required_mapping <- c(
      required_mapping,
      duration = duration_col
    )
  }

  missing_required <- required_mapping[
    !required_mapping %in% names(data)
  ]

  for (role in names(missing_required)) {
    add_issue(
      column = missing_required[[role]],
      issue_code = "missing_required_column",
      severity = "error",
      value = missing_required[[role]],
      message = paste0(
        "The mapped ",
        role,
        " column is absent from `data`."
      ),
      action = "Correct the column mapping or add the required column."
    )
  }

  missing_metadata <- setdiff(metadata_cols, names(data))

  for (column in missing_metadata) {
    add_issue(
      column = column,
      issue_code = "missing_metadata_column",
      severity = "error",
      value = column,
      message = "A requested metadata column is absent from `data`.",
      action = "Correct `metadata_cols` or add the metadata column."
    )
  }

  core_columns_present <- all(
    c(sequence_id_col, order_col, state_col) %in% names(data)
  )

  if (!core_columns_present) {
    return(.sequence_sort_audit(do.call(rbind, issues)))
  }

  if (nrow(data) == 0L) {
    add_issue(
      issue_code = "empty_data",
      severity = "error",
      message = "The input contains no sequence rows.",
      action = "Provide at least one ordered state observation."
    )

    return(.sequence_sort_audit(do.call(rbind, issues)))
  }

  sequence_values <- data[[sequence_id_col]]
  order_values <- data[[order_col]]
  state_values <- data[[state_col]]

  valid_sequence_type <- !is.list(sequence_values)
  valid_state_type <- !is.list(state_values)
  valid_order_type <- is.numeric(order_values)

  if (!valid_sequence_type) {
    add_issue(
      column = sequence_id_col,
      issue_code = "invalid_sequence_id_type",
      severity = "error",
      message = "Sequence identifiers must use an atomic vector.",
      action = "Convert sequence identifiers to character, factor, or numeric."
    )
  }

  if (!valid_state_type) {
    add_issue(
      column = state_col,
      issue_code = "invalid_state_type",
      severity = "error",
      message = "States must use an atomic vector.",
      action = "Convert states to character, factor, or numeric."
    )
  }

  if (!valid_order_type) {
    add_issue(
      column = order_col,
      issue_code = "invalid_order_type",
      severity = "error",
      message = "Sequence order must be numeric.",
      action = "Convert the order column to finite numeric positions."
    )
  }

  if (!valid_sequence_type || !valid_state_type) {
    return(.sequence_sort_audit(do.call(rbind, issues)))
  }

  sequence_missing <- .sequence_missing_value(sequence_values)
  state_missing <- .sequence_missing_value(state_values)

  sequence_text <- as.character(sequence_values)
  state_text <- as.character(state_values)

  for (row in which(sequence_missing)) {
    add_issue(
      row = row,
      column = sequence_id_col,
      issue_code = "missing_sequence_id",
      severity = "error",
      value = .sequence_value_text(sequence_values[row]),
      message = "The row has no usable sequence identifier.",
      action = "Supply a sequence identifier or remove the row explicitly."
    )
  }

  for (row in which(state_missing)) {
    add_issue(
      sequence_id = sequence_text[row],
      row = row,
      column = state_col,
      issue_code = "missing_state",
      severity = "error",
      value = .sequence_value_text(state_values[row]),
      message = "The row has no usable state value.",
      action = "Supply a state or apply an explicit missing-state policy."
    )
  }

  order_missing <- rep(TRUE, nrow(data))
  order_finite <- rep(FALSE, nrow(data))

  if (valid_order_type) {
    order_missing <- is.na(order_values)
    order_finite <- is.finite(order_values)

    for (row in which(order_missing)) {
      add_issue(
        sequence_id = sequence_text[row],
        row = row,
        column = order_col,
        issue_code = "missing_sequence_order",
        severity = "error",
        value = .sequence_value_text(order_values[row]),
        message = "The row has no sequence-order value.",
        action = "Supply the order explicitly; order is never inferred."
      )
    }

    for (row in which(!order_missing & !order_finite)) {
      add_issue(
        sequence_id = sequence_text[row],
        row = row,
        column = order_col,
        issue_code = "non_finite_order",
        severity = "error",
        value = .sequence_value_text(order_values[row]),
        message = "The sequence-order value is not finite.",
        action = "Replace infinite or non-finite order values."
      )
    }
  }

  valid_sequence_rows <- which(!sequence_missing)

  if (valid_order_type) {
    valid_order_rows <- which(
      !sequence_missing &
        !order_missing &
        order_finite
    )

    if (length(valid_order_rows) > 0L) {
      order_key <- format(
        order_values[valid_order_rows],
        digits = 17L,
        scientific = FALSE,
        trim = TRUE
      )

      keys <- paste(
        sequence_text[valid_order_rows],
        order_key,
        sep = "\034"
      )

      duplicate_local <- duplicated(keys) |
        duplicated(keys, fromLast = TRUE)

      duplicate_rows <- valid_order_rows[duplicate_local]

      for (row in duplicate_rows) {
        add_issue(
          sequence_id = sequence_text[row],
          row = row,
          column = order_col,
          issue_code = "duplicated_position",
          severity = "error",
          value = .sequence_value_text(order_values[row]),
          message = "The sequence contains a duplicated position.",
          action = paste0(
            "Correct the position or apply an explicit first/last policy."
          )
        )
      }

      groups <- split(
        valid_order_rows,
        sequence_text[valid_order_rows],
        drop = TRUE
      )

      for (sequence_id in names(groups)) {
        rows <- groups[[sequence_id]]
        current_order <- order_values[rows]

        if (is.unsorted(current_order, strictly = FALSE)) {
          add_issue(
            sequence_id = sequence_id,
            row = rows[1L],
            column = order_col,
            issue_code = "unordered_rows",
            severity = "review",
            value = .sequence_value_text(current_order),
            message = "Rows are not ordered within the sequence.",
            action = "Sort deterministically by sequence and order."
          )
        }

        unique_order <- sort(unique(current_order))

        integer_like <- all(
          abs(unique_order - round(unique_order)) <
            sqrt(.Machine$double.eps)
        )

        if (integer_like && length(unique_order) > 1L) {
          gap_index <- which(diff(unique_order) > 1)

          if (length(gap_index) > 0L) {
            gap_text <- paste(
              paste0(
                unique_order[gap_index],
                "->",
                unique_order[gap_index + 1L]
              ),
              collapse = ", "
            )

            add_issue(
              sequence_id = sequence_id,
              row = rows[1L],
              column = order_col,
              issue_code = "missing_positions",
              severity = "review",
              value = gap_text,
              message = "The sequence has gaps between integer positions.",
              action = "Confirm that omitted positions are intentional."
            )
          }
        }

        ordered_rows <- rows[
          order(order_values[rows], rows, method = "radix")
        ]

        ordered_states <- state_text[ordered_rows]
        ordered_missing <- state_missing[ordered_rows]

        repeated <- rep(FALSE, length(ordered_rows))

        if (length(ordered_rows) > 1L) {
          repeated[-1L] <- !ordered_missing[-1L] &
            !ordered_missing[-length(ordered_missing)] &
            ordered_states[-1L] ==
            ordered_states[-length(ordered_states)]
        }

        for (row in ordered_rows[repeated]) {
          add_issue(
            sequence_id = sequence_text[row],
            row = row,
            column = state_col,
            issue_code = "consecutive_repeated_state",
            severity = "review",
            value = .sequence_value_text(state_values[row]),
            message = "The state repeats consecutively within the sequence.",
            action = "Preserve or collapse repeats through an explicit policy."
          )
        }
      }
    }
  }

  if (length(valid_sequence_rows) > 0L) {
    sequence_groups <- split(
      valid_sequence_rows,
      sequence_text[valid_sequence_rows],
      drop = TRUE
    )

    for (sequence_id in names(sequence_groups)) {
      rows <- sequence_groups[[sequence_id]]
      usable_state_rows <- rows[!state_missing[rows]]

      if (length(usable_state_rows) == 1L) {
        add_issue(
          sequence_id = sequence_id,
          row = usable_state_rows,
          column = state_col,
          issue_code = "single_state_sequence",
          severity = "review",
          value = .sequence_value_text(
            state_values[usable_state_rows]
          ),
          message = "The sequence contains only one usable state row.",
          action = "Confirm that single-state sequences are admissible."
        )
      }
    }
  }

  if (!is.null(duration_col) && duration_col %in% names(data)) {
    duration_values <- data[[duration_col]]

    if (!is.numeric(duration_values)) {
      add_issue(
        column = duration_col,
        issue_code = "invalid_duration_type",
        severity = "error",
        message = "Duration must be numeric.",
        action = "Convert duration to a numeric scale."
      )
    } else {
      duration_missing <- is.na(duration_values)

      for (row in which(duration_missing)) {
        add_issue(
          sequence_id = sequence_text[row],
          row = row,
          column = duration_col,
          issue_code = "missing_duration",
          severity = "review",
          value = .sequence_value_text(duration_values[row]),
          message = "The row has no duration value.",
          action = "Confirm whether missing duration is admissible."
        )
      }

      for (row in which(
        !duration_missing & !is.finite(duration_values)
      )) {
        add_issue(
          sequence_id = sequence_text[row],
          row = row,
          column = duration_col,
          issue_code = "non_finite_duration",
          severity = "error",
          value = .sequence_value_text(duration_values[row]),
          message = "The duration value is not finite.",
          action = "Replace infinite or non-finite durations."
        )
      }

      for (row in which(
        !duration_missing &
        is.finite(duration_values) &
        duration_values < 0
      )) {
        add_issue(
          sequence_id = sequence_text[row],
          row = row,
          column = duration_col,
          issue_code = "negative_duration",
          severity = "error",
          value = .sequence_value_text(duration_values[row]),
          message = "The duration value is negative.",
          action = "Correct or explicitly exclude the row."
        )
      }

      for (row in which(
        !duration_missing &
        is.finite(duration_values) &
        duration_values == 0
      )) {
        add_issue(
          sequence_id = sequence_text[row],
          row = row,
          column = duration_col,
          issue_code = "zero_duration",
          severity = "review",
          value = "0",
          message = "The duration value is zero.",
          action = "Preserve, drop, or reject zero duration explicitly."
        )
      }
    }
  }

  available_metadata <- intersect(metadata_cols, names(data))

  for (column in available_metadata) {
    metadata_values <- data[[column]]

    if (is.list(metadata_values)) {
      add_issue(
        column = column,
        issue_code = "invalid_metadata_type",
        severity = "error",
        message = "Metadata columns must use atomic vectors.",
        action = "Convert list-columns before sequence preparation."
      )

      next
    }

    if (length(valid_sequence_rows) == 0L) {
      next
    }

    groups <- split(
      valid_sequence_rows,
      sequence_text[valid_sequence_rows],
      drop = TRUE
    )

    for (sequence_id in names(groups)) {
      rows <- groups[[sequence_id]]
      values <- metadata_values[rows]
      values <- unique(as.character(values[!is.na(values)]))

      if (length(values) > 1L) {
        add_issue(
          sequence_id = sequence_id,
          row = rows[1L],
          column = column,
          issue_code = "inconsistent_metadata",
          severity = "error",
          value = .sequence_value_text(values),
          message = paste0(
            "Metadata column `",
            column,
            "` varies within the sequence."
          ),
          action = "Correct the metadata or redefine the sequence identifier."
        )
      }
    }
  }

  if (!is.null(expected_states)) {
    expected_text <- unique(as.character(expected_states))

    unknown_rows <- which(
      !state_missing &
        !(state_text %in% expected_text)
    )

    for (row in unknown_rows) {
      add_issue(
        sequence_id = sequence_text[row],
        row = row,
        column = state_col,
        issue_code = "unknown_state",
        severity = "review",
        value = .sequence_value_text(state_values[row]),
        message = "The state is absent from `expected_states`.",
        action = "Preserve, drop, or reject unknown states explicitly."
      )
    }
  }

  if (is.factor(state_values)) {
    observed_levels <- unique(
      as.character(state_values[!state_missing])
    )

    unused_levels <- setdiff(
      levels(state_values),
      observed_levels
    )

    if (length(unused_levels) > 0L) {
      add_issue(
        column = state_col,
        issue_code = "unused_state_levels",
        severity = "info",
        value = .sequence_value_text(unused_levels),
        message = "The factor contains unused state levels.",
        action = "Preserve or drop unused levels explicitly."
      )
    }
  }

  if (length(issues) == 0L) {
    return(.sequence_empty_audit())
  }

  .sequence_sort_audit(do.call(rbind, issues))
}

#' Validate Long-Format Sequence Data
#'
#' Produces a compact validation result based on
#' `audit_sequence_data()` without modifying the input.
#'
#' @inheritParams audit_sequence_data
#'
#' @return A named list containing `valid`, `status`, issue counts, the
#'   complete `audit` table, the column `mapping`, row and sequence counts,
#'   and observed `state_levels`. A result is valid when no error-severity
#'   issue is present. Review-severity issues do not automatically invalidate
#'   the input.
#'
#' @examples
#' sequences <- data.frame(
#'   id = rep(c("s1", "s2"), each = 2L),
#'   position = rep(1:2, times = 2L),
#'   state = c("home", "search", "home", "product")
#' )
#'
#' validation <- validate_sequence_data(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state"
#' )
#'
#' validation$status
#' validation$valid
#'
#' @export
validate_sequence_data <- function(
    data,
    sequence_id_col,
    order_col,
    state_col,
    duration_col = NULL,
    metadata_cols = NULL,
    expected_states = NULL
) {
  audit <- audit_sequence_data(
    data = data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    duration_col = duration_col,
    metadata_cols = metadata_cols,
    expected_states = expected_states
  )

  issue_levels <- c("error", "review", "info")

  counts <- vapply(
    issue_levels,
    function(level) {
      as.integer(sum(audit$severity == level))
    },
    integer(1)
  )

  sequence_count <- 0L

  if (
    sequence_id_col %in% names(data) &&
    !is.list(data[[sequence_id_col]])
  ) {
    identifiers <- data[[sequence_id_col]]
    usable <- !.sequence_missing_value(identifiers)

    sequence_count <- length(
      unique(as.character(identifiers[usable]))
    )
  }

  state_levels <- character()

  if (
    state_col %in% names(data) &&
    !is.list(data[[state_col]])
  ) {
    states <- data[[state_col]]
    usable <- !.sequence_missing_value(states)

    state_levels <- if (is.factor(states)) {
      levels(states)
    } else {
      unique(as.character(states[usable]))
    }
  }

  status <- .sequence_status(audit)

  list(
    valid = identical(status, "pass") ||
      identical(status, "review"),
    status = status,
    n_errors = unname(counts[["error"]]),
    n_reviews = unname(counts[["review"]]),
    n_info = unname(counts[["info"]]),
    audit = audit,
    mapping = .sequence_mapping(
      sequence_id_col = sequence_id_col,
      order_col = order_col,
      state_col = state_col,
      duration_col = duration_col,
      metadata_cols = metadata_cols
    ),
    n_rows = as.integer(nrow(data)),
    n_sequences = as.integer(sequence_count),
    state_levels = as.character(state_levels)
  )
}

#' Prepare Long-Format Sequence Data
#'
#' Applies explicit preprocessing policies and returns a deterministic,
#' canonical long-format representation.
#'
#' @inheritParams audit_sequence_data
#' @param missing_state_policy Policy for missing states: `"error"` or
#'   `"drop"`.
#' @param duplicate_position_policy Policy for duplicated sequence positions:
#'   `"error"`, `"first"`, or `"last"`.
#' @param repeated_state_policy Policy for consecutive repeated states:
#'   `"preserve"` or `"collapse"`.
#' @param zero_duration_policy Policy for zero durations: `"preserve"`,
#'   `"drop"`, or `"error"`.
#' @param unknown_state_policy Policy for states absent from
#'   `expected_states`: `"preserve"`, `"drop"`, or `"error"`.
#' @param unused_state_levels Policy for unused factor levels: `"preserve"`
#'   or `"drop"`.
#'
#' @return A named list containing:
#'
#' * `data`: canonical prepared data, or `NULL` when unresolved errors remain;
#' * `audit`: input- and output-stage diagnostics;
#' * `decisions`: a machine-readable preprocessing decision log;
#' * `mapping`: source-to-contract column mappings;
#' * `status`: `pass`, `review`, or `fail`;
#' * row counts and final state levels.
#'
#' The canonical columns are `sequence_id`, `sequence_order`, `state`,
#' `original_row`, and optional `duration`. Unmapped columns are preserved.
#'
#' @details
#' Rows are sorted deterministically by sequence identifier, sequence order,
#' and original row number. When consecutive repeats are collapsed, the first
#' row supplies non-duration values and available durations are summed.
#'
#' Unresolved errors produce `status = "fail"` and `data = NULL`; diagnostics
#' and decision records remain available.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c("s2", "s1", "s1", "s2"),
#'   position = c(2, 2, 1, 1),
#'   state = c("product", "search", "home", "home")
#' )
#'
#' prepared <- prepare_sequence_data(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state"
#' )
#'
#' prepared$status
#' prepared$data
#'
#' @export
prepare_sequence_data <- function(
    data,
    sequence_id_col,
    order_col,
    state_col,
    duration_col = NULL,
    metadata_cols = NULL,
    expected_states = NULL,
    missing_state_policy = c("error", "drop"),
    duplicate_position_policy = c("error", "first", "last"),
    repeated_state_policy = c("preserve", "collapse"),
    zero_duration_policy = c("preserve", "drop", "error"),
    unknown_state_policy = c("preserve", "drop", "error"),
    unused_state_levels = c("preserve", "drop")
) {
  missing_state_policy <- match.arg(missing_state_policy)
  duplicate_position_policy <- match.arg(
    duplicate_position_policy
  )
  repeated_state_policy <- match.arg(repeated_state_policy)
  zero_duration_policy <- match.arg(zero_duration_policy)
  unknown_state_policy <- match.arg(unknown_state_policy)
  unused_state_levels <- match.arg(unused_state_levels)

  initial_validation <- validate_sequence_data(
    data = data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    duration_col = duration_col,
    metadata_cols = metadata_cols,
    expected_states = expected_states
  )

  mapping <- initial_validation$mapping
  input_audit <- .sequence_stage_audit(
    initial_validation$audit,
    "input"
  )

  fatal_codes <- c(
    "duplicate_column_names",
    "empty_data",
    "missing_required_column",
    "missing_metadata_column",
    "invalid_sequence_id_type",
    "invalid_state_type",
    "invalid_order_type",
    "missing_sequence_id",
    "missing_sequence_order",
    "non_finite_order",
    "invalid_duration_type",
    "negative_duration",
    "non_finite_duration",
    "invalid_metadata_type",
    "inconsistent_metadata"
  )

  fatal_input <- initial_validation$audit$issue_code %in%
    fatal_codes

  if (any(fatal_input)) {
    return(
      .sequence_prepare_result(
        data = NULL,
        audit = input_audit,
        decisions = .sequence_empty_decisions(),
        mapping = mapping,
        status = "fail",
        original_n_rows = nrow(data),
        prepared_n_rows = 0L,
        state_levels = character()
      )
    )
  }

  working <- data
  working$.gp3_original_row <- seq_len(nrow(working))

  decision_rows <- list()

  add_decision <- function(
    step,
    policy,
    affected_rows,
    details
  ) {
    decision_rows[[length(decision_rows) + 1L]] <<- data.frame(
      step = step,
      policy = policy,
      affected_rows = as.integer(affected_rows),
      details = details,
      stringsAsFactors = FALSE
    )

    invisible(NULL)
  }

  state_missing <- .sequence_missing_value(
    working[[state_col]]
  )

  if (missing_state_policy == "drop") {
    affected <- sum(state_missing)
    working <- working[!state_missing, , drop = FALSE]

    add_decision(
      step = "missing_states",
      policy = "drop",
      affected_rows = affected,
      details = "Rows with missing or blank states were removed."
    )
  } else {
    add_decision(
      step = "missing_states",
      policy = "error",
      affected_rows = sum(state_missing),
      details = "Missing states were retained as unresolved errors."
    )
  }

  unknown_rows <- rep(FALSE, nrow(working))

  if (!is.null(expected_states) && nrow(working) > 0L) {
    expected_text <- unique(as.character(expected_states))
    state_text <- as.character(working[[state_col]])

    unknown_rows <- !.sequence_missing_value(
      working[[state_col]]
    ) & !(state_text %in% expected_text)
  }

  if (unknown_state_policy == "drop") {
    affected <- sum(unknown_rows)
    working <- working[!unknown_rows, , drop = FALSE]

    add_decision(
      step = "unknown_states",
      policy = "drop",
      affected_rows = affected,
      details = "States absent from `expected_states` were removed."
    )
  } else {
    add_decision(
      step = "unknown_states",
      policy = unknown_state_policy,
      affected_rows = sum(unknown_rows),
      details = paste0(
        "Unknown states were ",
        if (unknown_state_policy == "error") {
          "retained as unresolved errors."
        } else {
          "preserved for review."
        }
      )
    )
  }

  zero_duration <- rep(FALSE, nrow(working))

  if (!is.null(duration_col) && nrow(working) > 0L) {
    duration <- working[[duration_col]]
    zero_duration <- !is.na(duration) &
      is.finite(duration) &
      duration == 0
  }

  if (zero_duration_policy == "drop") {
    affected <- sum(zero_duration)
    working <- working[!zero_duration, , drop = FALSE]

    add_decision(
      step = "zero_durations",
      policy = "drop",
      affected_rows = affected,
      details = "Rows with zero duration were removed."
    )
  } else {
    add_decision(
      step = "zero_durations",
      policy = zero_duration_policy,
      affected_rows = sum(zero_duration),
      details = paste0(
        "Zero-duration rows were ",
        if (zero_duration_policy == "error") {
          "retained as unresolved errors."
        } else {
          "preserved."
        }
      )
    )
  }

  duplicate_rows <- rep(FALSE, nrow(working))

  if (nrow(working) > 0L) {
    sequence_text <- as.character(
      working[[sequence_id_col]]
    )

    order_key <- format(
      working[[order_col]],
      digits = 17L,
      scientific = FALSE,
      trim = TRUE
    )

    keys <- paste(sequence_text, order_key, sep = "\034")

    duplicate_rows <- if (
      duplicate_position_policy == "last"
    ) {
      duplicated(keys, fromLast = TRUE)
    } else {
      duplicated(keys)
    }
  }

  if (duplicate_position_policy %in% c("first", "last")) {
    affected <- sum(duplicate_rows)
    working <- working[!duplicate_rows, , drop = FALSE]

    add_decision(
      step = "duplicated_positions",
      policy = duplicate_position_policy,
      affected_rows = affected,
      details = paste0(
        "Duplicated positions were resolved by retaining the ",
        duplicate_position_policy,
        " occurrence."
      )
    )
  } else {
    duplicate_count <- if (nrow(working) == 0L) {
      0L
    } else {
      sequence_text <- as.character(
        working[[sequence_id_col]]
      )

      order_key <- format(
        working[[order_col]],
        digits = 17L,
        scientific = FALSE,
        trim = TRUE
      )

      keys <- paste(sequence_text, order_key, sep = "\034")

      sum(
        duplicated(keys) |
          duplicated(keys, fromLast = TRUE)
      )
    }

    add_decision(
      step = "duplicated_positions",
      policy = "error",
      affected_rows = duplicate_count,
      details = "Duplicated positions were retained as unresolved errors."
    )
  }

  if (nrow(working) > 0L) {
    sort_index <- order(
      working[[sequence_id_col]],
      working[[order_col]],
      working$.gp3_original_row,
      na.last = TRUE,
      method = "radix"
    )

    moved_rows <- sum(
      sort_index != seq_len(nrow(working))
    )

    working <- working[sort_index, , drop = FALSE]
    row.names(working) <- NULL
  } else {
    moved_rows <- 0L
  }

  add_decision(
    step = "row_order",
    policy = "deterministic_sort",
    affected_rows = moved_rows,
    details = paste0(
      "Rows were ordered by sequence identifier, sequence order, ",
      "and original row."
    )
  )

  collapsed_rows <- 0L

  if (
    repeated_state_policy == "collapse" &&
    nrow(working) > 1L
  ) {
    sequence_text <- as.character(
      working[[sequence_id_col]]
    )
    state_text <- as.character(working[[state_col]])

    same_previous <- rep(FALSE, nrow(working))

    same_previous[-1L] <-
      sequence_text[-1L] ==
      sequence_text[-nrow(working)] &
      !.sequence_missing_value(
        working[[state_col]][-1L]
      ) &
      !.sequence_missing_value(
        working[[state_col]][-nrow(working)]
      ) &
      state_text[-1L] ==
      state_text[-nrow(working)]

    group_id <- cumsum(!same_previous)
    keep_rows <- !duplicated(group_id)

    if (!is.null(duration_col)) {
      repeated_groups <- unique(group_id[duplicated(group_id)])

      for (group in repeated_groups) {
        rows <- which(group_id == group)
        duration_values <- working[[duration_col]][rows]

        combined_duration <- if (all(is.na(duration_values))) {
          NA_real_
        } else {
          sum(duration_values, na.rm = TRUE)
        }

        working[[duration_col]][rows[1L]] <- combined_duration
      }
    }

    collapsed_rows <- sum(!keep_rows)
    working <- working[keep_rows, , drop = FALSE]
    row.names(working) <- NULL
  }

  add_decision(
    step = "consecutive_repeats",
    policy = repeated_state_policy,
    affected_rows = collapsed_rows,
    details = if (repeated_state_policy == "collapse") {
      paste0(
        "The first row was retained for each repeated run; ",
        "available durations were summed."
      )
    } else {
      "Consecutive repeated states were preserved."
    }
  )

  if (
    unused_state_levels == "drop" &&
    is.factor(working[[state_col]])
  ) {
    before_levels <- levels(working[[state_col]])
    working[[state_col]] <- droplevels(
      working[[state_col]]
    )
    removed_levels <- length(
      setdiff(
        before_levels,
        levels(working[[state_col]])
      )
    )
  } else {
    removed_levels <- 0L
  }

  add_decision(
    step = "unused_state_levels",
    policy = unused_state_levels,
    affected_rows = removed_levels,
    details = if (unused_state_levels == "drop") {
      "Unused factor levels were removed."
    } else {
      "Unused factor levels were preserved."
    }
  )

  source_mapped <- c(
    sequence_id_col,
    order_col,
    state_col,
    duration_col
  )
  source_mapped <- source_mapped[!is.na(source_mapped)]

  extra_columns <- setdiff(
    names(working),
    c(source_mapped, ".gp3_original_row")
  )

  canonical_names <- c(
    "sequence_id",
    "sequence_order",
    "state",
    "original_row"
  )

  if (!is.null(duration_col)) {
    canonical_names <- c(canonical_names, "duration")
  }

  collisions <- intersect(extra_columns, canonical_names)

  if (length(collisions) > 0L) {
    stop(
      "Unmapped source columns use reserved canonical names: ",
      paste(collisions, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  canonical <- data.frame(
    sequence_id = working[[sequence_id_col]],
    sequence_order = working[[order_col]],
    state = working[[state_col]],
    original_row = as.integer(
      working$.gp3_original_row
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  if (!is.null(duration_col)) {
    canonical$duration <- working[[duration_col]]
  }

  for (column in extra_columns) {
    canonical[[column]] <- working[[column]]
  }

  row.names(canonical) <- NULL

  add_decision(
    step = "column_mapping",
    policy = "canonicalise",
    affected_rows = nrow(canonical),
    details = paste0(
      "Mapped columns were standardised while unmapped columns ",
      "were preserved."
    )
  )

  output_validation <- validate_sequence_data(
    data = canonical,
    sequence_id_col = "sequence_id",
    order_col = "sequence_order",
    state_col = "state",
    duration_col = if (!is.null(duration_col)) {
      "duration"
    } else {
      NULL
    },
    metadata_cols = metadata_cols,
    expected_states = expected_states
  )

  final_audit <- output_validation$audit
  policy_issues <- list()

  if (
    zero_duration_policy == "error" &&
    "duration" %in% names(canonical)
  ) {
    rows <- which(
      !is.na(canonical$duration) &
        is.finite(canonical$duration) &
        canonical$duration == 0
    )

    for (row in rows) {
      policy_issues[[length(policy_issues) + 1L]] <-
        .sequence_issue_row(
          sequence_id = canonical$sequence_id[row],
          row = canonical$original_row[row],
          column = "duration",
          issue_code = "zero_duration_disallowed",
          severity = "error",
          value = "0",
          message = "Zero duration is disallowed by the selected policy.",
          action = "Use `preserve`, `drop`, or correct the duration."
        )
    }
  }

  if (
    unknown_state_policy == "error" &&
    !is.null(expected_states)
  ) {
    expected_text <- unique(as.character(expected_states))
    state_text <- as.character(canonical$state)

    rows <- which(
      !.sequence_missing_value(canonical$state) &
        !(state_text %in% expected_text)
    )

    for (row in rows) {
      policy_issues[[length(policy_issues) + 1L]] <-
        .sequence_issue_row(
          sequence_id = canonical$sequence_id[row],
          row = canonical$original_row[row],
          column = "state",
          issue_code = "unknown_state_disallowed",
          severity = "error",
          value = .sequence_value_text(canonical$state[row]),
          message = "The state is disallowed by the selected policy.",
          action = "Use `preserve`, `drop`, or revise expected states."
        )
    }
  }

  if (length(policy_issues) > 0L) {
    final_audit <- rbind(
      final_audit,
      do.call(rbind, policy_issues)
    )

    final_audit <- .sequence_sort_audit(final_audit)
  }

  output_audit <- .sequence_stage_audit(
    final_audit,
    "output"
  )

  combined_audit <- rbind(input_audit, output_audit)
  row.names(combined_audit) <- NULL

  decisions <- if (length(decision_rows) == 0L) {
    .sequence_empty_decisions()
  } else {
    do.call(rbind, decision_rows)
  }

  row.names(decisions) <- NULL

  final_status <- .sequence_status(final_audit)

  state_levels <- if (is.factor(canonical$state)) {
    levels(canonical$state)
  } else {
    unique(
      as.character(
        canonical$state[
          !.sequence_missing_value(canonical$state)
        ]
      )
    )
  }

  .sequence_prepare_result(
    data = if (final_status == "fail") {
      NULL
    } else {
      canonical
    },
    audit = combined_audit,
    decisions = decisions,
    mapping = mapping,
    status = final_status,
    original_n_rows = nrow(data),
    prepared_n_rows = nrow(canonical),
    state_levels = state_levels
  )
}
