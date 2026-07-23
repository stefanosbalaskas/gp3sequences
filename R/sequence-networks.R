#' Create a transition network from ordered sequences
#'
#' @param data Long-format sequence data or a prepared result.
#' @param sequence_id_col,order_col,state_col Sequence columns.
#' @param group_cols Optional grouping columns constant within sequence.
#' @param order Markov order. `1` creates ordinary state-to-state edges;
#'   larger values create context-to-next-state edges.
#' @param include_self Include first-order self-transitions.
#' @param normalise Edge weight scale: counts, conditional probabilities from
#'   each context, or global shares.
#' @param smoothing Non-negative additive smoothing applied to observed edges.
#' @param context_separator Separator used for higher-order contexts.
#'
#' @return A data frame of class `gp3_transition_network` containing context,
#' next state, counts, weights, sequence prevalence, and group columns.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' create_transition_network(sequences, normalise = "from")
#'
#' @export
create_transition_network <- function(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  group_cols = NULL,
  order = 1L,
  include_self = TRUE,
  normalise = c("count", "from", "global"),
  smoothing = 0,
  context_separator = " > "
) {
  normalise <- match.arg(normalise)
  .sequence_adv_scalar_number(order, "order", lower = 1, integer = TRUE)
  .sequence_adv_scalar_logical(include_self, "include_self")
  .sequence_adv_scalar_number(smoothing, "smoothing", lower = 0)
  .sequence_adv_scalar_character(context_separator, "context_separator")
  x <- .sequence_adv_data(data, sequence_id_col, order_col, state_col,
                          metadata_cols = group_cols, missing_state_policy = "error")
  if (any(grepl(context_separator, x$state_levels, fixed = TRUE))) {
    stop("`context_separator` must not occur inside an observed state label.",
         call. = FALSE)
  }
  group_cols <- .sequence_adv_match_cols(x$data, group_cols, "group_cols")
  sequence_meta <- if (length(group_cols) == 0L) {
    data.frame(sequence_id = x$sequence_ids, .group_key = "__all__",
               stringsAsFactors = FALSE)
  } else {
    meta <- x$metadata
    names(meta)[names(meta) == sequence_id_col] <- "sequence_id"
    meta$.group_key <- .sequence_adv_group_key(meta, group_cols)
    meta
  }
  event_rows <- list(); h <- 0L
  for (id in x$sequence_ids) {
    seq <- x$sequences[[id]]
    if (length(seq) <= order) next
    group_row <- sequence_meta[sequence_meta$sequence_id == id, , drop = FALSE]
    for (i in seq_len(length(seq) - order)) {
      context <- seq[i:(i + order - 1L)]
      next_state <- seq[i + order]
      if (order == 1L && !include_self && identical(context[1L], next_state)) next
      h <- h + 1L
      prefix <- if (length(group_cols) == 0L) {
        .sequence_adv_zero_column_frame(1L)
      } else {
        group_row[1L, group_cols, drop = FALSE]
      }
      event_rows[[h]] <- cbind(prefix, data.frame(
        group_key = group_row$.group_key[1L],
        sequence_id = id,
        context = paste(context, collapse = context_separator),
        from_state = if (order == 1L) context[1L] else NA_character_,
        to_state = next_state,
        stringsAsFactors = FALSE,
        check.names = FALSE
      ))
    }
  }
  if (length(event_rows) == 0L) {
    prefix <- if (length(group_cols) == 0L) {
      .sequence_adv_zero_column_frame(0L)
    } else {
      x$data[0L, group_cols, drop = FALSE]
    }
    result <- cbind(
      prefix,
      data.frame(group_key = character(), context = character(),
                 from_state = character(), to_state = character(),
                 count = numeric(), weight = numeric(),
                 sequence_count = integer(), sequence_prevalence = numeric(),
                 stringsAsFactors = FALSE, check.names = FALSE)
    )
    class(result) <- c("gp3_transition_network", "data.frame")
    attr(result, "group_cols") <- group_cols
    attr(result, "settings") <- list(order = as.integer(order), normalise = normalise,
                                     include_self = include_self, smoothing = smoothing,
                                     context_separator = context_separator)
    return(result)
  }
  events <- do.call(rbind, event_rows)
  grouping <- c(group_cols, "group_key", "context", "from_state", "to_state")
  key <- .sequence_adv_group_key(events, grouping)
  pieces <- split(seq_len(nrow(events)), key, drop = TRUE)
  edge_rows <- lapply(pieces, function(rows) {
    prefix <- events[rows[1L], grouping, drop = FALSE]
    group_key <- events$group_key[rows[1L]]
    group_sequences <- unique(sequence_meta$sequence_id[sequence_meta$.group_key == group_key])
    cbind(prefix, data.frame(
      count = length(rows) + smoothing,
      sequence_count = length(unique(events$sequence_id[rows])),
      sequence_prevalence = length(unique(events$sequence_id[rows])) / length(group_sequences),
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
  })
  result <- do.call(rbind, edge_rows)
  row.names(result) <- NULL
  if (normalise == "count") {
    result$weight <- result$count
  } else if (normalise == "from") {
    context_key <- .sequence_adv_group_key(result, c(group_cols, "group_key", "context"))
    totals <- stats::ave(result$count, context_key, FUN = sum)
    result$weight <- result$count / totals
  } else {
    group_key <- .sequence_adv_group_key(result, c(group_cols, "group_key"))
    totals <- stats::ave(result$count, group_key, FUN = sum)
    result$weight <- result$count / totals
  }
  result <- result[order(result$group_key, result$context, result$to_state, method = "radix"), , drop = FALSE]
  row.names(result) <- NULL
  class(result) <- c("gp3_transition_network", "data.frame")
  attr(result, "group_cols") <- group_cols
  attr(result, "settings") <- list(order = as.integer(order), normalise = normalise,
                                   include_self = include_self, smoothing = smoothing,
                                   context_separator = context_separator)
  result
}

.sequence_adv_graph_matrix <- function(network, use_weight = TRUE,
                                       symmetrise = FALSE) {
  if (!inherits(network, "gp3_transition_network")) {
    stop("`network` must be created by `create_transition_network()`.", call. = FALSE)
  }
  settings <- attr(network, "settings")
  if (!identical(settings$order, 1L)) {
    stop("Centrality and community helpers currently require a first-order network.",
         call. = FALSE)
  }
  group_keys <- unique(as.character(network$group_key))
  group_keys <- group_keys[!is.na(group_keys)]
  if (length(group_keys) > 1L) {
    stop("Filter a grouped transition network to one group before graph analysis.",
         call. = FALSE)
  }
  states <- sort(unique(c(network$from_state, network$to_state)), method = "radix")
  states <- states[!is.na(states)]
  adjacency <- matrix(0, length(states), length(states), dimnames = list(states, states))
  value <- if (use_weight) network$weight else rep(1, nrow(network))
  for (i in seq_len(nrow(network))) {
    adjacency[network$from_state[i], network$to_state[i]] <-
      adjacency[network$from_state[i], network$to_state[i]] + value[i]
  }
  if (symmetrise) {
    original_diagonal <- diag(adjacency)
    adjacency <- adjacency + t(adjacency)
    diag(adjacency) <- original_diagonal
  }
  adjacency
}

.sequence_adv_dijkstra <- function(cost, source) {
  n <- nrow(cost)
  distance <- rep(Inf, n)
  visited <- rep(FALSE, n)
  distance[source] <- 0
  for (step in seq_len(n)) {
    available <- which(!visited)
    if (length(available) == 0L) break
    current <- available[which.min(distance[available])]
    if (!is.finite(distance[current])) break
    visited[current] <- TRUE
    neighbours <- which(is.finite(cost[current, ]) & cost[current, ] > 0)
    for (j in neighbours) {
      candidate <- distance[current] + cost[current, j]
      if (candidate < distance[j]) distance[j] <- candidate
    }
  }
  distance
}

.sequence_adv_unweighted_betweenness <- function(adjacency) {
  n <- nrow(adjacency)
  score <- numeric(n)
  for (source in seq_len(n)) {
    stack <- integer()
    predecessors <- vector("list", n)
    sigma <- numeric(n); sigma[source] <- 1
    distance <- rep(-1L, n); distance[source] <- 0L
    queue <- source
    while (length(queue) > 0L) {
      v <- queue[1L]; queue <- queue[-1L]
      stack <- c(stack, v)
      neighbours <- which(adjacency[v, ] > 0)
      for (w in neighbours) {
        if (distance[w] < 0L) {
          queue <- c(queue, w)
          distance[w] <- distance[v] + 1L
        }
        if (distance[w] == distance[v] + 1L) {
          sigma[w] <- sigma[w] + sigma[v]
          predecessors[[w]] <- c(predecessors[[w]], v)
        }
      }
    }
    dependency <- numeric(n)
    while (length(stack) > 0L) {
      w <- stack[length(stack)]
      stack <- stack[-length(stack)]
      for (v in predecessors[[w]]) {
        if (sigma[w] > 0) dependency[v] <- dependency[v] +
          (sigma[v] / sigma[w]) * (1 + dependency[w])
      }
      if (w != source) score[w] <- score[w] + dependency[w]
    }
  }
  score
}

#' Summarise transition-network centrality
#'
#' @param network A first-order transition network.
#' @param directed Treat the network as directed.
#' @param pagerank_damping Damping factor for PageRank.
#' @param pagerank_tolerance Convergence tolerance.
#' @param pagerank_max_iter Maximum PageRank iterations.
#'
#' @return A data frame containing degree, strength, weighted closeness,
#' unweighted betweenness, and PageRank centrality.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' network <- create_transition_network(sequences)
#' summarise_transition_centrality(network)
#'
#' @export
summarise_transition_centrality <- function(network, directed = TRUE,
                                            pagerank_damping = 0.85,
                                            pagerank_tolerance = 1e-10,
                                            pagerank_max_iter = 1000L) {
  .sequence_adv_scalar_logical(directed, "directed")
  .sequence_adv_scalar_number(pagerank_damping, "pagerank_damping", lower = 0, upper = 1)
  .sequence_adv_scalar_number(pagerank_tolerance, "pagerank_tolerance", lower = 0)
  .sequence_adv_scalar_number(pagerank_max_iter, "pagerank_max_iter", lower = 1, integer = TRUE)
  adjacency <- .sequence_adv_graph_matrix(network, use_weight = TRUE,
                                          symmetrise = !directed)
  n <- nrow(adjacency)
  if (n == 0L) return(data.frame())
  binary <- adjacency > 0
  out_degree <- rowSums(binary)
  in_degree <- colSums(binary)
  out_strength <- rowSums(adjacency)
  in_strength <- colSums(adjacency)
  total_degree <- if (directed) out_degree + in_degree else out_degree
  total_strength <- if (directed) out_strength + in_strength else out_strength
  cost <- matrix(Inf, n, n, dimnames = dimnames(adjacency))
  cost[adjacency > 0] <- 1 / adjacency[adjacency > 0]
  diag(cost) <- 0
  distance_matrix <- do.call(rbind, lapply(seq_len(n), function(i) .sequence_adv_dijkstra(cost, i)))
  closeness <- vapply(seq_len(n), function(i) {
    reachable <- distance_matrix[i, is.finite(distance_matrix[i, ]) & distance_matrix[i, ] > 0]
    if (length(reachable) == 0L) 0 else length(reachable) / sum(reachable)
  }, numeric(1))
  betweenness <- .sequence_adv_unweighted_betweenness(binary)
  if (!directed) betweenness <- betweenness / 2
  transition <- adjacency
  dangling <- rowSums(transition) == 0
  if (any(!dangling)) transition[!dangling, ] <- transition[!dangling, , drop = FALSE] /
    rowSums(transition[!dangling, , drop = FALSE])
  if (any(dangling)) transition[dangling, ] <- 1 / n
  rank <- rep(1 / n, n)
  for (iter in seq_len(pagerank_max_iter)) {
    next_rank <- (1 - pagerank_damping) / n +
      pagerank_damping * as.numeric(t(transition) %*% rank)
    if (max(abs(next_rank - rank)) < pagerank_tolerance) {
      rank <- next_rank
      break
    }
    rank <- next_rank
  }
  rank <- .sequence_adv_vector_normalise(rank)
  data.frame(
    state = rownames(adjacency),
    out_degree = as.integer(out_degree),
    in_degree = as.integer(in_degree),
    total_degree = as.integer(total_degree),
    out_strength = as.numeric(out_strength),
    in_strength = as.numeric(in_strength),
    total_strength = as.numeric(total_strength),
    closeness = closeness,
    betweenness = betweenness,
    pagerank = rank,
    stringsAsFactors = FALSE
  )
}

#' Detect descriptive transition communities
#'
#' @param network A first-order transition network.
#' @param method `"label_propagation"` or `"components"`.
#' @param max_iter Maximum label-propagation iterations.
#' @param seed Reproducibility seed used only to rotate update order.
#'
#' @return A data frame with states and deterministic community labels.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' network <- create_transition_network(sequences)
#' detect_transition_communities(network)
#'
#' @export
detect_transition_communities <- function(network,
                                          method = c("label_propagation", "components"),
                                          max_iter = 100L, seed = 1L) {
  method <- match.arg(method)
  .sequence_adv_scalar_number(max_iter, "max_iter", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(seed, "seed", lower = 0, integer = TRUE)
  adjacency <- .sequence_adv_graph_matrix(network, use_weight = TRUE, symmetrise = TRUE)
  n <- nrow(adjacency)
  if (n == 0L) return(data.frame(state = character(), community = integer(), stringsAsFactors = FALSE))
  labels <- seq_len(n)
  if (method == "components") {
    community <- rep(NA_integer_, n)
    current <- 0L
    for (i in seq_len(n)) {
      if (!is.na(community[i])) next
      current <- current + 1L
      queue <- i; community[i] <- current
      while (length(queue) > 0L) {
        v <- queue[1L]; queue <- queue[-1L]
        neighbours <- which(adjacency[v, ] > 0)
        unseen <- neighbours[is.na(community[neighbours])]
        if (length(unseen)) {
          community[unseen] <- current
          queue <- c(queue, unseen)
        }
      }
    }
    labels <- community
  } else {
    base_order <- seq_len(n)
    if (n > 1L) {
      shift <- as.integer(seed %% n)
      if (shift > 0L) {
        base_order <- c(base_order[(shift + 1L):n], base_order[seq_len(shift)])
      }
    }
    for (iter in seq_len(max_iter)) {
      changed <- FALSE
      for (v in base_order) {
        neighbours <- which(adjacency[v, ] > 0)
        if (!length(neighbours)) next
        totals <- tapply(adjacency[v, neighbours], labels[neighbours], sum)
        winners <- as.integer(names(totals)[totals == max(totals)])
        new_label <- min(winners)
        if (new_label != labels[v]) {
          labels[v] <- new_label
          changed <- TRUE
        }
      }
      if (!changed) break
    }
    unique_labels <- sort(unique(labels))
    labels <- match(labels, unique_labels)
  }
  data.frame(state = rownames(adjacency), community = as.integer(labels),
             stringsAsFactors = FALSE)
}

#' Fit a higher-order transition model
#'
#' @param data Long-format sequence data.
#' @param sequence_id_col,order_col,state_col Sequence columns.
#' @param order Context order.
#' @param smoothing Additive smoothing over observed next states.
#' @param backoff Retain lower-order context tables for prediction backoff.
#' @param context_separator Context separator.
#'
#' @return An object of class `gp3_higher_order_transition_model`.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' fit_higher_order_transition_model(sequences, order = 2L)
#'
#' @export
fit_higher_order_transition_model <- function(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  order = 2L,
  smoothing = 0.5,
  backoff = TRUE,
  context_separator = " > "
) {
  .sequence_adv_scalar_number(order, "order", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(smoothing, "smoothing", lower = 0)
  .sequence_adv_scalar_logical(backoff, "backoff")
  .sequence_adv_scalar_character(context_separator, "context_separator")
  x <- .sequence_adv_data(data, sequence_id_col, order_col, state_col,
                          missing_state_policy = "error")
  if (any(grepl(context_separator, x$state_levels, fixed = TRUE))) {
    stop("`context_separator` must not occur inside an observed state label.",
         call. = FALSE)
  }
  build_level <- function(level) {
    contexts <- list(); h <- 0L
    for (id in x$sequence_ids) {
      seq <- x$sequences[[id]]
      if (length(seq) <= level) next
      for (i in seq_len(length(seq) - level)) {
        h <- h + 1L
        contexts[[h]] <- data.frame(
          context = paste(seq[i:(i + level - 1L)], collapse = context_separator),
          next_state = seq[i + level], stringsAsFactors = FALSE
        )
      }
    }
    if (length(contexts) == 0L) return(data.frame())
    events <- do.call(rbind, contexts)
    keys <- unique(events$context)
    out <- list(); z <- 0L
    for (context in sort(keys, method = "radix")) {
      counts <- table(factor(events$next_state[events$context == context], levels = x$state_levels))
      probabilities <- (as.numeric(counts) + smoothing) /
        (sum(counts) + smoothing * length(counts))
      for (j in seq_along(x$state_levels)) {
        z <- z + 1L
        out[[z]] <- data.frame(order = level, context = context,
                               next_state = x$state_levels[j], count = as.integer(counts[j]),
                               probability = probabilities[j], stringsAsFactors = FALSE)
      }
    }
    do.call(rbind, out)
  }
  levels <- if (backoff) seq_len(order) else order
  tables <- lapply(levels, build_level)
  names(tables) <- paste0("order_", levels)
  result <- list(order = as.integer(order), tables = tables,
                 state_levels = x$state_levels, smoothing = smoothing,
                 backoff = backoff, context_separator = context_separator)
  class(result) <- c("gp3_higher_order_transition_model", "list")
  result
}

#' Predict the next state from a transition model
#'
#' @param model A higher-order transition model.
#' @param history Character vector of observed recent states.
#' @param top_n Optional number of states to retain. Returned probabilities
#'   remain on the full-model scale and are not renormalised after truncation.
#'
#' @return A probability table ordered from highest to lowest probability,
#' with the context order actually used.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' model <- fit_higher_order_transition_model(sequences, order = 2L)
#' predict_next_state(model, c("A", "B"))
#'
#' @export
predict_next_state <- function(model, history, top_n = NULL) {
  if (!inherits(model, "gp3_higher_order_transition_model")) {
    stop("`model` must be created by `fit_higher_order_transition_model()`.", call. = FALSE)
  }
  if (!is.character(history) || length(history) < 1L || anyNA(history) ||
      any(!nzchar(trimws(history)))) {
    stop("`history` must be a non-missing, non-blank character vector.",
         call. = FALSE)
  }
  if (!is.null(top_n)) .sequence_adv_scalar_number(top_n, "top_n", lower = 1, integer = TRUE)
  available_orders <- sort(as.integer(sub("order_", "", names(model$tables))), decreasing = TRUE)
  used <- NA_integer_; table_used <- NULL; context_used <- NULL
  for (level in available_orders) {
    if (length(history) < level) next
    context <- paste(utils::tail(history, level), collapse = model$context_separator)
    table <- model$tables[[paste0("order_", level)]]
    if (!is.data.frame(table) || nrow(table) == 0L || !("context" %in% names(table))) next
    current <- table[table$context == context, , drop = FALSE]
    if (nrow(current) > 0L) {
      used <- level; table_used <- current; context_used <- context; break
    }
  }
  if (is.null(table_used)) {
    table_used <- data.frame(
      order = 0L,
      context = "<unseen>",
      next_state = model$state_levels,
      count = 0L,
      probability = rep(1 / length(model$state_levels), length(model$state_levels)),
      stringsAsFactors = FALSE
    )
    used <- 0L
    context_used <- "<unseen>"
  }
  table_used <- table_used[order(-table_used$probability, table_used$next_state,
                                 method = "radix"), , drop = FALSE]
  if (!is.null(top_n)) table_used <- utils::head(table_used, top_n)
  table_used$used_order <- used
  table_used$used_context <- context_used
  row.names(table_used) <- NULL
  table_used
}

#' Bootstrap transition-network edge weights
#'
#' @param data Long-format sequence data.
#' @param sequence_id_col,order_col,state_col Sequence columns.
#' @param n_boot Number of bootstrap samples of whole sequences.
#' @param level Confidence level for percentile intervals.
#' @param seed Reproducibility seed.
#' @param include_self Include self-transitions.
#'
#' @return A data frame containing observed edge weights, bootstrap means,
#' standard deviations, and percentile intervals.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' bootstrap_transition_network(sequences, n_boot = 5L, seed = 1L)
#'
#' @export
bootstrap_transition_network <- function(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  n_boot = 100L,
  level = 0.95,
  seed = 1L,
  include_self = TRUE
) {
  .sequence_adv_scalar_number(n_boot, "n_boot", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(level, "level", lower = 0.5, upper = 0.999)
  .sequence_adv_scalar_number(seed, "seed", lower = 0, integer = TRUE)
  .sequence_adv_scalar_logical(include_self, "include_self")
  x <- .sequence_adv_data(data, sequence_id_col, order_col, state_col,
                          missing_state_policy = "error")
  observed <- create_transition_network(x$data, sequence_id_col, order_col, state_col,
                                        include_self = include_self, normalise = "from")
  if (nrow(observed) == 0L) {
    stop("No first-order transitions are available to bootstrap.", call. = FALSE)
  }
  edge_key <- paste(observed$from_state, observed$to_state, sep = "\034")
  values <- matrix(0, nrow = nrow(observed), ncol = n_boot)
  .sequence_adv_with_seed(seed, {
    for (b in seq_len(n_boot)) {
      sampled <- sample(x$sequence_ids, length(x$sequence_ids), replace = TRUE)
      rows <- list(); h <- 0L
      for (i in seq_along(sampled)) {
        source_id <- sampled[i]
        current <- x$data[as.character(x$data[[sequence_id_col]]) == source_id, , drop = FALSE]
        current[[sequence_id_col]] <- paste0("boot", b, "_", i)
        h <- h + 1L
        rows[[h]] <- current
      }
      boot_data <- do.call(rbind, rows)
      boot <- create_transition_network(boot_data, sequence_id_col, order_col, state_col,
                                        include_self = include_self, normalise = "from")
      boot_key <- paste(boot$from_state, boot$to_state, sep = "\034")
      values[, b] <- boot$weight[match(edge_key, boot_key)]
      values[is.na(values[, b]), b] <- 0
    }
  })
  alpha <- (1 - level) / 2
  observed$bootstrap_mean <- rowMeans(values)
  observed$bootstrap_sd <- apply(values, 1L, stats::sd)
  observed$conf_low <- apply(values, 1L, stats::quantile, probs = alpha, names = FALSE)
  observed$conf_high <- apply(values, 1L, stats::quantile, probs = 1 - alpha, names = FALSE)
  observed$n_boot <- as.integer(n_boot)
  observed$confidence_level <- level
  observed
}
