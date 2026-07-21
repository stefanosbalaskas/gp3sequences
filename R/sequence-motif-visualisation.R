.sequence_motif_position_empty_occurrences <- function(by) {
  result <- data.frame(
    sequence_id = character(),
    motif_id = character(),
    motif_key = character(),
    motif = character(),
    motif_length = integer(),
    start_index = integer(),
    end_index = integer(),
    n_states = integer(),
    position_basis = character(),
    position_scale = character(),
    absolute_position = double(),
    relative_position = double(),
    position_value = double(),
    stringsAsFactors = FALSE
  )

  for (column in by) {
    result[[column]] <- character()
  }

  result[
    c(
      "sequence_id",
      by,
      "motif_id",
      "motif_key",
      "motif",
      "motif_length",
      "start_index",
      "end_index",
      "n_states",
      "position_basis",
      "position_scale",
      "absolute_position",
      "relative_position",
      "position_value"
    )
  ]
}

.sequence_motif_position_empty_summary <- function(by) {
  result <- data.frame(
    motif_id = character(),
    motif_key = character(),
    motif = character(),
    motif_length = integer(),
    position_basis = character(),
    position_scale = character(),
    n_occurrences = integer(),
    n_sequences = integer(),
    min_position = double(),
    max_position = double(),
    mean_position = double(),
    median_position = double(),
    stringsAsFactors = FALSE
  )

  for (column in by) {
    result[[column]] <- character()
  }

  result[
    c(
      by,
      "motif_id",
      "motif_key",
      "motif",
      "motif_length",
      "position_basis",
      "position_scale",
      "n_occurrences",
      "n_sequences",
      "min_position",
      "max_position",
      "mean_position",
      "median_position"
    )
  ]
}

