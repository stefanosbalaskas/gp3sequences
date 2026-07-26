#' Plot a sequence index heatmap
#'
#' @param data Long-format sequence data or a prepared result.
#' @param sequence_id_col,order_col,state_col Core sequence columns.
#' @param sort_by `"input"`, `"length"`, or `"path"`.
#' @param state_levels Optional state ordering.
#' @param palette Base HCL palette.
#' @param show_sequence_labels Draw sequence identifiers.
#' @param ... Additional arguments passed to [graphics::image()].
#'
#' @return The plotted state-code matrix, invisibly.
#' @examples
#' data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
#'                    sequence_order = rep(1:4, 2L),
#'                    state = c("A", "B", "C", "D", "A", "C", "C", "D"))
#' plot_sequence_index(data)
#' @export
plot_sequence_index <- function(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  sort_by = c("input", "length", "path"),
  state_levels = NULL,
  palette = "Dark 3",
  show_sequence_labels = TRUE,
  ...
) {
  sort_by <- match.arg(sort_by)
  .sequence_adv_scalar_logical(show_sequence_labels, "show_sequence_labels")
  x <- .sequence_adv_data(data, sequence_id_col, order_col, state_col,
                          missing_state_policy = "error")
  levels_value <- .sequence_adv_state_order(unlist(x$sequences, use.names = FALSE),
                                            state_levels)
  ids <- x$sequence_ids
  if (sort_by == "length") {
    ids <- ids[order(lengths(x$sequences)[ids], ids, method = "radix")]
  } else if (sort_by == "path") {
    paths <- vapply(x$sequences, paste, collapse = "\034", character(1))
    ids <- ids[order(paths[ids], ids, method = "radix")]
  }
  max_length <- max(lengths(x$sequences))
  matrix_value <- matrix(NA_integer_, nrow = length(ids), ncol = max_length,
                         dimnames = list(ids, seq_len(max_length)))
  for (i in seq_along(ids)) {
    sequence <- x$sequences[[ids[i]]]
    matrix_value[i, seq_along(sequence)] <- match(sequence, levels_value)
  }
  colors <- .sequence_ext_base_colors(length(levels_value), palette)
  graphics::image(
    x = seq_len(ncol(matrix_value)),
    y = seq_len(nrow(matrix_value)),
    z = t(matrix_value[nrow(matrix_value):1L, , drop = FALSE]),
    col = colors,
    xlab = "Sequence position",
    ylab = "Sequence",
    yaxt = "n",
    ...
  )
  if (show_sequence_labels) {
    graphics::axis(2, at = seq_len(length(ids)), labels = rev(ids), las = 2)
  }
  graphics::legend("topright", legend = levels_value, fill = colors, bty = "n")
  invisible(matrix_value)
}

#' Plot state distributions over aligned positions
#'
#' @param data Long-format sequence data or a prepared result.
#' @param sequence_id_col,order_col,state_col Core sequence columns.
#' @param proportion Plot position-wise proportions rather than counts.
#' @param state_levels Optional state ordering.
#' @param palette Base HCL palette.
#' @param ... Additional arguments passed to [graphics::matplot()].
#'
#' @return A position-by-state matrix, invisibly.
#' @examples
#' data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
#'                    sequence_order = rep(1:4, 2L),
#'                    state = c("A", "B", "C", "D", "A", "C", "C", "D"))
#' plot_sequence_state_distribution(data)
#' @export
plot_sequence_state_distribution <- function(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  proportion = TRUE,
  state_levels = NULL,
  palette = "Dark 3",
  ...
) {
  .sequence_adv_scalar_logical(proportion, "proportion")
  x <- .sequence_adv_data(data, sequence_id_col, order_col, state_col,
                          missing_state_policy = "error")
  levels_value <- .sequence_adv_state_order(unlist(x$sequences, use.names = FALSE),
                                            state_levels)
  positions <- sort(unique(x$data[[order_col]]))
  matrix_value <- matrix(0, nrow = length(positions), ncol = length(levels_value),
                         dimnames = list(as.character(positions), levels_value))
  for (i in seq_along(positions)) {
    current <- as.character(x$data[[state_col]][x$data[[order_col]] == positions[i]])
    matrix_value[i, ] <- table(factor(current, levels = levels_value))
    if (proportion && sum(matrix_value[i, ]) > 0) {
      matrix_value[i, ] <- matrix_value[i, ] / sum(matrix_value[i, ])
    }
  }
  colors <- .sequence_ext_base_colors(ncol(matrix_value), palette)
  graphics::matplot(positions, matrix_value, type = "l", lty = 1,
                    col = colors, xlab = "Sequence position",
                    ylab = if (proportion) "State proportion" else "State count", ...)
  graphics::legend("topright", legend = colnames(matrix_value), col = colors,
                   lty = 1, bty = "n")
  invisible(matrix_value)
}

