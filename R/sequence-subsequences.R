#' Extract bounded non-contiguous sequence subsequences
#'
#' Enumerates ordered non-contiguous subsequences under explicit length, gap,
#' span, and safety limits. The implementation is transparent and intended for
#' modest sequence collections; specialist mining packages remain preferable
#' for very large search spaces.
#'
#' @param data Long-format sequence data or a prepared result.
#' @param sequence_id_col,order_col,state_col Core sequence columns.
#' @param metadata_cols Optional sequence-constant metadata retained as
#'   attributes.
#' @param min_length,max_length Minimum and maximum subsequence lengths.
#' @param max_gap Maximum number of skipped positions between adjacent selected
#'   states. Use `Inf` for no restriction.
#' @param max_span Maximum difference between the first and last selected
#'   sequence positions. Use `Inf` for no restriction.
#' @param repeated_state_policy Preserve or collapse consecutive repeated
#'   states before mining.
#' @param separator Separator used in stable motif labels.
#' @param max_combinations_per_sequence Safety limit for the number of index
#'   combinations considered for any one sequence.
#'
#' @return A data frame of class `gp3_sequence_subsequences`, with one row per
#'   qualifying occurrence.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2"), each = 5L),
#'   sequence_order = rep(1:5, times = 2L),
#'   state = c("A", "B", "C", "D", "E", "A", "C", "B", "D", "E")
#' )
#' extract_sequence_subsequences(sequences, min_length = 2L, max_length = 3L,
#'                               max_gap = 2L)
#' @export
extract_sequence_subsequences <- function(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = NULL,
  min_length = 2L,
  max_length = 5L,
  max_gap = Inf,
  max_span = Inf,
  repeated_state_policy = c("preserve", "collapse"),
  separator = " > ",
  max_combinations_per_sequence = 100000L
) {
  repeated_state_policy <- match.arg(repeated_state_policy)
  .sequence_adv_scalar_number(min_length, "min_length", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(max_length, "max_length", lower = min_length, integer = TRUE)
  if (!is.numeric(max_gap) || length(max_gap) != 1L || is.na(max_gap) || max_gap < 0) {
    stop("`max_gap` must be one non-negative number or `Inf`.", call. = FALSE)
  }
  if (!is.numeric(max_span) || length(max_span) != 1L || is.na(max_span) || max_span < 0) {
    stop("`max_span` must be one non-negative number or `Inf`.", call. = FALSE)
  }
  .sequence_adv_scalar_character(separator, "separator")
  .sequence_adv_scalar_number(max_combinations_per_sequence,
                              "max_combinations_per_sequence", lower = 1, integer = TRUE)
  x <- .sequence_adv_data(
    data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    metadata_cols = metadata_cols,
    missing_state_policy = "error"
  )
  if (any(grepl(separator, x$state_levels, fixed = TRUE))) {
    stop("`separator` must not occur inside an observed state label.", call. = FALSE)
  }
  occurrences <- list()
  h <- 0L
  for (sequence_id in x$sequence_ids) {
    states <- x$sequences[[sequence_id]]
    orders <- x$orders[[sequence_id]]
    if (repeated_state_policy == "collapse" && length(states) > 1L) {
      keep <- c(TRUE, states[-1L] != states[-length(states)])
      states <- states[keep]
      orders <- orders[keep]
    }
    n <- length(states)
    upper <- min(as.integer(max_length), n)
    if (upper < min_length) next
    expected <- 0
    for (k in seq.int(min_length, upper)) {
      log_count <- lchoose(n, k)
      if (is.finite(log_count)) expected <- expected + exp(log_count)
      if (!is.finite(expected) || expected > max_combinations_per_sequence) {
        stop(
          "The subsequence search exceeds `max_combinations_per_sequence` for sequence `",
          sequence_id, "`. Reduce `max_length` or tighten gap/span constraints.",
          call. = FALSE
        )
      }
    }
    for (k in seq.int(min_length, upper)) {
      combinations <- utils::combn(seq_len(n), k)
      if (is.null(dim(combinations))) combinations <- matrix(combinations, nrow = k)
      for (j in seq_len(ncol(combinations))) {
        indices <- combinations[, j]
        skipped <- if (length(indices) > 1L) diff(indices) - 1L else 0L
        span <- orders[indices[length(indices)]] - orders[indices[1L]]
        if (any(skipped > max_gap) || span > max_span) next
        h <- h + 1L
        occurrences[[h]] <- data.frame(
          sequence_id = sequence_id,
          subsequence = paste(states[indices], collapse = separator),
          subsequence_length = as.integer(k),
          start_order = orders[indices[1L]],
          end_order = orders[indices[length(indices)]],
          span = as.numeric(span),
          max_observed_gap = if (length(skipped)) max(skipped) else 0,
          selected_positions = paste(indices, collapse = ","),
          selected_orders = paste(orders[indices], collapse = ","),
          stringsAsFactors = FALSE
        )
      }
    }
  }
  if (length(occurrences) == 0L) {
    result <- data.frame(
      sequence_id = character(), subsequence = character(),
      subsequence_length = integer(), start_order = numeric(), end_order = numeric(),
      span = numeric(), max_observed_gap = numeric(), selected_positions = character(),
      selected_orders = character(), stringsAsFactors = FALSE
    )
  } else {
    result <- do.call(rbind, occurrences)
    result <- result[order(result$subsequence_length, result$subsequence,
                           result$sequence_id, result$start_order,
                           result$selected_positions, method = "radix"), , drop = FALSE]
    row.names(result) <- NULL
  }
  class(result) <- c("gp3_sequence_subsequences", "data.frame")
  attr(result, "sequence_ids") <- x$sequence_ids
  attr(result, "n_sequences") <- length(x$sequence_ids)
  attr(result, "state_levels") <- x$state_levels
  attr(result, "metadata") <- x$metadata
  attr(result, "metadata_cols") <- metadata_cols
  attr(result, "settings") <- list(
    min_length = as.integer(min_length), max_length = as.integer(max_length),
    max_gap = max_gap, max_span = max_span,
    repeated_state_policy = repeated_state_policy, separator = separator,
    max_combinations_per_sequence = as.integer(max_combinations_per_sequence)
  )
  result
}

#' Summarise non-contiguous subsequences
#'
#' @param occurrences A result from [extract_sequence_subsequences()].
#'
#' @return A data frame with occurrence counts, sequence prevalence, and span
#'   diagnostics.
#' @examples
#' data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
#'                    sequence_order = rep(1:4, 2L),
#'                    state = c("A", "B", "C", "D", "A", "C", "B", "D"))
#' summarise_sequence_subsequences(extract_sequence_subsequences(data))
#' @export
summarise_sequence_subsequences <- function(occurrences) {
  if (!inherits(occurrences, "gp3_sequence_subsequences")) {
    stop("`occurrences` must be created by `extract_sequence_subsequences()`.",
         call. = FALSE)
  }
  n_sequences <- attr(occurrences, "n_sequences")
  if (nrow(occurrences) == 0L) {
    return(data.frame(
      subsequence = character(), subsequence_length = integer(),
      occurrence_count = integer(), sequence_count = integer(),
      sequence_prevalence = numeric(), mean_span = numeric(), median_span = numeric(),
      mean_max_gap = numeric(), stringsAsFactors = FALSE
    ))
  }
  split_rows <- split(seq_len(nrow(occurrences)), occurrences$subsequence, drop = TRUE)
  rows <- lapply(split_rows, function(index) {
    current <- occurrences[index, , drop = FALSE]
    data.frame(
      subsequence = current$subsequence[1L],
      subsequence_length = current$subsequence_length[1L],
      occurrence_count = nrow(current),
      sequence_count = length(unique(current$sequence_id)),
      sequence_prevalence = length(unique(current$sequence_id)) / n_sequences,
      mean_span = mean(current$span),
      median_span = stats::median(current$span),
      mean_max_gap = mean(current$max_observed_gap),
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, rows)
  result <- result[order(-result$sequence_prevalence, -result$occurrence_count,
                         result$subsequence_length, result$subsequence,
                         method = "radix"), , drop = FALSE]
  row.names(result) <- NULL
  result
}

#' Filter non-contiguous subsequence summaries
#'
#' @param summary A data frame from [summarise_sequence_subsequences()].
#' @param min_sequences Minimum sequence count.
#' @param min_prevalence Minimum sequence prevalence.
#' @param max_mean_gap Optional maximum mean gap.
#' @param top_n Optional number of rows retained after deterministic sorting.
#' @param ties Include or exclude ties at the `top_n` boundary.
#'
#' @return A filtered summary data frame.
#' @examples
#' data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
#'                    sequence_order = rep(1:4, 2L),
#'                    state = c("A", "B", "C", "D", "A", "C", "B", "D"))
#' x <- summarise_sequence_subsequences(extract_sequence_subsequences(data))
#' filter_sequence_subsequences(x, min_sequences = 2L)
#' @export
filter_sequence_subsequences <- function(
  summary,
  min_sequences = 1L,
  min_prevalence = 0,
  max_mean_gap = Inf,
  top_n = NULL,
  ties = c("include", "exclude")
) {
  ties <- match.arg(ties)
  required <- c("subsequence", "subsequence_length", "occurrence_count",
                "sequence_count", "sequence_prevalence", "mean_max_gap")
  if (!is.data.frame(summary) || !all(required %in% names(summary))) {
    stop("`summary` is not a subsequence summary table.", call. = FALSE)
  }
  .sequence_adv_scalar_number(min_sequences, "min_sequences", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(min_prevalence, "min_prevalence", lower = 0, upper = 1)
  if (!is.numeric(max_mean_gap) || length(max_mean_gap) != 1L || is.na(max_mean_gap) ||
      max_mean_gap < 0) {
    stop("`max_mean_gap` must be one non-negative number or `Inf`.", call. = FALSE)
  }
  if (!is.null(top_n)) .sequence_adv_scalar_number(top_n, "top_n", lower = 1, integer = TRUE)
  keep <- summary$sequence_count >= min_sequences &
    summary$sequence_prevalence >= min_prevalence &
    summary$mean_max_gap <= max_mean_gap
  result <- summary[keep, , drop = FALSE]
  result <- result[order(-result$sequence_prevalence, -result$occurrence_count,
                         result$subsequence_length, result$subsequence,
                         method = "radix"), , drop = FALSE]
  if (!is.null(top_n) && nrow(result) > top_n) {
    if (ties == "exclude") {
      result <- result[seq_len(top_n), , drop = FALSE]
    } else {
      boundary <- result$sequence_prevalence[top_n]
      result <- result[result$sequence_prevalence >= boundary, , drop = FALSE]
    }
  }
  row.names(result) <- NULL
  result
}

#' Compare subsequence prevalence between groups
#'
#' Performs transparent contingency-table tests on sequence-level presence.
#' Multiple testing is adjusted explicitly. Results are associational unless a
#' randomized design independently justifies causal interpretation.
#'
#' @param occurrences A non-contiguous subsequence occurrence table.
#' @param group_col Sequence-constant group column retained through
#'   `metadata_cols` during extraction.
#' @param test `"auto"`, `"chisq"`, or `"fisher"`.
#' @param p_adjust Multiple-testing adjustment method.
#' @param min_sequence_count Minimum total sequence count per subsequence.
#'
#' @return A data frame of prevalence contrasts and adjusted p-values.
#' @examples
#' data <- data.frame(
#'   sequence_id = rep(paste0("s", 1:4), each = 4L),
#'   sequence_order = rep(1:4, 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "D", "D",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L)
#' )
#' occurrences <- extract_sequence_subsequences(data, metadata_cols = "group")
#' compare_sequence_subsequences(occurrences, "group")
#' @export
compare_sequence_subsequences <- function(
  occurrences,
  group_col,
  test = c("auto", "chisq", "fisher"),
  p_adjust = "BH",
  min_sequence_count = 1L
) {
  if (!inherits(occurrences, "gp3_sequence_subsequences")) {
    stop("`occurrences` must be created by `extract_sequence_subsequences()`.",
         call. = FALSE)
  }
  test <- match.arg(test)
  .sequence_adv_scalar_character(group_col, "group_col")
  .sequence_adv_scalar_number(min_sequence_count, "min_sequence_count", lower = 1,
                              integer = TRUE)
  metadata <- attr(occurrences, "metadata")
  if (is.null(metadata) || !(group_col %in% names(metadata))) {
    stop("The requested group column was not retained as sequence metadata.",
         call. = FALSE)
  }
  id_col <- names(metadata)[1L]
  groups <- as.character(metadata[[group_col]])
  if (anyNA(groups) || any(!nzchar(trimws(groups)))) {
    stop("Group values must not be missing or blank.", call. = FALSE)
  }
  group_levels <- sort(unique(groups), method = "radix")
  if (length(group_levels) < 2L) stop("At least two groups are required.", call. = FALSE)
  sequence_ids <- as.character(metadata[[id_col]])
  motifs <- sort(unique(occurrences$subsequence), method = "radix")
  results <- list()
  h <- 0L
  for (motif in motifs) {
    present_ids <- unique(occurrences$sequence_id[occurrences$subsequence == motif])
    present <- sequence_ids %in% present_ids
    table_value <- table(
      factor(groups, levels = group_levels),
      factor(present, levels = c(FALSE, TRUE))
    )
    if (sum(table_value[, "TRUE"]) < min_sequence_count) next
    expected <- suppressWarnings(stats::chisq.test(table_value, correct = FALSE)$expected)
    chosen <- if (test == "auto") {
      if (any(expected < 5) && nrow(table_value) == 2L) "fisher" else "chisq"
    } else test
    if (chosen == "fisher" && nrow(table_value) != 2L) {
      stop("Fisher's exact test is currently limited to two groups.", call. = FALSE)
    }
    tested <- if (chosen == "fisher") {
      stats::fisher.test(table_value)
    } else {
      suppressWarnings(stats::chisq.test(table_value, correct = FALSE))
    }
    prevalence <- table_value[, "TRUE"] / rowSums(table_value)
    h <- h + 1L
    row <- data.frame(
      subsequence = motif,
      subsequence_length = occurrences$subsequence_length[match(motif, occurrences$subsequence)],
      test = chosen,
      statistic = if (is.null(tested$statistic)) NA_real_ else unname(tested$statistic),
      df = if (is.null(tested$parameter)) NA_real_ else unname(tested$parameter),
      p_value = tested$p.value,
      max_prevalence = max(prevalence),
      min_prevalence = min(prevalence),
      prevalence_range = max(prevalence) - min(prevalence),
      stringsAsFactors = FALSE
    )
    for (g in group_levels) {
      row[[paste0("prevalence_", make.names(g))]] <- prevalence[g]
      row[[paste0("n_", make.names(g))]] <- rowSums(table_value)[g]
    }
    if (length(group_levels) == 2L) {
      row$prevalence_difference <- prevalence[group_levels[2L]] - prevalence[group_levels[1L]]
    }
    results[[h]] <- row
  }
  if (length(results) == 0L) return(data.frame())
  result <- do.call(rbind, results)
  result$p_adjusted <- stats::p.adjust(result$p_value, method = p_adjust)
  result <- result[order(result$p_adjusted, -result$prevalence_range,
                         result$subsequence, method = "radix"), , drop = FALSE]
  row.names(result) <- NULL
  attr(result, "group_levels") <- group_levels
  attr(result, "p_adjust") <- p_adjust
  result
}

#' Plot non-contiguous subsequence summaries
#'
#' @param x A summary or group-comparison table.
#' @param metric Numeric column to plot.
#' @param top_n Maximum number of subsequences.
#' @param decreasing Sort metric in decreasing order.
#' @param ... Additional arguments passed to [graphics::barplot()].
#'
#' @return The plotted rows, invisibly.
#' @examples
#' data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
#'                    sequence_order = rep(1:4, 2L),
#'                    state = c("A", "B", "C", "D", "A", "C", "B", "D"))
#' summary <- summarise_sequence_subsequences(extract_sequence_subsequences(data))
#' plot_sequence_subsequences(summary, top_n = 5L)
#' @export
plot_sequence_subsequences <- function(
  x,
  metric = "sequence_prevalence",
  top_n = 10L,
  decreasing = TRUE,
  ...
) {
  if (!is.data.frame(x) || !("subsequence" %in% names(x)) ||
      !(metric %in% names(x)) || !is.numeric(x[[metric]])) {
    stop("`x` must contain `subsequence` and the requested numeric metric.",
         call. = FALSE)
  }
  .sequence_adv_scalar_number(top_n, "top_n", lower = 1, integer = TRUE)
  .sequence_adv_scalar_logical(decreasing, "decreasing")
  ordering <- order(x[[metric]], x$subsequence,
                    decreasing = decreasing, method = "radix")
  selected <- x[utils::head(ordering, top_n), , drop = FALSE]
  graphics::barplot(
    height = selected[[metric]],
    names.arg = selected$subsequence,
    las = 2,
    ylab = metric,
    ...
  )
  invisible(selected)
}