.sequence_motif_position_validate_by <- function(by, occurrences) {
  if (is.null(by)) {
    return(character())
  }

  if (
    !is.character(by) ||
      length(by) == 0L ||
      anyNA(by) ||
      any(!nzchar(by)) ||
      anyDuplicated(by)
  ) {
    stop(
      "`by` must be `NULL` or a unique character vector of column names.",
      call. = FALSE
    )
  }

  reserved <- c(
    "sequence_id",
    "motif_id",
    "motif_key",
    "motif",
    "motif_length",
    "start_index",
    "end_index",
    "start_order",
    "end_order",
    "start_original_row",
    "end_original_row",
    "occurrence_index"
  )

  reserved_by <- intersect(by, reserved)

  if (length(reserved_by) > 0L) {
    stop(
      "`by` must contain preserved metadata columns, not reserved motif columns: ",
      paste(reserved_by, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  missing_by <- setdiff(by, names(occurrences))

  if (length(missing_by) > 0L) {
    stop(
      "The following `by` columns were not preserved during extraction: ",
      paste(missing_by, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  by
}

.sequence_motif_group_factor <- function(data, columns) {
  if (length(columns) == 0L) {
    return(factor(rep("all", nrow(data))))
  }

  values <- lapply(
    data[columns],
    function(value) {
      addNA(factor(value, exclude = NULL), ifany = FALSE)
    }
  )

  do.call(
    interaction,
    c(values, list(drop = TRUE, lex.order = TRUE))
  )
}

.sequence_motif_position_sort <- function(data, by) {
  if (nrow(data) == 0L) {
    return(data)
  }

  order_arguments <- list()

  for (column in by) {
    value <- data[[column]]

    if (is.factor(value)) {
      value <- as.character(value)
    }

    order_arguments[[length(order_arguments) + 1L]] <- value
  }

  order_arguments[[length(order_arguments) + 1L]] <- data$mean_position
  order_arguments[[length(order_arguments) + 1L]] <- data$median_position
  order_arguments[[length(order_arguments) + 1L]] <- -data$n_occurrences
  order_arguments[[length(order_arguments) + 1L]] <- -data$n_sequences
  order_arguments[[length(order_arguments) + 1L]] <- data$motif_length
  order_arguments[[length(order_arguments) + 1L]] <- data$motif_key
  order_arguments$method <- "radix"

  data <- data[do.call(order, order_arguments), , drop = FALSE]
  row.names(data) <- NULL
  data
}

.sequence_motif_position_validate_summary <- function(x) {
  if (
    !is.list(x) ||
      is.null(x$summary) ||
      is.null(x$occurrences) ||
      is.null(x$settings)
  ) {
    stop(
      "`x` must be an object returned by `summarise_sequence_motif_positions()`.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.sequence_motif_position_values <- function(
  occurrences,
  sequences,
  position,
  scale
) {
  if (nrow(occurrences) == 0L) {
    result <- occurrences
    result$n_states <- integer()
    result$position_basis <- character()
    result$position_scale <- character()
    result$absolute_position <- double()
    result$relative_position <- double()
    result$position_value <- double()
    return(result)
  }

  sequence_match <- match(
    occurrences$sequence_id,
    sequences$sequence_id
  )

  if (anyNA(sequence_match)) {
    stop(
      "Some motif occurrences do not match the extraction sequence table.",
      call. = FALSE
    )
  }

  n_states <- as.integer(sequences$n_states[sequence_match])

  absolute_position <- switch(
    position,
    start = as.numeric(occurrences$start_index),
    centre = (
      as.numeric(occurrences$start_index) +
        as.numeric(occurrences$end_index)
    ) / 2,
    end = as.numeric(occurrences$end_index)
  )

  relative_position <- ifelse(
    n_states <= 1L,
    0,
    (absolute_position - 1) / (n_states - 1)
  )

  relative_position <- pmin(1, pmax(0, relative_position))

  result <- occurrences
  result$n_states <- n_states
  result$position_basis <- position
  result$position_scale <- scale
  result$absolute_position <- absolute_position
  result$relative_position <- relative_position
  result$position_value <- if (scale == "relative") {
    relative_position
  } else {
    absolute_position
  }

  result
}

.sequence_motif_plot_empty <- function(message, main, xlab = "") {
  graphics::plot.new()
  graphics::title(main = main, xlab = xlab)
  graphics::text(0.5, 0.5, labels = message)
  invisible(NULL)
}

.sequence_motif_plot_metric_label <- function(metric) {
  switch(
    metric,
    sequence_prevalence = "Sequence prevalence (proportion)",
    n_occurrences = "Occurrence count",
    n_sequences = "Sequences containing motif",
    occurrence_share = "Occurrence share (proportion)"
  )
}

.sequence_motif_plot_selectors <- function(motifs, dictionary) {
  if (is.null(motifs)) {
    return(NULL)
  }

  if (
    !is.character(motifs) ||
      length(motifs) == 0L ||
      anyNA(motifs) ||
      any(!nzchar(motifs))
  ) {
    stop(
      "`motifs` must be `NULL` or a non-empty character vector.",
      call. = FALSE
    )
  }

  selected_ids <- character()
  unknown <- character()

  for (selector in motifs) {
    matched <- dictionary$motif_id[
      dictionary$motif_id == selector |
        dictionary$motif_key == selector |
        dictionary$motif == selector
    ]

    matched <- unique(matched)

    if (length(matched) == 0L) {
      unknown <- c(unknown, selector)
    } else {
      selected_ids <- c(selected_ids, matched)
    }
  }

  if (length(unknown) > 0L) {
    stop(
      "The following requested motifs were not found: ",
      paste(unique(unknown), collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  unique(selected_ids)
}

# Shared internal plot-data contract. It is deliberately not exported.
.sequence_motif_plot_data <- function(
  x,
  type = c("motifs", "positions"),
  metric = "sequence_prevalence",
  motif_lengths = NULL,
  top_n = 20L,
  ties = c("include", "first"),
  motifs = NULL,
  position = "start",
  scale = "relative"
) {
  type <- .sequence_motif_match_arg(
    type,
    c("motifs", "positions"),
    "type"
  )

  .sequence_motif_assert_whole_number(
    top_n,
    "top_n",
    minimum = 1L
  )

  if (type == "motifs") {
    metric <- .sequence_motif_match_arg(
      metric,
      c(
        "sequence_prevalence",
        "n_occurrences",
        "n_sequences",
        "occurrence_share"
      ),
      "metric"
    )

    .sequence_motif_assert_motif_lengths(motif_lengths)

    ties <- .sequence_motif_match_arg(
      ties,
      c("include", "first"),
      "ties"
    )

    summary <- .sequence_motif_as_summary(x)
    data <- summary$overall

    if (!is.null(motif_lengths)) {
      data <- data[
        data$motif_length %in% sort(unique(as.integer(motif_lengths))),
        ,
        drop = FALSE
      ]
    }

    data <- .sequence_motif_sort_overall(data, primary = metric)

    if (nrow(data) > top_n) {
      if (ties == "include") {
        threshold <- data[[metric]][top_n]
        data <- data[data[[metric]] >= threshold, , drop = FALSE]
      } else {
        data <- data[seq_len(top_n), , drop = FALSE]
      }
    }

    row.names(data) <- NULL
    data$plot_rank <- seq_len(nrow(data))
    data$plot_value <- as.numeric(data[[metric]])
    data$plot_label <- as.character(data$motif)

    return(data)
  }

  position <- .sequence_motif_match_arg(
    position,
    c("start", "centre", "end"),
    "position"
  )

  scale <- .sequence_motif_match_arg(
    scale,
    c("absolute", "relative"),
    "scale"
  )

  if (
    is.list(x) &&
      !is.null(x$summary) &&
      !is.null(x$occurrences) &&
      !is.null(x$settings)
  ) {
    positional <- x
    occurrences <- positional$occurrences

    required <- c(
      "sequence_id",
      "motif_id",
      "motif_key",
      "motif",
      "motif_length",
      "start_index",
      "end_index",
      "n_states"
    )

    missing_required <- setdiff(required, names(occurrences))

    if (length(missing_required) > 0L) {
      stop(
        "The positional summary is missing required occurrence columns: ",
        paste(missing_required, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    absolute_position <- switch(
      position,
      start = as.numeric(occurrences$start_index),
      centre = (
        as.numeric(occurrences$start_index) +
          as.numeric(occurrences$end_index)
      ) / 2,
      end = as.numeric(occurrences$end_index)
    )

    relative_position <- ifelse(
      occurrences$n_states <= 1L,
      0,
      (absolute_position - 1) / (occurrences$n_states - 1)
    )

    relative_position <- pmin(1, pmax(0, relative_position))

    occurrences$position_basis <- position
    occurrences$position_scale <- scale
    occurrences$absolute_position <- absolute_position
    occurrences$relative_position <- relative_position
    occurrences$position_value <- if (scale == "relative") {
      relative_position
    } else {
      absolute_position
    }
  } else {
    .sequence_motif_validate_extraction(x)

    positional <- summarise_sequence_motif_positions(
      x,
      position = position,
      scale = scale
    )

    occurrences <- positional$occurrences
  }

  if (nrow(occurrences) == 0L) {
    occurrences$plot_rank <- integer()
    occurrences$plot_label <- character()
    return(occurrences)
  }

  dictionary <- unique(
    occurrences[
      c("motif_id", "motif_key", "motif", "motif_length")
    ]
  )

  selected_ids <- .sequence_motif_plot_selectors(
    motifs,
    dictionary
  )

  occurrence_groups <- split(
    seq_len(nrow(occurrences)),
    occurrences$motif_id
  )

  motif_rows <- lapply(
    occurrence_groups,
    function(indices) {
      first <- indices[1L]

      data.frame(
        motif_id = occurrences$motif_id[first],
        motif_key = occurrences$motif_key[first],
        motif = occurrences$motif[first],
        motif_length = as.integer(occurrences$motif_length[first]),
        n_occurrences = as.integer(length(indices)),
        n_sequences = as.integer(
          length(unique(occurrences$sequence_id[indices]))
        ),
        stringsAsFactors = FALSE
      )
    }
  )

  motif_table <- do.call(rbind, motif_rows)
  row.names(motif_table) <- NULL

  if (is.null(selected_ids)) {
    motif_table <- motif_table[
      order(
        -motif_table$n_occurrences,
        -motif_table$n_sequences,
        motif_table$motif_length,
        motif_table$motif_key,
        method = "radix"
      ),
      ,
      drop = FALSE
    ]

    if (nrow(motif_table) > top_n) {
      motif_table <- motif_table[seq_len(top_n), , drop = FALSE]
    }

    selected_ids <- motif_table$motif_id
  } else {
    motif_table <- motif_table[
      motif_table$motif_id %in% selected_ids,
      ,
      drop = FALSE
    ]

    motif_table <- motif_table[
      match(selected_ids, motif_table$motif_id),
      ,
      drop = FALSE
    ]
  }

  row.names(motif_table) <- NULL
  motif_table$plot_rank <- seq_len(nrow(motif_table))

  occurrences <- occurrences[
    occurrences$motif_id %in% selected_ids,
    ,
    drop = FALSE
  ]

  occurrences$plot_rank <- match(
    occurrences$motif_id,
    selected_ids
  )
  occurrences$plot_label <- motif_table$motif[
    match(occurrences$motif_id, motif_table$motif_id)
  ]

  occurrences <- occurrences[
    order(
      occurrences$plot_rank,
      occurrences$position_value,
      occurrences$sequence_id,
      occurrences$start_index,
      occurrences$end_index,
      method = "radix"
    ),
    ,
    drop = FALSE
  ]

  row.names(occurrences) <- NULL
  attr(occurrences, "motif_table") <- motif_table
  occurrences
}

#' Summarise Sequence Motif Positions
#'
#' Summarises where contiguous motif occurrences appear within sequences.
#'
#' @param x An object returned by `extract_sequence_ngrams()`.
#' @param position Position represented by each occurrence: motif `"start"`,
#'   `"centre"`, or `"end"`.
#' @param scale Position scale: one-based `"absolute"` sequence positions or
#'   `"relative"` positions from 0 to 1.
#' @param by Optional character vector naming preserved metadata columns used
#'   to produce separate summaries, such as `"group"` or `"condition"`.
#'
#' @return A named list containing:
#'
#' * `summary`: one row per motif and optional metadata group;
#' * `occurrences`: occurrence-level absolute, relative, and selected-scale
#'   positions;
#' * `sequences`, validation metadata, and extraction settings;
#' * `settings`: the resolved position basis, scale, and grouping columns.
#'
#' The summary reports motif identifiers and labels, motif length, occurrence
#' and sequence counts, and minimum, maximum, mean, and median positions.
#'
#' @details
#' Absolute positions use the one-based state index within each validated
#' sequence. Relative positions are calculated as
#' `(absolute_position - 1) / (n_states - 1)` and are constrained to the
#' interval from 0 to 1. A sequence containing one state is assigned relative
#' position 0.
#'
#' Grouping is descriptive. The function does not test differences or attach
#' behavioural, psychological, cognitive, or causal interpretations to motif
#' location.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c(rep("s1", 5L), rep("s2", 4L)),
#'   position = c(1:5, 1:4),
#'   state = c("A", "B", "A", "B", "C", "A", "B", "C", "B"),
#'   group = c(rep("g1", 5L), rep("g2", 4L))
#' )
#'
#' extracted <- extract_sequence_ngrams(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state",
#'   metadata_cols = "group",
#'   min_length = 2,
#'   max_length = 3
#' )
#'
#' positions <- summarise_sequence_motif_positions(
#'   extracted,
#'   position = "centre",
#'   scale = "relative",
#'   by = "group"
#' )
#'
#' positions$summary
#'
#' @export
summarise_sequence_motif_positions <- function(
  x,
  position = c("start", "centre", "end"),
  scale = c("absolute", "relative"),
  by = NULL
) {
  .sequence_motif_validate_extraction(x)

  position <- .sequence_motif_match_arg(
    position,
    c("start", "centre", "end"),
    "position"
  )

  scale <- .sequence_motif_match_arg(
    scale,
    c("absolute", "relative"),
    "scale"
  )

  by <- .sequence_motif_position_validate_by(
    by,
    x$occurrences
  )

  occurrences <- .sequence_motif_position_values(
    x$occurrences,
    x$sequences,
    position,
    scale
  )

  occurrence_columns <- c(
    "sequence_id",
    by,
    "motif_id",
    "motif_key",
    "motif",
    "motif_length",
    "start_index",
    "end_index",
    "n_states",
    "position_basis",
    "position_scale",
    "absolute_position",
    "relative_position",
    "position_value"
  )

  if (nrow(occurrences) == 0L) {
    occurrence_positions <- .sequence_motif_position_empty_occurrences(by)
    summary <- .sequence_motif_position_empty_summary(by)
  } else {
    occurrence_positions <- occurrences[, occurrence_columns, drop = FALSE]

    group_columns <- c(by, "motif_id")
    groups <- split(
      seq_len(nrow(occurrence_positions)),
      .sequence_motif_group_factor(
        occurrence_positions,
        group_columns
      )
    )

    summary_rows <- lapply(
      groups,
      function(indices) {
        first <- indices[1L]
        group_values <- vector("list", length(by))
        names(group_values) <- by

        for (column in by) {
          group_values[[column]] <- occurrence_positions[[column]][first]
        }

        values <- occurrence_positions$position_value[indices]

        as.data.frame(
          c(
            group_values,
            list(
              motif_id = occurrence_positions$motif_id[first],
              motif_key = occurrence_positions$motif_key[first],
              motif = occurrence_positions$motif[first],
              motif_length = as.integer(
                occurrence_positions$motif_length[first]
              ),
              position_basis = position,
              position_scale = scale,
              n_occurrences = as.integer(length(indices)),
              n_sequences = as.integer(
                length(unique(occurrence_positions$sequence_id[indices]))
              ),
              min_position = min(values),
              max_position = max(values),
              mean_position = mean(values),
              median_position = stats::median(values)
            )
          ),
          stringsAsFactors = FALSE,
          check.names = FALSE
        )
      }
    )

    summary <- do.call(rbind, summary_rows)
    row.names(summary) <- NULL
    summary <- .sequence_motif_position_sort(summary, by)

    occurrence_order <- list()

    for (column in by) {
      value <- occurrence_positions[[column]]

      if (is.factor(value)) {
        value <- as.character(value)
      }

      occurrence_order[[length(occurrence_order) + 1L]] <- value
    }

    occurrence_order[[length(occurrence_order) + 1L]] <-
      occurrence_positions$motif_length
    occurrence_order[[length(occurrence_order) + 1L]] <-
      occurrence_positions$motif_key
    occurrence_order[[length(occurrence_order) + 1L]] <-
      occurrence_positions$position_value
    occurrence_order[[length(occurrence_order) + 1L]] <-
      occurrence_positions$sequence_id
    occurrence_order[[length(occurrence_order) + 1L]] <-
      occurrence_positions$start_index
    occurrence_order[[length(occurrence_order) + 1L]] <-
      occurrence_positions$end_index
    occurrence_order$method <- "radix"

    occurrence_positions <- occurrence_positions[
      do.call(order, occurrence_order),
      ,
      drop = FALSE
    ]

    row.names(occurrence_positions) <- NULL
  }

  list(
    summary = summary,
    occurrences = occurrence_positions,
    sequences = x$sequences,
    state_dictionary = x$state_dictionary,
    audit = x$audit,
    status = x$status,
    mapping = x$mapping,
    extraction_settings = x$settings,
    settings = list(
      position = position,
      scale = scale,
      by = by,
      absolute_unit = "one_based_state_index",
      relative_range = c(0, 1)
    ),
    n_occurrences = as.integer(nrow(occurrence_positions)),
    n_motifs = as.integer(length(unique(occurrence_positions$motif_id))),
    n_groups = if (nrow(summary) == 0L) {
      0L
    } else if (length(by) == 0L) {
      1L
    } else {
      as.integer(
        length(unique(.sequence_motif_group_factor(summary, by)))
      )
    }
  )
}

#' Format Sequence Motif Position Summaries
#'
#' Produces a deterministic report-ready table from positional motif summaries.
#'
#' @param x An object returned by `summarise_sequence_motif_positions()`.
#' @param digits Whole number from 0 to 15 controlling numeric rounding.
#' @param position_units Display units for relative positions: `"proportion"`
#'   or `"percent"`. Absolute positions remain one-based sequence indices.
#' @param include_rank Logical value indicating whether to include an
#'   earlier-to-later rank based on mean position. Ranking is performed within
#'   each supplied `by` group.
#'
#' @return A named list containing the formatted `table`, validation metadata,
#' and formatting settings.
#'
#' @details
#' Formatting copies and transforms the summary table only. The input object is
#' not modified. Rows are ordered deterministically by grouping values, mean
#' and median position, occurrence and sequence counts, motif length, and motif
#' key. Equal mean positions receive the same minimum rank.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c(rep("s1", 5L), rep("s2", 4L)),
#'   position = c(1:5, 1:4),
#'   state = c("A", "B", "A", "B", "C", "A", "B", "C", "B")
#' )
#'
#' extracted <- extract_sequence_ngrams(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state"
#' )
#'
#' positions <- summarise_sequence_motif_positions(
#'   extracted,
#'   position = "centre",
#'   scale = "relative"
#' )
#'
#' formatted <- format_sequence_motif_positions(
#'   positions,
#'   position_units = "percent",
#'   digits = 1
#' )
#'
#' formatted$table
#'
#' @export
format_sequence_motif_positions <- function(
  x,
  digits = 3L,
  position_units = c("proportion", "percent"),
  include_rank = TRUE
) {
  .sequence_motif_position_validate_summary(x)

  .sequence_motif_assert_whole_number(
    digits,
    "digits",
    minimum = 0L
  )

  if (digits > 15L) {
    stop("`digits` must not exceed 15.", call. = FALSE)
  }

  .sequence_assert_flag(include_rank, "include_rank")

  position_units <- .sequence_motif_match_arg(
    position_units,
    c("proportion", "percent"),
    "position_units"
  )

  by <- x$settings$by
  table <- x$summary
  table <- .sequence_motif_position_sort(table, by)

  if (include_rank) {
    rank_values <- integer(nrow(table))

    if (nrow(table) > 0L) {
      groups <- if (length(by) == 0L) {
        list(seq_len(nrow(table)))
      } else {
        split(
          seq_len(nrow(table)),
          .sequence_motif_group_factor(table, by)
        )
      }

      for (indices in groups) {
        rank_values[indices] <- as.integer(
          rank(
            table$mean_position[indices],
            ties.method = "min"
          )
        )
      }
    }

    table$rank <- rank_values
  }

  position_columns <- c(
    "min_position",
    "max_position",
    "mean_position",
    "median_position"
  )

  applied_units <- if (identical(x$settings$scale, "relative")) {
    position_units
  } else {
    "index"
  }

  if (
    nrow(table) > 0L &&
      identical(x$settings$scale, "relative") &&
      identical(position_units, "percent")
  ) {
    for (column in position_columns) {
      table[[column]] <- 100 * table[[column]]
    }
  }

  for (column in position_columns) {
    table[[column]] <- round(table[[column]], digits = digits)
  }

  table$position_unit <- applied_units

  front <- c(
    by,
    if (include_rank) "rank",
    "motif_id",
    "motif_key",
    "motif",
    "motif_length",
    "position_basis",
    "position_scale",
    "position_unit",
    "n_occurrences",
    "n_sequences"
  )

  table <- table[c(front, setdiff(names(table), front))]
  row.names(table) <- NULL

  list(
    table = table,
    audit = x$audit,
    status = x$status,
    mapping = x$mapping,
    source_settings = x$settings,
    settings = list(
      digits = as.integer(digits),
      requested_position_units = position_units,
      applied_position_units = applied_units,
      include_rank = include_rank,
      rank_metric = "mean_position",
      rank_direction = "earlier_to_later"
    )
  )
}

#' Plot Sequence Motif Summaries
#'
#' Draws a dependency-free base-R bar chart of structural motif measurements.
#'
#' @param x A motif extraction, summary, or filtered-motif object.
#' @param metric Structural metric to plot: `"sequence_prevalence"`,
#'   `"n_occurrences"`, `"n_sequences"`, or `"occurrence_share"`.
#' @param top_n Positive whole number giving the requested number of motifs.
#' @param motif_lengths Optional vector of positive whole-number motif lengths
#'   to retain.
#' @param ties Top-`n` boundary policy. `"include"` retains all motifs tied on
#'   the selected metric; `"first"` retains exactly `top_n` after deterministic
#'   secondary sorting.
#' @param horizontal Logical value indicating whether bars should be horizontal.
#'
#' @return Invisibly returns the exact motif table used for plotting, including
#' `plot_rank`, `plot_value`, `plot_label`, and `bar_midpoint`.
#'
#' @details
#' The plot is descriptive. It does not perform inferential testing or assign
#' substantive meaning to motif frequency or prevalence. Empty inputs produce
#' an informative blank plot and return an empty table.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c(rep("s1", 5L), rep("s2", 4L)),
#'   position = c(1:5, 1:4),
#'   state = c("A", "B", "A", "B", "C", "A", "B", "C", "B")
#' )
#'
#' extracted <- extract_sequence_ngrams(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state"
#' )
#'
#' plot_sequence_motifs(
#'   extracted,
#'   metric = "sequence_prevalence",
#'   top_n = 10
#' )
#'
#' @export
plot_sequence_motifs <- function(
  x,
  metric = c(
    "sequence_prevalence",
    "n_occurrences",
    "n_sequences",
    "occurrence_share"
  ),
  top_n = 20L,
  motif_lengths = NULL,
  ties = c("include", "first"),
  horizontal = TRUE
) {
  metric <- .sequence_motif_match_arg(
    metric,
    c(
      "sequence_prevalence",
      "n_occurrences",
      "n_sequences",
      "occurrence_share"
    ),
    "metric"
  )

  ties <- .sequence_motif_match_arg(
    ties,
    c("include", "first"),
    "ties"
  )

  .sequence_assert_flag(horizontal, "horizontal")

  plot_data <- .sequence_motif_plot_data(
    x = x,
    type = "motifs",
    metric = metric,
    motif_lengths = motif_lengths,
    top_n = top_n,
    ties = ties
  )

  axis_label <- .sequence_motif_plot_metric_label(metric)

  if (nrow(plot_data) == 0L) {
    .sequence_motif_plot_empty(
      "No motifs match the requested plotting settings.",
      "Sequence motifs",
      axis_label
    )
    plot_data$bar_midpoint <- double()
    return(invisible(plot_data))
  }

  old_parameters <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old_parameters), add = TRUE)

  if (horizontal) {
    label_width <- max(nchar(plot_data$plot_label), na.rm = TRUE)
    left_margin <- min(16, max(5.1, 3.5 + 0.13 * label_width))

    graphics::par(
      mar = c(5.1, left_margin, 4.1, 2.1)
    )

    reverse_index <- rev(seq_len(nrow(plot_data)))

    midpoint <- graphics::barplot(
      height = plot_data$plot_value[reverse_index],
      names.arg = plot_data$plot_label[reverse_index],
      horiz = TRUE,
      las = 1,
      xlab = axis_label,
      ylab = "",
      main = "Sequence motifs"
    )

    plot_data$bar_midpoint <- rev(as.numeric(midpoint))
  } else {
    bottom_margin <- min(
      16,
      max(6.1, 4.5 + 0.13 * max(nchar(plot_data$plot_label)))
    )

    graphics::par(
      mar = c(bottom_margin, 5.1, 4.1, 2.1)
    )

    midpoint <- graphics::barplot(
      height = plot_data$plot_value,
      names.arg = plot_data$plot_label,
      horiz = FALSE,
      las = 2,
      xlab = "",
      ylab = axis_label,
      main = "Sequence motifs"
    )

    plot_data$bar_midpoint <- as.numeric(midpoint)
  }

  invisible(plot_data)
}

#' Plot Sequence Motif Positions
#'
#' Shows occurrence locations for selected contiguous motifs.
#'
#' @param x An object returned by `extract_sequence_ngrams()` or
#'   `summarise_sequence_motif_positions()`.
#' @param motifs Optional character vector of motif identifiers, motif keys, or
#'   displayed motif labels. When omitted, motifs are selected deterministically
#'   by occurrence count, sequence count, motif length, and motif key.
#' @param position Occurrence position represented by motif `"start"`,
#'   `"centre"`, or `"end"`.
#' @param scale Position scale: one-based `"absolute"` sequence positions or
#'   `"relative"` positions from 0 to 1.
#' @param top_n Positive whole number giving the number of motifs selected when
#'   `motifs` is `NULL`.
#' @param display Base-R display type: occurrence `"strip"` or
#'   `"distribution"` boxplots.
#'
#' @return Invisibly returns the exact occurrence-level data used by the plot,
#' including deterministic motif ranks and plotting coordinates where relevant.
#'
#' @details
#' The strip display uses deterministic vertical stacking rather than random
#' jitter. The distribution display uses one horizontal boxplot per motif.
#' Empty inputs produce an informative blank plot and return an empty table.
#' The function provides structural location summaries only.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c(rep("s1", 5L), rep("s2", 4L)),
#'   position = c(1:5, 1:4),
#'   state = c("A", "B", "A", "B", "C", "A", "B", "C", "B")
#' )
#'
#' extracted <- extract_sequence_ngrams(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state"
#' )
#'
#' plot_sequence_motif_positions(
#'   extracted,
#'   position = "centre",
#'   scale = "relative",
#'   top_n = 5,
#'   display = "strip"
#' )
#'
#' @export
plot_sequence_motif_positions <- function(
  x,
  motifs = NULL,
  position = c("start", "centre", "end"),
  scale = c("absolute", "relative"),
  top_n = 10L,
  display = c("strip", "distribution")
) {
  position <- .sequence_motif_match_arg(
    position,
    c("start", "centre", "end"),
    "position"
  )

  scale <- .sequence_motif_match_arg(
    scale,
    c("absolute", "relative"),
    "scale"
  )

  display <- .sequence_motif_match_arg(
    display,
    c("strip", "distribution"),
    "display"
  )

  plot_data <- .sequence_motif_plot_data(
    x = x,
    type = "positions",
    motifs = motifs,
    position = position,
    scale = scale,
    top_n = top_n
  )

  position_label <- paste0(
    toupper(substr(position, 1L, 1L)),
    substring(position, 2L)
  )

  axis_label <- if (scale == "relative") {
    paste0(
      position_label,
      " position within sequence (0 to 1)"
    )
  } else {
    paste0(
      position_label,
      " position (one-based state index)"
    )
  }

  if (nrow(plot_data) == 0L) {
    .sequence_motif_plot_empty(
      "No motif occurrences match the requested plotting settings.",
      "Sequence motif positions",
      axis_label
    )
    plot_data$plot_y <- double()
    return(invisible(plot_data))
  }

  motif_table <- attr(plot_data, "motif_table")
  selected_ids <- motif_table$motif_id
  selected_labels <- motif_table$motif
  n_motifs <- nrow(motif_table)

  old_parameters <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old_parameters), add = TRUE)

  label_width <- max(nchar(selected_labels), na.rm = TRUE)
  left_margin <- min(16, max(5.1, 3.5 + 0.13 * label_width))

  graphics::par(
    mar = c(5.1, left_margin, 4.1, 2.1)
  )

  x_values <- plot_data$position_value

  if (scale == "relative") {
    x_limits <- c(0, 1)
  } else {
    value_range <- range(x_values, finite = TRUE)

    if (diff(value_range) == 0) {
      padding <- max(0.5, abs(value_range[1L]) * 0.04)
    } else {
      padding <- 0.04 * diff(value_range)
    }

    x_limits <- value_range + c(-padding, padding)
  }

  if (display == "strip") {
    base_y <- n_motifs - plot_data$plot_rank + 1L
    duplicate_group <- interaction(
      plot_data$motif_id,
      format(plot_data$position_value, digits = 15, trim = TRUE),
      drop = TRUE,
      lex.order = TRUE
    )

    stack_index <- stats::ave(
      seq_len(nrow(plot_data)),
      duplicate_group,
      FUN = seq_along
    )

    stack_size <- stats::ave(
      seq_len(nrow(plot_data)),
      duplicate_group,
      FUN = length
    )

    offset <- (stack_index - (stack_size + 1) / 2) * 0.06
    plot_data$plot_y <- base_y + offset

    graphics::plot(
      x = plot_data$position_value,
      y = plot_data$plot_y,
      xlim = x_limits,
      ylim = c(0.5, n_motifs + 0.5),
      xlab = axis_label,
      ylab = "",
      yaxt = "n",
      main = "Sequence motif positions",
      type = "n"
    )

    graphics::axis(
      side = 2,
      at = seq_len(n_motifs),
      labels = rev(selected_labels),
      las = 1
    )

    graphics::abline(
      h = seq_len(n_motifs),
      lty = 3
    )

    graphics::points(
      x = plot_data$position_value,
      y = plot_data$plot_y,
      pch = 16
    )
  } else {
    value_list <- lapply(
      rev(selected_ids),
      function(motif_id) {
        plot_data$position_value[plot_data$motif_id == motif_id]
      }
    )

    names(value_list) <- rev(selected_labels)

    graphics::boxplot(
      value_list,
      horizontal = TRUE,
      las = 1,
      xlim = x_limits,
      xlab = axis_label,
      ylab = "",
      main = "Sequence motif position distributions"
    )

    plot_data$plot_y <- n_motifs - plot_data$plot_rank + 1L
  }

  attr(plot_data, "motif_table") <- motif_table
  invisible(plot_data)
}
