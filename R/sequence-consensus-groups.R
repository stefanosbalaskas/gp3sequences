#' Create an aligned-position consensus sequence
#'
#' Computes a descriptive consensus state at each observed sequence position.
#' The function does not treat the consensus as a behavioural norm and does not
#' infer psychological or causal meaning.
#'
#' @param data A long-format data frame, a prepared gp3sequences result, or a
#'   data frame containing canonical columns.
#' @param sequence_id_col,order_col,state_col Column names defining sequences.
#' @param group_cols Optional columns defining independent consensus groups.
#' @param weight_col Optional non-negative row-weight column.
#' @param missing_state_policy One of `"exclude"`, `"state"`, or `"error"`.
#' @param missing_state_label Label used when missing states are retained.
#' @param tie_method Deterministic tie policy: `"first"`, `"last"`,
#'   `"missing"`, or `"all"`.
#' @param state_levels Optional preferred state ordering used for ties.
#' @param min_support Minimum number of contributing sequences at a position.
#'
#' @return A data frame of class `gp3_consensus_sequence` containing group
#'   columns, sequence position, consensus state, support counts and weights,
#'   agreement proportion, tie count, tied states, and total group sequences.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' create_consensus_sequence(sequences, group_cols = "group")
#'
#' @export
create_consensus_sequence <- function(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  group_cols = NULL,
  weight_col = NULL,
  missing_state_policy = c("exclude", "state", "error"),
  missing_state_label = "<MISSING>",
  tie_method = c("first", "last", "missing", "all"),
  state_levels = NULL,
  min_support = 1L
) {
  missing_state_policy <- match.arg(missing_state_policy)
  tie_method <- match.arg(tie_method)
  .sequence_adv_scalar_number(min_support, "min_support", lower = 1, integer = TRUE)
  missing_input_policy <- switch(missing_state_policy,
                                 exclude = "drop", state = "state", error = "error")
  x <- .sequence_adv_data(
    data = data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    metadata_cols = group_cols,
    missing_state_policy = missing_input_policy,
    missing_state_label = missing_state_label
  )
  group_cols <- .sequence_adv_match_cols(x$data, group_cols, "group_cols")
  if (!is.null(weight_col)) {
    .sequence_adv_scalar_character(weight_col, "weight_col")
    if (!(weight_col %in% names(x$data))) stop("`weight_col` is absent from `data`.", call. = FALSE)
    weights <- x$data[[weight_col]]
    if (!is.numeric(weights) || anyNA(weights) || any(!is.finite(weights)) || any(weights < 0)) {
      stop("`weight_col` must contain finite, non-negative numeric values.", call. = FALSE)
    }
  } else {
    weights <- rep(1, nrow(x$data))
  }
  working <- x$data
  working$.gp3_adv_weight <- weights
  working$.gp3_adv_group <- .sequence_adv_group_key(working, group_cols)
  state_order <- .sequence_adv_state_order(working[[state_col]], state_levels)
  groups <- split(seq_len(nrow(working)), working$.gp3_adv_group, drop = TRUE)
  output <- list()
  output_index <- 0L
  for (group_key in names(groups)) {
    rows_group <- groups[[group_key]]
    group_data <- working[rows_group, , drop = FALSE]
    positions <- sort(unique(group_data[[order_col]]))
    n_group_sequences <- length(unique(as.character(group_data[[sequence_id_col]])))
    for (position in positions) {
      rows <- rows_group[working[[order_col]][rows_group] == position]
      states <- as.character(working[[state_col]][rows])
      current_weights <- working$.gp3_adv_weight[rows]
      contributing <- current_weights > 0
      states <- states[contributing]
      current_weights <- current_weights[contributing]
      support_n <- length(unique(as.character(working[[sequence_id_col]][rows][contributing])))
      if (support_n < min_support || length(states) == 0L) next
      tie <- .sequence_adv_tie(states, current_weights, state_order, tie_method)
      output_index <- output_index + 1L
      group_values <- if (length(group_cols) == 0L) {
        .sequence_adv_zero_column_frame(1L)
      } else {
        group_data[1L, group_cols, drop = FALSE]
      }
      output[[output_index]] <- cbind(
        group_values,
        data.frame(
          sequence_order = position,
          consensus_state = tie$selected,
          support_n = as.integer(support_n),
          support_weight = sum(current_weights),
          agreement = tie$agreement,
          tie_n = as.integer(length(tie$tied)),
          tied_states = paste(tie$tied, collapse = " | "),
          n_sequences = as.integer(n_group_sequences),
          stringsAsFactors = FALSE,
          check.names = FALSE
        )
      )
    }
  }
  if (length(output) == 0L) {
    prefix <- if (length(group_cols) == 0L) {
      .sequence_adv_zero_column_frame(0L)
    } else {
      x$data[0L, group_cols, drop = FALSE]
    }
    result <- cbind(
      prefix,
      data.frame(
        sequence_order = numeric(), consensus_state = character(), support_n = integer(),
        support_weight = numeric(), agreement = numeric(), tie_n = integer(),
        tied_states = character(), n_sequences = integer(), stringsAsFactors = FALSE,
        check.names = FALSE
      )
    )
  } else {
    result <- do.call(rbind, output)
    row.names(result) <- NULL
  }
  class(result) <- c("gp3_consensus_sequence", "data.frame")
  attr(result, "group_cols") <- group_cols
  attr(result, "state_levels") <- state_order
  attr(result, "settings") <- list(
    missing_state_policy = missing_state_policy,
    missing_state_label = missing_state_label,
    tie_method = tie_method,
    min_support = as.integer(min_support),
    weight_col = weight_col
  )
  result
}

