#' Prepare longitudinal or panel sequence data
#'
#' Validates a collection of sequences observed repeatedly for the same panel
#' units and creates an auditable panel index. Each sequence must map to exactly
#' one panel unit and one occasion.
#'
#' @param data Long-format sequence data or a prepared gp3sequences result.
#' @param panel_id_col Column identifying the repeatedly observed unit.
#' @param occasion_col Column identifying the wave, visit, or occasion.
#' @param sequence_id_col,order_col,state_col Core sequence columns.
#' @param metadata_cols Optional columns that must remain constant within each
#'   sequence.
#' @param require_unique_occasions Require at most one sequence per panel unit
#'   and occasion.
#'
#' @return An object of class `gp3_sequence_panel` containing canonical data,
#'   a panel index, state levels, and mapping information.
#' @examples
#' panel <- data.frame(
#'   participant_id = rep(c("p1", "p2"), each = 8L),
#'   occasion = rep(rep(c(1, 2), each = 4L), times = 2L),
#'   sequence_id = rep(c("p1_w1", "p1_w2", "p2_w1", "p2_w2"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "C", "C", "D",
#'             "D", "C", "B", "A", "D", "B", "B", "A")
#' )
#' prepare_sequence_panel(panel, "participant_id", "occasion")
#' @export
prepare_sequence_panel <- function(
  data,
  panel_id_col,
  occasion_col,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  metadata_cols = NULL,
  require_unique_occasions = TRUE
) {
  .sequence_adv_scalar_character(panel_id_col, "panel_id_col")
  .sequence_adv_scalar_character(occasion_col, "occasion_col")
  .sequence_adv_scalar_logical(require_unique_occasions, "require_unique_occasions")
  metadata_cols <- unique(c(panel_id_col, occasion_col, metadata_cols))
  x <- .sequence_adv_data(
    data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    metadata_cols = metadata_cols,
    missing_state_policy = "error"
  )
  metadata <- x$metadata
  panel_id <- metadata[[panel_id_col]]
  occasion <- metadata[[occasion_col]]
  panel_missing <- is.na(panel_id) | trimws(as.character(panel_id)) == ""
  occasion_missing <- is.na(occasion) | trimws(as.character(occasion)) == ""
  if (any(panel_missing)) {
    stop("Panel identifiers must not be missing or blank.", call. = FALSE)
  }
  if (any(occasion_missing)) {
    stop("Occasion values must not be missing or blank.", call. = FALSE)
  }
  panel_text <- as.character(panel_id)
  occasion_text <- as.character(occasion)
  duplicate_key <- paste(panel_text, occasion_text, sep = "\034")
  if (require_unique_occasions && anyDuplicated(duplicate_key)) {
    duplicated_rows <- which(duplicated(duplicate_key) | duplicated(duplicate_key, fromLast = TRUE))
    stop(
      "More than one sequence was found for panel/occasion combinations: ",
      paste(unique(duplicate_key[duplicated_rows]), collapse = ", "), ".",
      call. = FALSE
    )
  }
  occasion_rank <- integer(length(occasion))
  for (panel in unique(panel_text)) {
    rows <- which(panel_text == panel)
    current <- occasion[rows]
    if (is.numeric(current) || inherits(current, c("Date", "POSIXct", "POSIXlt"))) {
      ordering <- order(current, as.character(metadata[[sequence_id_col]][rows]), method = "radix")
    } else if (is.factor(current) && is.ordered(current)) {
      ordering <- order(as.integer(current), as.character(metadata[[sequence_id_col]][rows]), method = "radix")
    } else {
      ordering <- order(as.character(current), as.character(metadata[[sequence_id_col]][rows]), method = "radix")
    }
    occasion_rank[rows[ordering]] <- seq_along(rows)
  }
  sequence_lengths <- lengths(x$sequences)
  transition_counts <- pmax(sequence_lengths - 1L, 0L)
  index <- data.frame(
    sequence_id = x$sequence_ids,
    panel_id = panel_text,
    occasion = occasion_text,
    occasion_rank = as.integer(occasion_rank),
    sequence_length = as.integer(sequence_lengths[x$sequence_ids]),
    transition_count = as.integer(transition_counts[x$sequence_ids]),
    stringsAsFactors = FALSE
  )
  index <- index[order(index$panel_id, index$occasion_rank, index$sequence_id,
                       method = "radix"), , drop = FALSE]
  row.names(index) <- NULL
  result <- list(
    data = x$data,
    index = index,
    sequences = x$sequences,
    orders = x$orders,
    state_levels = x$state_levels,
    columns = list(
      panel_id = panel_id_col,
      occasion = occasion_col,
      sequence_id = sequence_id_col,
      order = order_col,
      state = state_col,
      metadata = metadata_cols
    ),
    settings = list(require_unique_occasions = require_unique_occasions),
    call = match.call()
  )
  class(result) <- c("gp3_sequence_panel", "list")
  result
}