#' Plot position-wise state entropy
#'
#' @param data Long-format sequence data or a prepared result.
#' @param sequence_id_col,order_col,state_col Core sequence columns.
#' @param base Logarithm base.
#' @param normalise Divide entropy by the maximum entropy for the observed
#'   alphabet.
#' @param ... Additional arguments passed to [graphics::plot()].
#'
#' @return A data frame of position-wise entropy values, invisibly.
#' @examples
#' data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
#'                    sequence_order = rep(1:4, 2L),
#'                    state = c("A", "B", "C", "D", "A", "C", "C", "D"))
#' plot_sequence_entropy(data)
#' @export
plot_sequence_entropy <- function(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  base = 2,
  normalise = TRUE,
  ...
) {
  .sequence_adv_scalar_number(base, "base", lower = 1 + .Machine$double.eps)
  .sequence_adv_scalar_logical(normalise, "normalise")
  x <- .sequence_adv_data(data, sequence_id_col, order_col, state_col,
                          missing_state_policy = "error")
  positions <- sort(unique(x$data[[order_col]]))
  entropy <- vapply(positions, function(position) {
    current <- as.character(x$data[[state_col]][x$data[[order_col]] == position])
    probabilities <- as.numeric(table(current)) / length(current)
    value <- .sequence_ext_entropy(probabilities, base = base)
    if (normalise && length(x$state_levels) > 1L) {
      value <- value / (log(length(x$state_levels)) / log(base))
    }
    value
  }, numeric(1))
  result <- data.frame(position = positions, entropy = entropy,
                       normalised = normalise, stringsAsFactors = FALSE)
  graphics::plot(result$position, result$entropy, type = "b",
                 xlab = "Sequence position",
                 ylab = if (normalise) "Normalised entropy" else "Entropy", ...)
  invisible(result)
}

#' Plot a sequence-distance heatmap
#'
#' @param distance A sequence distance object or square matrix.
#' @param order_by Optional clustering or named assignment vector used to order
#'   the matrix.
#' @param palette Base HCL palette.
#' @param show_labels Draw sequence identifiers.
#' @param ... Additional arguments passed to [graphics::image()].
#'
#' @return The ordered distance matrix, invisibly.
#' @examples
#' data <- data.frame(sequence_id = rep(paste0("s", 1:4), each = 4L),
#'                    sequence_order = rep(1:4, 4L),
#'                    state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'                              "D", "C", "B", "A", "D", "C", "A", "A"))
#' plot_sequence_distance_heatmap(compute_sequence_distance(data))
#' @export
plot_sequence_distance_heatmap <- function(
  distance,
  order_by = NULL,
  palette = "Viridis",
  show_labels = TRUE,
  ...
) {
  .sequence_adv_scalar_logical(show_labels, "show_labels")
  matrix_value <- .sequence_adv_distance_matrix(distance)
  ids <- rownames(matrix_value)
  if (!is.null(order_by)) {
    assignments <- if (inherits(order_by, "gp3_sequence_clustering")) {
      order_by$assignments
    } else order_by
    if (is.null(names(assignments)) || !setequal(names(assignments), ids)) {
      stop("`order_by` assignments must be named for every sequence.", call. = FALSE)
    }
    ids <- ids[order(assignments[ids], ids, method = "radix")]
    matrix_value <- matrix_value[ids, ids, drop = FALSE]
  }
  colors <- .sequence_ext_base_colors(64L, palette)
  graphics::image(seq_len(nrow(matrix_value)), seq_len(ncol(matrix_value)),
                  t(matrix_value[nrow(matrix_value):1L, , drop = FALSE]),
                  col = colors, xlab = "Sequence", ylab = "Sequence",
                  xaxt = "n", yaxt = "n", ...)
  if (show_labels) {
    graphics::axis(1, at = seq_along(ids), labels = ids, las = 2)
    graphics::axis(2, at = seq_along(ids), labels = rev(ids), las = 2)
  }
  invisible(matrix_value)
}