#' Summarise consensus agreement
#'
#' @param consensus A result from [create_consensus_sequence()].
#' @param by Summary level: `"overall"`, `"group"`, or `"position"`.
#' @param threshold Agreement threshold used to count low-agreement positions.
#'
#' @return A data frame with position counts, mean, median, minimum and maximum
#'   agreement, weighted agreement, tie counts, and low-agreement counts.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' consensus <- create_consensus_sequence(sequences)
#' summarise_consensus_agreement(consensus)
#'
#' @export
summarise_consensus_agreement <- function(consensus,
                                          by = c("overall", "group", "position"),
                                          threshold = 0.5) {
  by <- match.arg(by)
  .sequence_adv_scalar_number(threshold, "threshold", lower = 0, upper = 1)
  if (!inherits(consensus, "gp3_consensus_sequence") || !is.data.frame(consensus)) {
    stop("`consensus` must be created by `create_consensus_sequence()`.", call. = FALSE)
  }
  group_cols <- attr(consensus, "group_cols")
  if (by == "group" && length(group_cols) == 0L) {
    stop("`by = \"group\"` requires a consensus created with `group_cols`.",
         call. = FALSE)
  }
  split_cols <- switch(by, overall = character(), group = group_cols,
                       position = c(group_cols, "sequence_order"))
  if (nrow(consensus) == 0L) {
    prefix <- if (length(split_cols) == 0L) {
      .sequence_adv_zero_column_frame(0L)
    } else {
      consensus[0L, split_cols, drop = FALSE]
    }
    return(cbind(
      prefix,
      data.frame(
        n_positions = integer(), mean_agreement = numeric(), median_agreement = numeric(),
        min_agreement = numeric(), max_agreement = numeric(), weighted_agreement = numeric(),
        n_ties = integer(), n_below_threshold = integer(), threshold = numeric(),
        stringsAsFactors = FALSE, check.names = FALSE
      )
    ))
  }
  key <- .sequence_adv_group_key(consensus, split_cols)
  pieces <- split(seq_len(nrow(consensus)), key, drop = TRUE)
  result <- lapply(pieces, function(rows) {
    prefix <- if (length(split_cols) == 0L) {
      .sequence_adv_zero_column_frame(1L)
    } else {
      consensus[rows[1L], split_cols, drop = FALSE]
    }
    weighted <- if (sum(consensus$support_weight[rows]) > 0) {
      stats::weighted.mean(consensus$agreement[rows], consensus$support_weight[rows])
    } else NA_real_
    cbind(prefix, data.frame(
      n_positions = as.integer(length(rows)),
      mean_agreement = mean(consensus$agreement[rows]),
      median_agreement = stats::median(consensus$agreement[rows]),
      min_agreement = min(consensus$agreement[rows]),
      max_agreement = max(consensus$agreement[rows]),
      weighted_agreement = weighted,
      n_ties = as.integer(sum(consensus$tie_n[rows] > 1L)),
      n_below_threshold = as.integer(sum(consensus$agreement[rows] < threshold)),
      threshold = threshold,
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
  })
  out <- do.call(rbind, result)
  row.names(out) <- NULL
  out
}

#' Format consensus sequences as paths
#'
#' @param consensus A consensus result.
#' @param separator State separator.
#' @param include_order Include position labels.
#' @param include_agreement Include rounded agreement values.
#' @param digits Number of decimal places for agreement values.
#'
#' @return One row per consensus group with a formatted path and position count.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' consensus <- create_consensus_sequence(sequences)
#' format_consensus_sequence(consensus)
#'
#' @export
format_consensus_sequence <- function(consensus, separator = " -> ",
                                      include_order = FALSE,
                                      include_agreement = FALSE,
                                      digits = 3L) {
  if (!inherits(consensus, "gp3_consensus_sequence")) {
    stop("`consensus` must be created by `create_consensus_sequence()`.", call. = FALSE)
  }
  .sequence_adv_scalar_character(separator, "separator")
  .sequence_adv_scalar_logical(include_order, "include_order")
  .sequence_adv_scalar_logical(include_agreement, "include_agreement")
  .sequence_adv_scalar_number(digits, "digits", lower = 0, integer = TRUE)
  group_cols <- attr(consensus, "group_cols")
  if (nrow(consensus) == 0L) {
    prefix <- if (length(group_cols) == 0L) {
      .sequence_adv_zero_column_frame(0L)
    } else {
      consensus[0L, group_cols, drop = FALSE]
    }
    return(cbind(
      prefix,
      data.frame(path = character(), n_positions = integer(),
                 stringsAsFactors = FALSE, check.names = FALSE)
    ))
  }
  key <- .sequence_adv_group_key(consensus, group_cols)
  pieces <- split(seq_len(nrow(consensus)), key, drop = TRUE)
  result <- lapply(pieces, function(rows) {
    rows <- rows[order(consensus$sequence_order[rows], method = "radix")]
    labels <- consensus$consensus_state[rows]
    labels[is.na(labels)] <- "<TIE>"
    if (include_order) labels <- paste0(consensus$sequence_order[rows], ":", labels)
    if (include_agreement) labels <- paste0(labels, " [", format(round(consensus$agreement[rows], digits),
                                                                 nsmall = digits), "]")
    prefix <- if (length(group_cols) == 0L) {
      .sequence_adv_zero_column_frame(1L)
    } else {
      consensus[rows[1L], group_cols, drop = FALSE]
    }
    cbind(prefix, data.frame(path = paste(labels, collapse = separator),
                             n_positions = as.integer(length(rows)),
                             stringsAsFactors = FALSE, check.names = FALSE))
  })
  out <- do.call(rbind, result)
  row.names(out) <- NULL
  out
}

#' Plot a consensus sequence
#'
#' @param consensus A consensus result.
#' @param type `"agreement"` or `"states"`.
#' @param group Optional group value, encoded group key, or named list of
#'   values when grouped consensus was created. It is required when more than one
#'   consensus group is present.
#' @param main,xlab,ylab Plot labels.
#' @param ... Additional arguments passed to base graphics.
#'
#' @return The plotted data, invisibly.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' consensus <- create_consensus_sequence(sequences)
#' plot_consensus_sequence(consensus)
#'
#' @export
plot_consensus_sequence <- function(consensus, type = c("agreement", "states"),
                                    group = NULL, main = NULL,
                                    xlab = "Sequence position", ylab = NULL, ...) {
  type <- match.arg(type)
  if (!inherits(consensus, "gp3_consensus_sequence")) {
    stop("`consensus` must be created by `create_consensus_sequence()`.", call. = FALSE)
  }
  data <- consensus
  group_cols <- attr(consensus, "group_cols")
  keys <- .sequence_adv_group_key(data, group_cols)
  available_keys <- unique(keys)
  if (length(group_cols) > 0L && length(available_keys) > 1L && is.null(group)) {
    stop("Select one consensus group before plotting grouped results.", call. = FALSE)
  }
  if (!is.null(group)) {
    if (is.list(group)) {
      if (is.null(names(group)) || !setequal(names(group), group_cols) ||
          any(lengths(group) != 1L)) {
        stop("A list-valued `group` must provide one named value per group column.",
             call. = FALSE)
      }
      selected <- rep(TRUE, nrow(data))
      for (column in group_cols) {
        observed <- as.character(data[[column]])
        target <- as.character(group[[column]])
        selected <- selected & if (is.na(group[[column]])) is.na(data[[column]]) else
          !is.na(observed) & observed == target
      }
      data <- data[selected, , drop = FALSE]
    } else {
      .sequence_adv_scalar_character(as.character(group), "group")
      data <- data[keys == as.character(group), , drop = FALSE]
    }
  }
  if (nrow(data) == 0L) stop("No consensus positions are available to plot.", call. = FALSE)
  data <- data[order(data$sequence_order, method = "radix"), , drop = FALSE]
  if (type == "agreement") {
    if (is.null(main)) main <- "Consensus agreement by position"
    if (is.null(ylab)) ylab <- "Agreement proportion"
    graphics::plot(data$sequence_order, data$agreement, type = "b", ylim = c(0, 1),
                   xlab = xlab, ylab = ylab, main = main, ...)
    graphics::abline(h = c(0.5, 1), lty = c(3, 2))
  } else {
    if (is.null(main)) main <- "Consensus states by position"
    if (is.null(ylab)) ylab <- "Consensus state"
    display_state <- as.character(data$consensus_state)
    display_state[is.na(display_state)] <- "<TIE>"
    levels <- .sequence_adv_state_order(display_state, attr(consensus, "state_levels"))
    y <- match(display_state, levels)
    graphics::plot(data$sequence_order, y, type = "b", yaxt = "n", xlab = xlab,
                   ylab = ylab, main = main, ...)
    graphics::axis(2, at = seq_along(levels), labels = levels, las = 1)
  }
  invisible(data)
}

#' Compare sequence groups descriptively
#'
#' Produces descriptive state, transition and sequence-length comparisons.
#' No hypothesis tests or causal interpretations are produced.
#'
#' @param data Long-format sequence data.
#' @param group_col Grouping column that is constant within sequence.
#' @param sequence_id_col,order_col,state_col Sequence columns.
#' @param reference Optional reference group. When supplied, each other
#'   group is reported as `group_1` and the reference as `group_2`; differences
#'   and ratios are therefore other-minus-reference and other/reference. When
#'   omitted, all pairwise group contrasts are returned.
#' @param metrics Any of `"state"`, `"transition"`, and `"length"`.
#' @param include_self Include self-transitions.
#' @param transition_separator Separator used in reported transition labels. It
#'   must not occur inside an observed state label.
#' @param zero_policy Ratio policy when the reference value is zero.
#'
#' @return A list of class `gp3_sequence_group_comparison` containing group
#' summaries and pairwise descriptive contrasts.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' compare_sequence_groups(sequences, group_col = "group")
#'
#' @export
compare_sequence_groups <- function(
  data,
  group_col,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  reference = NULL,
  metrics = c("state", "transition", "length"),
  include_self = TRUE,
  transition_separator = " -> ",
  zero_policy = c("missing", "infinite")
) {
  zero_policy <- match.arg(zero_policy)
  metrics <- unique(match.arg(metrics, c("state", "transition", "length"), several.ok = TRUE))
  if (length(metrics) == 0L) stop("Select at least one comparison metric.", call. = FALSE)
  .sequence_adv_scalar_logical(include_self, "include_self")
  .sequence_adv_scalar_character(transition_separator, "transition_separator")
  .sequence_adv_scalar_character(group_col, "group_col")
  x <- .sequence_adv_data(data, sequence_id_col, order_col, state_col,
                          metadata_cols = group_col, missing_state_policy = "error")
  if (any(grepl(transition_separator, x$state_levels, fixed = TRUE))) {
    stop("`transition_separator` must not occur inside an observed state label.",
         call. = FALSE)
  }
  group_map <- x$metadata
  names(group_map)[names(group_map) == sequence_id_col] <- ".sequence_id"
  names(group_map)[names(group_map) == group_col] <- ".group"
  group_text <- as.character(group_map$.group)
  if (any(is.na(group_map$.group) | trimws(group_text) == "")) {
    stop("The grouping column must be non-missing and non-blank for every sequence.",
         call. = FALSE)
  }
  if (!is.null(reference)) {
    .sequence_adv_scalar_character(as.character(reference), "reference")
  }
  groups <- unique(group_text)
  groups <- sort(groups, method = "radix")
  if (length(groups) < 2L) stop("At least two sequence groups are required.", call. = FALSE)
  if (!is.null(reference) && !(as.character(reference) %in% groups)) {
    stop("`reference` is not an observed group.", call. = FALSE)
  }
  sequence_group <- stats::setNames(as.character(group_map$.group), as.character(group_map$.sequence_id))
  group_n <- table(factor(sequence_group, levels = groups))
  state_rows <- list()
  transition_rows <- list()
  length_rows <- list()
  for (g in groups) {
    ids <- names(sequence_group)[sequence_group == g]
    seqs <- x$sequences[ids]
    states_all <- unlist(seqs, use.names = FALSE)
    state_count <- table(factor(states_all, levels = x$state_levels))
    state_sequence_count <- vapply(x$state_levels, function(s) sum(vapply(seqs, function(z) s %in% z, logical(1))), integer(1))
    state_rows[[g]] <- data.frame(
      group = g, state = x$state_levels, event_count = as.integer(state_count),
      event_share = as.numeric(state_count) / max(1, sum(state_count)),
      sequence_count = as.integer(state_sequence_count),
      sequence_prevalence = as.numeric(state_sequence_count) / length(seqs),
      stringsAsFactors = FALSE
    )
    transitions <- unlist(lapply(seqs, function(z) {
      if (length(z) < 2L) return(character())
      paste(z[-length(z)], z[-1L], sep = transition_separator)
    }), use.names = FALSE)
    if (!include_self && length(transitions) > 0L) {
      parts <- strsplit(transitions, transition_separator, fixed = TRUE)
      transitions <- transitions[vapply(parts, function(p) p[1L] != p[2L], logical(1))]
    }
    transition_levels <- sort(unique(transitions), method = "radix")
    if (length(transition_levels) > 0L) {
      transition_count <- table(factor(transitions, levels = transition_levels))
      transition_sequence_count <- vapply(transition_levels, function(tr) {
        sum(vapply(seqs, function(z) {
          if (length(z) < 2L) return(FALSE)
          tr %in% paste(z[-length(z)], z[-1L], sep = transition_separator)
        }, logical(1)))
      }, integer(1))
      transition_rows[[g]] <- data.frame(
        group = g, transition = transition_levels,
        occurrence_count = as.integer(transition_count),
        occurrence_share = as.numeric(transition_count) / max(1, sum(transition_count)),
        sequence_count = as.integer(transition_sequence_count),
        sequence_prevalence = as.numeric(transition_sequence_count) / length(seqs),
        stringsAsFactors = FALSE
      )
    }
    lengths <- lengths(seqs)
    length_rows[[g]] <- data.frame(
      group = g, n_sequences = length(lengths), mean_length = mean(lengths),
      median_length = stats::median(lengths), min_length = min(lengths),
      max_length = max(lengths), sd_length = if (length(lengths) > 1L) stats::sd(lengths) else 0,
      stringsAsFactors = FALSE
    )
  }
  state_summary <- do.call(rbind, state_rows)
  transition_summary <- if (length(transition_rows) > 0L) do.call(rbind, transition_rows) else
    data.frame(group = character(), transition = character(), occurrence_count = integer(),
               occurrence_share = numeric(), sequence_count = integer(),
               sequence_prevalence = numeric(), stringsAsFactors = FALSE)
  length_summary <- do.call(rbind, length_rows)
  pair_matrix <- if (is.null(reference)) {
    .sequence_adv_pair_grid(groups)
  } else {
    cbind(setdiff(seq_along(groups), match(as.character(reference), groups)),
          match(as.character(reference), groups))
  }
  make_contrasts <- function(summary, key_col, measures) {
    if (nrow(pair_matrix) == 0L || nrow(summary) == 0L) return(data.frame())
    keys <- unique(as.character(summary[[key_col]]))
    out <- list(); h <- 0L
    for (r in seq_len(nrow(pair_matrix))) {
      g1 <- groups[pair_matrix[r, 1L]]; g2 <- groups[pair_matrix[r, 2L]]
      for (key in keys) {
        a <- summary[summary$group == g1 & summary[[key_col]] == key, , drop = FALSE]
        b <- summary[summary$group == g2 & summary[[key_col]] == key, , drop = FALSE]
        if (nrow(a) == 0L) a <- summary[0L, , drop = FALSE]
        if (nrow(b) == 0L) b <- summary[0L, , drop = FALSE]
        h <- h + 1L
        row <- data.frame(group_1 = g1, group_2 = g2, stringsAsFactors = FALSE)
        row[[key_col]] <- key
        for (measure in measures) {
          va <- if (nrow(a) == 0L) 0 else a[[measure]][1L]
          vb <- if (nrow(b) == 0L) 0 else b[[measure]][1L]
          ratio <- if (vb == 0) {
            if (zero_policy == "infinite" && va > 0) Inf else NA_real_
          } else va / vb
          row[[paste0(measure, "_group_1")]] <- va
          row[[paste0(measure, "_group_2")]] <- vb
          row[[paste0(measure, "_difference")]] <- va - vb
          row[[paste0(measure, "_ratio")]] <- ratio
        }
        out[[h]] <- row
      }
    }
    do.call(rbind, out)
  }
  state_contrasts <- make_contrasts(state_summary, "state",
                                    c("event_share", "sequence_prevalence"))
  transition_contrasts <- make_contrasts(transition_summary, "transition",
                                         c("occurrence_share", "sequence_prevalence"))
  length_contrasts <- if (nrow(pair_matrix) == 0L) data.frame() else do.call(rbind, lapply(seq_len(nrow(pair_matrix)), function(r) {
    g1 <- groups[pair_matrix[r, 1L]]; g2 <- groups[pair_matrix[r, 2L]]
    a <- length_summary[length_summary$group == g1, , drop = FALSE]
    b <- length_summary[length_summary$group == g2, , drop = FALSE]
    data.frame(group_1 = g1, group_2 = g2,
               mean_length_group_1 = a$mean_length, mean_length_group_2 = b$mean_length,
               mean_length_difference = a$mean_length - b$mean_length,
               median_length_group_1 = a$median_length, median_length_group_2 = b$median_length,
               median_length_difference = a$median_length - b$median_length,
               stringsAsFactors = FALSE)
  }))
  result <- list(
    groups = data.frame(group = groups, n_sequences = as.integer(group_n), stringsAsFactors = FALSE),
    state_summary = if ("state" %in% metrics) state_summary else NULL,
    state_contrasts = if ("state" %in% metrics) state_contrasts else NULL,
    transition_summary = if ("transition" %in% metrics) transition_summary else NULL,
    transition_contrasts = if ("transition" %in% metrics) transition_contrasts else NULL,
    length_summary = if ("length" %in% metrics) length_summary else NULL,
    length_contrasts = if ("length" %in% metrics) length_contrasts else NULL,
    settings = list(reference = reference, metrics = metrics, include_self = include_self,
                    transition_separator = transition_separator, zero_policy = zero_policy)
  )
  class(result) <- c("gp3_sequence_group_comparison", "list")
  result
}

#' Plot a descriptive sequence-group comparison
#'
#' @param comparison A result from [compare_sequence_groups()].
#' @param component `"state"`, `"transition"`, or `"length"`.
#' @param measure Measure to display. Defaults depend on `component`.
#' @param top_n Maximum states or transitions to display.
#' @param main,xlab,ylab Plot labels.
#' @param ... Additional base-graphics arguments.
#'
#' @return The plotted summary data, invisibly.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' comparison <- compare_sequence_groups(sequences, group_col = "group")
#' plot_sequence_group_comparison(comparison, component = "state")
#'
#' @export
plot_sequence_group_comparison <- function(comparison,
                                           component = c("state", "transition", "length"),
                                           measure = NULL, top_n = 12L,
                                           main = NULL, xlab = NULL, ylab = NULL, ...) {
  component <- match.arg(component)
  .sequence_adv_scalar_number(top_n, "top_n", lower = 1, integer = TRUE)
  if (!inherits(comparison, "gp3_sequence_group_comparison")) {
    stop("`comparison` must be created by `compare_sequence_groups()`.", call. = FALSE)
  }
  if (component == "length") {
    data <- comparison$length_summary
    if (is.null(data)) stop("Length summaries were not requested.", call. = FALSE)
    if (is.null(measure)) measure <- "mean_length"
    if (!(measure %in% names(data))) stop("Unknown length measure.", call. = FALSE)
    if (is.null(main)) main <- "Sequence length by group"
    if (is.null(xlab)) xlab <- "Group"
    if (is.null(ylab)) ylab <- measure
    graphics::barplot(data[[measure]], names.arg = data$group, main = main,
                      xlab = xlab, ylab = ylab, ...)
    return(invisible(data))
  }
  data <- if (component == "state") comparison$state_summary else comparison$transition_summary
  if (is.null(data)) stop("The requested component was not calculated.", call. = FALSE)
  if (nrow(data) == 0L) stop("No comparison rows are available to plot.", call. = FALSE)
  key <- if (component == "state") "state" else "transition"
  if (is.null(measure)) measure <- "sequence_prevalence"
  if (!(measure %in% names(data))) stop("Unknown comparison measure.", call. = FALSE)
  totals <- stats::aggregate(data[[measure]], list(key = data[[key]]), max)
  names(totals)[2L] <- "score"
  selected <- utils::head(totals$key[order(-totals$score, totals$key, method = "radix")], top_n)
  data <- data[data[[key]] %in% selected, , drop = FALSE]
  if (nrow(data) == 0L) stop("No comparison rows are available to plot.", call. = FALSE)
  groups <- comparison$groups$group
  matrix_data <- matrix(0, nrow = length(selected), ncol = length(groups),
                        dimnames = list(selected, groups))
  for (i in seq_len(nrow(data))) matrix_data[data[[key]][i], data$group[i]] <- data[[measure]][i]
  if (is.null(main)) main <- paste("Sequence", component, "comparison")
  if (is.null(xlab)) xlab <- measure
  if (is.null(ylab)) ylab <- component
  graphics::barplot(t(matrix_data), beside = TRUE, horiz = TRUE, legend.text = groups,
                    main = main, xlab = xlab, ylab = ylab, ...)
  invisible(data)
}