#' Summarise a sequence panel
#'
#' @param panel A result from [prepare_sequence_panel()].
#'
#' @return A list with occasion-level sequence summaries and state prevalence.
#' @examples
#' panel_data <- data.frame(
#'   participant_id = rep(c("p1", "p2"), each = 6L),
#'   occasion = rep(rep(c(1, 2), each = 3L), times = 2L),
#'   sequence_id = rep(c("a", "b", "c", "d"), each = 3L),
#'   sequence_order = rep(1:3, times = 4L),
#'   state = c("A", "B", "C", "A", "C", "C", "C", "B", "A", "C", "B", "B")
#' )
#' summarise_sequence_panel(prepare_sequence_panel(panel_data, "participant_id", "occasion"))
#' @export
summarise_sequence_panel <- function(panel) {
  if (!inherits(panel, "gp3_sequence_panel")) {
    stop("`panel` must be created by `prepare_sequence_panel()`.", call. = FALSE)
  }
  index <- panel$index
  occasion_levels <- unique(index$occasion[order(index$occasion_rank, index$occasion,
                                                  method = "radix")])
  occasion_rows <- lapply(occasion_levels, function(occasion) {
    current <- index[index$occasion == occasion, , drop = FALSE]
    data.frame(
      occasion = occasion,
      n_panels = length(unique(current$panel_id)),
      n_sequences = nrow(current),
      mean_length = mean(current$sequence_length),
      median_length = stats::median(current$sequence_length),
      mean_transitions = mean(current$transition_count),
      stringsAsFactors = FALSE
    )
  })
  state_rows <- list()
  h <- 0L
  for (occasion in occasion_levels) {
    ids <- index$sequence_id[index$occasion == occasion]
    sequences <- panel$sequences[ids]
    for (state in panel$state_levels) {
      h <- h + 1L
      occurrence_count <- sum(vapply(sequences, function(x) sum(x == state), integer(1)))
      sequence_count <- sum(vapply(sequences, function(x) any(x == state), logical(1)))
      total_positions <- sum(lengths(sequences))
      state_rows[[h]] <- data.frame(
        occasion = occasion,
        state = state,
        occurrence_count = as.integer(occurrence_count),
        occurrence_share = if (total_positions > 0) occurrence_count / total_positions else NA_real_,
        sequence_count = as.integer(sequence_count),
        sequence_prevalence = if (length(sequences) > 0) sequence_count / length(sequences) else NA_real_,
        stringsAsFactors = FALSE
      )
    }
  }
  list(
    occasions = do.call(rbind, occasion_rows),
    states = do.call(rbind, state_rows),
    n_panels = length(unique(index$panel_id)),
    n_occasions = length(occasion_levels),
    state_levels = panel$state_levels
  )
}

#' Compare within-panel sequence changes
#'
#' Computes distance and simple structural changes between consecutive panel
#' occasions. The output is descriptive and does not establish a causal or
#' psychological change.
#'
#' @param panel A sequence panel.
#' @param method Distance method supported by [compute_sequence_distance()].
#' @param normalise Distance normalisation.
#' @param indel_cost,substitution_cost Costs for optimal matching.
#' @param substitution_matrix Optional named substitution matrix.
#' @param transition_smoothing Smoothing for transition-profile distance.
#'
#' @return A data frame of class `gp3_sequence_panel_changes`.
#' @examples
#' panel_data <- data.frame(
#'   participant_id = rep(c("p1", "p2"), each = 8L),
#'   occasion = rep(rep(c(1, 2), each = 4L), times = 2L),
#'   sequence_id = rep(c("a", "b", "c", "d"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "C", "C", "D",
#'             "D", "C", "B", "A", "D", "B", "B", "A")
#' )
#' compare_sequence_panel_changes(
#'   prepare_sequence_panel(panel_data, "participant_id", "occasion"),
#'   method = "lcs"
#' )
#' @export
compare_sequence_panel_changes <- function(
  panel,
  method = c("levenshtein", "lcs", "optimal_matching", "transition"),
  normalise = c("none", "max_length", "path_length"),
  indel_cost = 1,
  substitution_cost = 1,
  substitution_matrix = NULL,
  transition_smoothing = 0
) {
  if (!inherits(panel, "gp3_sequence_panel")) {
    stop("`panel` must be created by `prepare_sequence_panel()`.", call. = FALSE)
  }
  method <- match.arg(method)
  normalise <- match.arg(normalise)
  index <- panel$index
  pieces <- list()
  h <- 0L
  for (panel_id in unique(index$panel_id)) {
    current <- index[index$panel_id == panel_id, , drop = FALSE]
    current <- current[order(current$occasion_rank, current$sequence_id, method = "radix"), , drop = FALSE]
    if (nrow(current) < 2L) next
    for (i in seq_len(nrow(current) - 1L)) {
      ids <- current$sequence_id[c(i, i + 1L)]
      subset_data <- panel$data[as.character(panel$data[[panel$columns$sequence_id]]) %in% ids,
                                , drop = FALSE]
      distance <- compute_sequence_distance(
        subset_data,
        sequence_id_col = panel$columns$sequence_id,
        order_col = panel$columns$order,
        state_col = panel$columns$state,
        method = method,
        indel_cost = indel_cost,
        substitution_cost = substitution_cost,
        substitution_matrix = substitution_matrix,
        transition_smoothing = transition_smoothing,
        normalise = normalise
      )
      value <- as.numeric(distance)[1L]
      h <- h + 1L
      pieces[[h]] <- data.frame(
        panel_id = panel_id,
        from_sequence_id = ids[1L],
        to_sequence_id = ids[2L],
        from_occasion = current$occasion[i],
        to_occasion = current$occasion[i + 1L],
        from_rank = current$occasion_rank[i],
        to_rank = current$occasion_rank[i + 1L],
        distance = value,
        length_change = current$sequence_length[i + 1L] - current$sequence_length[i],
        transition_change = current$transition_count[i + 1L] - current$transition_count[i],
        stringsAsFactors = FALSE
      )
    }
  }
  if (length(pieces) == 0L) {
    result <- data.frame(
      panel_id = character(), from_sequence_id = character(), to_sequence_id = character(),
      from_occasion = character(), to_occasion = character(), from_rank = integer(),
      to_rank = integer(), distance = numeric(), length_change = numeric(),
      transition_change = numeric(), stringsAsFactors = FALSE
    )
  } else {
    result <- do.call(rbind, pieces)
    row.names(result) <- NULL
  }
  class(result) <- c("gp3_sequence_panel_changes", "data.frame")
  attr(result, "method") <- method
  attr(result, "normalise") <- normalise
  result
}

