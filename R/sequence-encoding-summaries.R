.sequence_assert_text_scalar <- function(value, argument) {
  if (
    !is.character(value) ||
    length(value) != 1L ||
    is.na(value) ||
    !nzchar(value)
  ) {
    stop(
      "`",
      argument,
      "` must be one non-missing, non-empty character value.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.sequence_assert_flag <- function(value, argument) {
  if (
    !is.logical(value) ||
    length(value) != 1L ||
    is.na(value)
  ) {
    stop(
      "`",
      argument,
      "` must be either `TRUE` or `FALSE`.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.sequence_assert_output_names <- function(
    metadata_cols,
    reserved,
    context
) {
  collisions <- intersect(metadata_cols, reserved)

  if (length(collisions) > 0L) {
    stop(
      "Metadata column names conflict with ",
      context,
      " output columns: ",
      paste(collisions, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.sequence_summary_input <- function(
    data,
    sequence_id_col,
    order_col,
    state_col,
    duration_col = NULL,
    metadata_cols = NULL,
    expected_states = NULL
) {
  validation <- validate_sequence_data(
    data = data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    duration_col = duration_col,
    metadata_cols = metadata_cols,
    expected_states = expected_states
  )

  if (!validation$valid) {
    error_codes <- unique(
      validation$audit$issue_code[
        validation$audit$severity == "error"
      ]
    )

    stop(
      "Sequence data failed validation: ",
      paste(error_codes, collapse = ", "),
      ". Resolve the errors or use `prepare_sequence_data()` ",
      "with explicit policies before continuing.",
      call. = FALSE
    )
  }

  reserved <- c(
    "sequence_id",
    "sequence_order",
    "state",
    "original_row",
    "duration"
  )

  .sequence_assert_output_names(
    metadata_cols = metadata_cols,
    reserved = reserved,
    context = "canonical"
  )

  working <- data
  original_row <- seq_len(nrow(working))

  sequence_values <- working[[sequence_id_col]]

  sequence_sort <- if (
    is.numeric(sequence_values) ||
    is.logical(sequence_values)
  ) {
    sequence_values
  } else {
    as.character(sequence_values)
  }

  sort_index <- order(
    sequence_sort,
    working[[order_col]],
    original_row,
    method = "radix"
  )

  working <- working[sort_index, , drop = FALSE]
  original_row <- original_row[sort_index]
  row.names(working) <- NULL

  canonical <- data.frame(
    sequence_id = as.character(
      working[[sequence_id_col]]
    ),
    sequence_order = working[[order_col]],
    state = as.character(working[[state_col]]),
    original_row = as.integer(original_row),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  if (!is.null(duration_col)) {
    canonical$duration <- working[[duration_col]]
  }

  for (column in metadata_cols) {
    canonical[[column]] <- working[[column]]
  }

  list(
    data = canonical,
    audit = validation$audit,
    status = validation$status,
    mapping = validation$mapping,
    original_state_levels = if (
      is.factor(data[[state_col]])
    ) {
      levels(data[[state_col]])
    } else {
      NULL
    }
  )
}

.sequence_metadata_values <- function(
    data,
    rows,
    metadata_cols
) {
  values <- vector("list", length(metadata_cols))
  names(values) <- metadata_cols

  for (column in metadata_cols) {
    column_values <- data[[column]][rows]
    usable <- which(!is.na(column_values))

    selected <- if (length(usable) > 0L) {
      usable[1L]
    } else {
      1L
    }

    values[[column]] <- column_values[selected]
  }

  values
}

.sequence_sum_or_na <- function(value) {
  if (length(value) == 0L || all(is.na(value))) {
    return(NA_real_)
  }

  as.numeric(sum(value, na.rm = TRUE))
}

.sequence_mean_or_na <- function(value) {
  if (length(value) == 0L || all(is.na(value))) {
    return(NA_real_)
  }

  as.numeric(mean(value, na.rm = TRUE))
}

.sequence_safe_proportion <- function(
    numerator,
    denominator
) {
  if (
    length(denominator) != 1L ||
    is.na(denominator) ||
    denominator == 0
  ) {
    return(NA_real_)
  }

  as.numeric(numerator / denominator)
}

.sequence_bind_frames <- function(frames, empty) {
  if (length(frames) == 0L) {
    return(empty)
  }

  result <- do.call(rbind, frames)
  row.names(result) <- NULL
  result
}

.sequence_empty_state_by_sequence <- function(
    metadata_cols,
    include_duration
) {
  result <- data.frame(
    sequence_id = character(),
    state = character(),
    n_observations = integer(),
    observation_proportion = double(),
    stringsAsFactors = FALSE
  )

  for (column in metadata_cols) {
    result[[column]] <- character()
  }

  result <- result[
    c(
      "sequence_id",
      metadata_cols,
      "state",
      "n_observations",
      "observation_proportion"
    )
  ]

  if (include_duration) {
    result$duration_sum <- double()
    result$duration_proportion <- double()
    result$mean_duration <- double()
  }

  result
}

.sequence_empty_state_overall <- function(
    include_duration
) {
  result <- data.frame(
    state = character(),
    n_sequences = integer(),
    sequence_proportion = double(),
    n_observations = integer(),
    observation_proportion = double(),
    stringsAsFactors = FALSE
  )

  if (include_duration) {
    result$duration_sum <- double()
    result$duration_proportion <- double()
    result$mean_duration <- double()
  }

  result
}

.sequence_empty_transition_by_sequence <- function(
    metadata_cols
) {
  result <- data.frame(
    sequence_id = character(),
    from_state = character(),
    to_state = character(),
    n_transitions = integer(),
    sequence_transition_proportion = double(),
    origin_transition_proportion = double(),
    stringsAsFactors = FALSE
  )

  for (column in metadata_cols) {
    result[[column]] <- character()
  }

  result[
    c(
      "sequence_id",
      metadata_cols,
      "from_state",
      "to_state",
      "n_transitions",
      "sequence_transition_proportion",
      "origin_transition_proportion"
    )
  ]
}

.sequence_empty_transition_overall <- function() {
  data.frame(
    from_state = character(),
    to_state = character(),
    n_sequences = integer(),
    sequence_proportion = double(),
    n_transitions = integer(),
    transition_proportion = double(),
    origin_transition_proportion = double(),
    stringsAsFactors = FALSE
  )
}

#' Encode Ordered Sequence States
#'
#' Creates a deterministic dictionary and adds integer and labelled state
#' codes to long-format sequence data.
#'
#' @inheritParams audit_sequence_data
#' @param state_levels Optional atomic vector defining the complete state
#'   ordering. When omitted, factor levels are respected; otherwise observed
#'   state labels are sorted alphabetically.
#' @param prefix Character prefix used for labelled codes.
#' @param width Optional positive integer width for the numeric part of each
#'   labelled code. The default is determined from the dictionary size.
#'
#' @return A named list containing:
#'
#' * `data`: deterministically sorted canonical data with `state_index` and
#'   `state_code`;
#' * `dictionary`: state labels, integer indices, labelled codes, and an
#'   observed-state indicator;
#' * `audit`, `status`, and `mapping` from input validation;
#' * `settings`: the resolved code prefix and width.
#'
#' @details
#' The function does not reinterpret states. State codes are transparent
#' identifiers derived from an explicit or deterministic state ordering.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c("s1", "s1", "s2", "s2"),
#'   position = c(1, 2, 1, 2),
#'   state = c("home", "search", "home", "product")
#' )
#'
#' encoded <- encode_sequence_data(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state"
#' )
#'
#' encoded$dictionary
#' encoded$data
#'
#' @export
encode_sequence_data <- function(
    data,
    sequence_id_col,
    order_col,
    state_col,
    duration_col = NULL,
    metadata_cols = NULL,
    expected_states = NULL,
    state_levels = NULL,
    prefix = "S",
    width = NULL
) {
  .sequence_assert_text_scalar(prefix, "prefix")

  input <- .sequence_summary_input(
    data = data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    duration_col = duration_col,
    metadata_cols = metadata_cols,
    expected_states = expected_states
  )

  .sequence_assert_output_names(
    metadata_cols = metadata_cols,
    reserved = c("state_index", "state_code"),
    context = "encoded"
  )

  observed_states <- unique(input$data$state)

  if (is.null(state_levels)) {
    resolved_levels <- if (
      !is.null(input$original_state_levels)
    ) {
      as.character(input$original_state_levels)
    } else {
      sort(
        observed_states,
        method = "radix"
      )
    }
  } else {
    if (
      !is.atomic(state_levels) ||
      is.list(state_levels) ||
      anyNA(state_levels)
    ) {
      stop(
        "`state_levels` must be a non-missing atomic vector.",
        call. = FALSE
      )
    }

    resolved_levels <- as.character(state_levels)

    if (
      any(!nzchar(trimws(resolved_levels))) ||
      anyDuplicated(resolved_levels)
    ) {
      stop(
        "`state_levels` must contain unique, non-empty values.",
        call. = FALSE
      )
    }

    omitted_states <- setdiff(
      observed_states,
      resolved_levels
    )

    if (length(omitted_states) > 0L) {
      stop(
        "`state_levels` omits observed states: ",
        paste(omitted_states, collapse = ", "),
        ".",
        call. = FALSE
      )
    }
  }

  if (is.null(width)) {
    resolved_width <- max(
      1L,
      nchar(as.character(length(resolved_levels)))
    )
  } else {
    if (
      !is.numeric(width) ||
      length(width) != 1L ||
      is.na(width) ||
      !is.finite(width) ||
      width < 1 ||
      width != floor(width)
    ) {
      stop(
        "`width` must be one positive whole number.",
        call. = FALSE
      )
    }

    resolved_width <- as.integer(width)
  }

  state_index <- seq_along(resolved_levels)

  state_codes <- paste0(
    prefix,
    sprintf(
      paste0("%0", resolved_width, "d"),
      state_index
    )
  )

  dictionary <- data.frame(
    state = resolved_levels,
    state_index = as.integer(state_index),
    state_code = state_codes,
    observed = resolved_levels %in% observed_states,
    stringsAsFactors = FALSE
  )

  encoded <- input$data

  encoded$state_index <- dictionary$state_index[
    match(encoded$state, dictionary$state)
  ]

  encoded$state_code <- dictionary$state_code[
    match(encoded$state, dictionary$state)
  ]

  front <- c(
    "sequence_id",
    "sequence_order",
    "state",
    "state_index",
    "state_code",
    "original_row"
  )

  encoded <- encoded[
    c(
      front,
      setdiff(names(encoded), front)
    )
  ]

  list(
    data = encoded,
    dictionary = dictionary,
    audit = input$audit,
    status = input$status,
    mapping = input$mapping,
    settings = list(
      prefix = prefix,
      width = resolved_width
    )
  )
}

#' Summarise Sequence States
#'
#' Produces per-sequence and overall state-frequency summaries from validated
#' ordered sequence data.
#'
#' @inheritParams audit_sequence_data
#'
#' @return A named list containing:
#'
#' * `by_sequence`: state counts and proportions within each sequence;
#' * `overall`: state counts and proportions across all sequences;
#' * `audit`, `status`, and `mapping` from input validation.
#'
#' When `duration_col` is supplied, both tables also include duration sums,
#' duration proportions, and mean durations.
#'
#' @details
#' Observation proportions use state rows as the denominator. Sequence
#' proportions report the proportion of sequences in which each state occurs.
#' Missing durations are excluded from duration calculations; an all-missing
#' duration group returns `NA`.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c("s1", "s1", "s1", "s2", "s2"),
#'   position = c(1, 2, 3, 1, 2),
#'   state = c("A", "B", "A", "B", "C")
#' )
#'
#' summaries <- summarise_sequence_states(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state"
#' )
#'
#' summaries$by_sequence
#' summaries$overall
#'
#' @export
summarise_sequence_states <- function(
    data,
    sequence_id_col,
    order_col,
    state_col,
    duration_col = NULL,
    metadata_cols = NULL,
    expected_states = NULL
) {
  .sequence_assert_output_names(
    metadata_cols = metadata_cols,
    reserved = c(
      "state",
      "n_observations",
      "observation_proportion",
      "duration_sum",
      "duration_proportion",
      "mean_duration"
    ),
    context = "state-summary"
  )

  input <- .sequence_summary_input(
    data = data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    duration_col = duration_col,
    metadata_cols = metadata_cols,
    expected_states = expected_states
  )

  sequence_data <- input$data
  sequence_ids <- unique(sequence_data$sequence_id)
  include_duration <- "duration" %in% names(sequence_data)

  sequence_rows <- list()

  for (sequence_id in sequence_ids) {
    rows <- which(
      sequence_data$sequence_id == sequence_id
    )

    metadata <- .sequence_metadata_values(
      data = sequence_data,
      rows = rows,
      metadata_cols = metadata_cols
    )

    sequence_states <- sequence_data$state[rows]
    state_order <- unique(sequence_states)
    sequence_n <- length(rows)

    sequence_duration <- if (include_duration) {
      .sequence_sum_or_na(sequence_data$duration[rows])
    } else {
      NULL
    }

    for (state in state_order) {
      state_rows <- rows[
        sequence_data$state[rows] == state
      ]

      values <- c(
        list(sequence_id = sequence_id),
        metadata,
        list(
          state = state,
          n_observations = as.integer(
            length(state_rows)
          ),
          observation_proportion =
            length(state_rows) / sequence_n
        )
      )

      if (include_duration) {
        state_duration <- .sequence_sum_or_na(
          sequence_data$duration[state_rows]
        )

        values <- c(
          values,
          list(
            duration_sum = state_duration,
            duration_proportion =
              .sequence_safe_proportion(
                state_duration,
                sequence_duration
              ),
            mean_duration = .sequence_mean_or_na(
              sequence_data$duration[state_rows]
            )
          )
        )
      }

      sequence_rows[[length(sequence_rows) + 1L]] <-
        as.data.frame(
          values,
          stringsAsFactors = FALSE,
          check.names = FALSE
        )
    }
  }

  by_sequence <- .sequence_bind_frames(
    frames = sequence_rows,
    empty = .sequence_empty_state_by_sequence(
      metadata_cols = metadata_cols,
      include_duration = include_duration
    )
  )

  overall_rows <- list()
  overall_states <- unique(sequence_data$state)
  total_observations <- nrow(sequence_data)
  total_sequences <- length(sequence_ids)

  total_duration <- if (include_duration) {
    .sequence_sum_or_na(sequence_data$duration)
  } else {
    NULL
  }

  for (state in overall_states) {
    state_rows <- which(sequence_data$state == state)
    state_sequences <- unique(
      sequence_data$sequence_id[state_rows]
    )

    values <- list(
      state = state,
      n_sequences = as.integer(
        length(state_sequences)
      ),
      sequence_proportion =
        length(state_sequences) / total_sequences,
      n_observations = as.integer(
        length(state_rows)
      ),
      observation_proportion =
        length(state_rows) / total_observations
    )

    if (include_duration) {
      state_duration <- .sequence_sum_or_na(
        sequence_data$duration[state_rows]
      )

      values <- c(
        values,
        list(
          duration_sum = state_duration,
          duration_proportion =
            .sequence_safe_proportion(
              state_duration,
              total_duration
            ),
          mean_duration = .sequence_mean_or_na(
            sequence_data$duration[state_rows]
          )
        )
      )
    }

    overall_rows[[length(overall_rows) + 1L]] <-
      as.data.frame(
        values,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
  }

  overall <- .sequence_bind_frames(
    frames = overall_rows,
    empty = .sequence_empty_state_overall(
      include_duration = include_duration
    )
  )

  list(
    by_sequence = by_sequence,
    overall = overall,
    audit = input$audit,
    status = input$status,
    mapping = input$mapping
  )
}

#' Summarise Adjacent Sequence Transitions
#'
#' Counts transitions between adjacent ordered states for each sequence and
#' across the complete data set.
#'
#' @inheritParams audit_sequence_data
#' @param include_self Logical value indicating whether transitions from a
#'   state to the same state should be included.
#'
#' @return A named list containing:
#'
#' * `by_sequence`: transition counts, proportions within each sequence, and
#'   conditional proportions within each origin state;
#' * `overall`: transition counts, sequence coverage, global proportions, and
#'   conditional origin-state proportions;
#' * `audit`, `status`, `mapping`, and the resolved `include_self` setting.
#'
#' @details
#' A transition is defined only between adjacent rows after deterministic
#' ordering by sequence identifier, sequence order, and original row.
#' Sequences with one state contribute no transitions.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c("s1", "s1", "s1", "s2", "s2"),
#'   position = c(1, 2, 3, 1, 2),
#'   state = c("A", "B", "C", "A", "C")
#' )
#'
#' transitions <- summarise_sequence_transitions(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state"
#' )
#'
#' transitions$by_sequence
#' transitions$overall
#'
#' @export
summarise_sequence_transitions <- function(
    data,
    sequence_id_col,
    order_col,
    state_col,
    metadata_cols = NULL,
    expected_states = NULL,
    include_self = TRUE
) {
  .sequence_assert_flag(include_self, "include_self")

  .sequence_assert_output_names(
    metadata_cols = metadata_cols,
    reserved = c(
      "from_state",
      "to_state",
      "n_transitions",
      "sequence_transition_proportion",
      "transition_proportion",
      "origin_transition_proportion",
      "n_sequences",
      "sequence_proportion"
    ),
    context = "transition-summary"
  )

  input <- .sequence_summary_input(
    data = data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    metadata_cols = metadata_cols,
    expected_states = expected_states
  )

  sequence_data <- input$data
  sequence_ids <- unique(sequence_data$sequence_id)

  by_sequence_rows <- list()
  raw_transition_rows <- list()

  for (sequence_id in sequence_ids) {
    rows <- which(
      sequence_data$sequence_id == sequence_id
    )

    if (length(rows) < 2L) {
      next
    }

    states <- sequence_data$state[rows]

    pairs <- data.frame(
      from_state = states[-length(states)],
      to_state = states[-1L],
      stringsAsFactors = FALSE
    )

    if (!include_self) {
      pairs <- pairs[
        pairs$from_state != pairs$to_state,
        ,
        drop = FALSE
      ]
    }

    if (nrow(pairs) == 0L) {
      next
    }

    raw_transition_rows[[length(raw_transition_rows) + 1L]] <-
      data.frame(
        sequence_id = rep(sequence_id, nrow(pairs)),
        pairs,
        stringsAsFactors = FALSE
      )

    metadata <- .sequence_metadata_values(
      data = sequence_data,
      rows = rows,
      metadata_cols = metadata_cols
    )

    unique_pairs <- unique(pairs)
    sequence_total <- nrow(pairs)

    for (pair_index in seq_len(nrow(unique_pairs))) {
      from_state <- unique_pairs$from_state[pair_index]
      to_state <- unique_pairs$to_state[pair_index]

      pair_rows <- pairs$from_state == from_state &
        pairs$to_state == to_state

      pair_count <- sum(pair_rows)
      origin_count <- sum(
        pairs$from_state == from_state
      )

      values <- c(
        list(sequence_id = sequence_id),
        metadata,
        list(
          from_state = from_state,
          to_state = to_state,
          n_transitions = as.integer(pair_count),
          sequence_transition_proportion =
            pair_count / sequence_total,
          origin_transition_proportion =
            pair_count / origin_count
        )
      )

      by_sequence_rows[[length(by_sequence_rows) + 1L]] <-
        as.data.frame(
          values,
          stringsAsFactors = FALSE,
          check.names = FALSE
        )
    }
  }

  by_sequence <- .sequence_bind_frames(
    frames = by_sequence_rows,
    empty = .sequence_empty_transition_by_sequence(
      metadata_cols = metadata_cols
    )
  )

  raw_transitions <- if (
    length(raw_transition_rows) == 0L
  ) {
    data.frame(
      sequence_id = character(),
      from_state = character(),
      to_state = character(),
      stringsAsFactors = FALSE
    )
  } else {
    result <- do.call(rbind, raw_transition_rows)
    row.names(result) <- NULL
    result
  }

  overall_rows <- list()

  if (nrow(raw_transitions) > 0L) {
    unique_pairs <- unique(
      raw_transitions[
        c("from_state", "to_state")
      ]
    )

    total_transitions <- nrow(raw_transitions)
    total_sequences <- length(sequence_ids)

    for (pair_index in seq_len(nrow(unique_pairs))) {
      from_state <- unique_pairs$from_state[pair_index]
      to_state <- unique_pairs$to_state[pair_index]

      pair_rows <-
        raw_transitions$from_state == from_state &
        raw_transitions$to_state == to_state

      pair_count <- sum(pair_rows)
      origin_count <- sum(
        raw_transitions$from_state == from_state
      )

      contributing_sequences <- unique(
        raw_transitions$sequence_id[pair_rows]
      )

      overall_rows[[length(overall_rows) + 1L]] <-
        data.frame(
          from_state = from_state,
          to_state = to_state,
          n_sequences = as.integer(
            length(contributing_sequences)
          ),
          sequence_proportion =
            length(contributing_sequences) /
            total_sequences,
          n_transitions = as.integer(pair_count),
          transition_proportion =
            pair_count / total_transitions,
          origin_transition_proportion =
            pair_count / origin_count,
          stringsAsFactors = FALSE
        )
    }
  }

  overall <- .sequence_bind_frames(
    frames = overall_rows,
    empty = .sequence_empty_transition_overall()
  )

  list(
    by_sequence = by_sequence,
    overall = overall,
    audit = input$audit,
    status = input$status,
    mapping = input$mapping,
    include_self = include_self
  )
}

#' Format Ordered Sequence Paths
#'
#' Creates a compact one-row-per-sequence representation of ordered state
#' paths.
#'
#' @inheritParams audit_sequence_data
#' @param separator Character value inserted between adjacent state labels.
#' @param collapse_repeats Logical value indicating whether consecutive
#'   repeated states should be collapsed for path display.
#'
#' @return A named list containing:
#'
#' * `paths`: one row per sequence with observation counts, formatted-state
#'   counts, unique-state counts, start and end states, and the path string;
#' * `audit`, `status`, and `mapping` from input validation;
#' * `settings`: the path separator and repeat-collapsing choice.
#'
#' @details
#' Repeat collapsing affects only the formatted representation. It does not
#' modify the supplied data or alter non-consecutive repeated states.
#' Input rows are ordered deterministically for formatting, but review-level
#' diagnostics such as `unordered_rows` remain reflected in the returned
#' `status` and `audit`.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c("s1", "s1", "s1", "s2", "s2"),
#'   position = c(1, 2, 3, 1, 2),
#'   state = c("A", "B", "C", "A", "C")
#' )
#'
#' paths <- format_sequence_paths(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state"
#' )
#'
#' paths$paths
#'
#' @export
format_sequence_paths <- function(
    data,
    sequence_id_col,
    order_col,
    state_col,
    metadata_cols = NULL,
    expected_states = NULL,
    separator = " > ",
    collapse_repeats = FALSE
) {
  .sequence_assert_text_scalar(separator, "separator")
  .sequence_assert_flag(
    collapse_repeats,
    "collapse_repeats"
  )

  .sequence_assert_output_names(
    metadata_cols = metadata_cols,
    reserved = c(
      "n_observations",
      "n_states",
      "n_unique_states",
      "start_state",
      "end_state",
      "path"
    ),
    context = "path"
  )

  input <- .sequence_summary_input(
    data = data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    metadata_cols = metadata_cols,
    expected_states = expected_states
  )

  sequence_data <- input$data
  sequence_ids <- unique(sequence_data$sequence_id)
  path_rows <- list()

  for (sequence_id in sequence_ids) {
    rows <- which(
      sequence_data$sequence_id == sequence_id
    )

    observed_states <- sequence_data$state[rows]
    formatted_states <- observed_states

    if (
      collapse_repeats &&
      length(formatted_states) > 1L
    ) {
      keep <- c(
        TRUE,
        formatted_states[-1L] !=
          formatted_states[-length(formatted_states)]
      )

      formatted_states <- formatted_states[keep]
    }

    metadata <- .sequence_metadata_values(
      data = sequence_data,
      rows = rows,
      metadata_cols = metadata_cols
    )

    values <- c(
      list(sequence_id = sequence_id),
      metadata,
      list(
        n_observations = as.integer(
          length(observed_states)
        ),
        n_states = as.integer(
          length(formatted_states)
        ),
        n_unique_states = as.integer(
          length(unique(formatted_states))
        ),
        start_state = formatted_states[1L],
        end_state = formatted_states[
          length(formatted_states)
        ],
        path = paste(
          formatted_states,
          collapse = separator
        )
      )
    )

    path_rows[[length(path_rows) + 1L]] <-
      as.data.frame(
        values,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
  }

  paths <- do.call(rbind, path_rows)
  row.names(paths) <- NULL

  list(
    paths = paths,
    audit = input$audit,
    status = input$status,
    mapping = input$mapping,
    settings = list(
      separator = separator,
      collapse_repeats = collapse_repeats
    )
  )
}