#' Plot a first-order transition network
#'
#' @param network A first-order network from [create_transition_network()].
#' @param weight_col Edge-weight column.
#' @param minimum_weight Minimum plotted edge weight.
#' @param vertex_cex Vertex label size.
#' @param edge_scale Edge-width multiplier.
#' @param ... Additional arguments passed to [graphics::plot.window()].
#'
#' @return The plotted network rows, invisibly.
#' @examples
#' data <- data.frame(sequence_id = rep(c("a", "b"), each = 4L),
#'                    sequence_order = rep(1:4, 2L),
#'                    state = c("A", "B", "C", "D", "A", "C", "C", "D"))
#' plot_transition_network(create_transition_network(data, normalise = "from"))
#' @export
plot_transition_network <- function(
  network,
  weight_col = "weight",
  minimum_weight = 0,
  vertex_cex = 1,
  edge_scale = 5,
  ...
) {
  if (!inherits(network, "gp3_transition_network")) {
    stop("`network` must be created by `create_transition_network()`.", call. = FALSE)
  }
  settings <- attr(network, "settings")
  if (!identical(settings$order, 1L)) {
    stop("Only first-order networks can be plotted with this helper.", call. = FALSE)
  }
  if (length(unique(network$group_key)) > 1L) {
    stop("Filter a grouped network to one group before plotting.", call. = FALSE)
  }
  if (!(weight_col %in% names(network)) || !is.numeric(network[[weight_col]])) {
    stop("`weight_col` must name a numeric network column.", call. = FALSE)
  }
  .sequence_adv_scalar_number(minimum_weight, "minimum_weight", lower = 0)
  .sequence_adv_scalar_number(vertex_cex, "vertex_cex", lower = 0)
  .sequence_adv_scalar_number(edge_scale, "edge_scale", lower = 0)
  edges <- network[network[[weight_col]] >= minimum_weight, , drop = FALSE]
  states <- sort(unique(c(edges$from_state, edges$to_state)), method = "radix")
  if (length(states) == 0L) stop("No edges satisfy the plotting threshold.", call. = FALSE)
  angle <- seq(0, 2 * pi, length.out = length(states) + 1L)[seq_len(length(states))]
  coordinates <- cbind(x = cos(angle), y = sin(angle))
  rownames(coordinates) <- states
  graphics::plot.new()
  graphics::plot.window(xlim = c(-1.3, 1.3), ylim = c(-1.3, 1.3), asp = 1, ...)
  for (i in seq_len(nrow(edges))) {
    from <- coordinates[edges$from_state[i], ]
    to <- coordinates[edges$to_state[i], ]
    width <- max(0.5, edges[[weight_col]][i] * edge_scale)
    if (identical(edges$from_state[i], edges$to_state[i])) {
      graphics::symbols(from[1], from[2] + 0.12, circles = 0.12,
                        inches = FALSE, add = TRUE, lwd = width)
    } else {
      graphics::arrows(from[1], from[2], to[1], to[2], length = 0.08,
                       lwd = width)
    }
  }
  graphics::points(coordinates[, 1], coordinates[, 2], pch = 21, bg = "white",
                   cex = 2)
  graphics::text(coordinates[, 1], coordinates[, 2], labels = states,
                 cex = vertex_cex)
  invisible(edges)
}

#' Plot sequence-cluster silhouette values
#'
#' @param clustering A clustering result or named assignment vector.
#' @param distance Optional distance when `clustering` is an assignment vector.
#' @param ... Additional arguments passed to [graphics::barplot()].
#'
#' @return The ordered per-sequence silhouette table, invisibly.
#' @examples
#' data <- data.frame(sequence_id = rep(paste0("s", 1:4), each = 4L),
#'                    sequence_order = rep(1:4, 4L),
#'                    state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'                              "D", "C", "B", "A", "D", "C", "A", "A"))
#' distance <- compute_sequence_distance(data)
#' plot_sequence_cluster_silhouette(cluster_sequences(distance, 2L))
#' @export
plot_sequence_cluster_silhouette <- function(clustering, distance = NULL, ...) {
  validation <- validate_sequence_clusters(clustering, distance)
  current <- validation$per_sequence
  current <- current[order(current$cluster, -current$silhouette,
                           current$sequence_id, method = "radix"), , drop = FALSE]
  colors <- .sequence_ext_base_colors(length(unique(current$cluster)))
  color_map <- stats::setNames(colors, sort(unique(current$cluster), method = "radix"))
  graphics::barplot(current$silhouette,
                    names.arg = current$sequence_id,
                    col = color_map[current$cluster],
                    las = 2, ylab = "Silhouette", ...)
  graphics::abline(h = 0, lty = 2)
  invisible(current)
}