#' Plot longitudinal sequence changes
#'
#' @param changes A result from [compare_sequence_panel_changes()].
#' @param metric One of `"distance"`, `"length_change"`, or
#'   `"transition_change"`.
#' @param type Plot individual panel trajectories or occasion-transition means.
#' @param ... Additional graphical arguments passed to base plotting functions.
#'
#' @return The plotted data, invisibly.
#' @examples
#' panel_data <- data.frame(
#'   participant_id = rep(c("p1", "p2"), each = 6L),
#'   occasion = rep(rep(c(1, 2), each = 3L), times = 2L),
#'   sequence_id = rep(c("a", "b", "c", "d"), each = 3L),
#'   sequence_order = rep(1:3, times = 4L),
#'   state = c("A", "B", "C", "A", "C", "C", "C", "B", "A", "C", "B", "B")
#' )
#' changes <- compare_sequence_panel_changes(
#'   prepare_sequence_panel(panel_data, "participant_id", "occasion")
#' )
#' plot_sequence_panel_changes(changes)
#' @export
plot_sequence_panel_changes <- function(
  changes,
  metric = c("distance", "length_change", "transition_change"),
  type = c("individual", "summary"),
  ...
) {
  if (!inherits(changes, "gp3_sequence_panel_changes")) {
    stop("`changes` must be created by `compare_sequence_panel_changes()`.",
         call. = FALSE)
  }
  metric <- match.arg(metric)
  type <- match.arg(type)
  if (nrow(changes) == 0L) stop("There are no panel changes to plot.", call. = FALSE)
  transition_label <- paste(changes$from_occasion, changes$to_occasion, sep = " -> ")
  transition_levels <- unique(transition_label[order(changes$from_rank, changes$to_rank,
                                                      transition_label, method = "radix")])
  x <- match(transition_label, transition_levels)
  y <- changes[[metric]]
  if (type == "individual") {
    graphics::plot(x, y, type = "n", xaxt = "n", xlab = "Occasion transition",
                   ylab = metric, ...)
    graphics::axis(1, at = seq_along(transition_levels), labels = transition_levels)
    panels <- unique(changes$panel_id)
    colors <- .sequence_ext_base_colors(length(panels))
    for (i in seq_along(panels)) {
      rows <- which(changes$panel_id == panels[i])
      graphics::lines(x[rows], y[rows], type = "b", col = colors[i])
    }
  } else {
    means <- tapply(y, factor(transition_label, levels = transition_levels), mean)
    standard_errors <- tapply(y, factor(transition_label, levels = transition_levels),
                              function(z) if (length(z) > 1L) stats::sd(z) / sqrt(length(z)) else 0)
    graphics::plot(seq_along(means), means, type = "b", xaxt = "n",
                   ylim = range(c(means - standard_errors, means + standard_errors), finite = TRUE),
                   xlab = "Occasion transition", ylab = metric, ...)
    graphics::axis(1, at = seq_along(transition_levels), labels = transition_levels)
    error_index <- which(
      is.finite(standard_errors) &
        standard_errors > 0
    )
    if (length(error_index) > 0L) {
      graphics::arrows(
        error_index,
        means[error_index] - standard_errors[error_index],
        error_index,
        means[error_index] + standard_errors[error_index],
        angle = 90,
        code = 3,
        length = 0.05
      )
    }
  }
  invisible(changes)
}
