#' Compute pairwise sequence distances
#'
#' Provides transparent base-R implementations of Levenshtein edit distance,
#' longest-common-subsequence distance, optimal matching, and a first-order
#' transition-profile distance.
#'
#' @param data Long-format sequence data or a prepared gp3sequences result.
#' @param sequence_id_col,order_col,state_col Sequence columns.
#' @param method Distance method.
#' @param indel_cost Non-negative insertion/deletion cost used by
#'   `method = "optimal_matching"`.
#' @param substitution_cost Non-negative default substitution cost used by
#'   `method = "optimal_matching"`.
#' @param substitution_matrix Optional named square substitution-cost matrix for
#'   `method = "optimal_matching"`.
#' @param transition_smoothing Non-negative smoothing for transition profiles.
#' @param normalise One of `"none"`, `"max_length"`, or `"path_length"`.
#'
#' @return A `dist` object with method and preprocessing metadata attached.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' compute_sequence_distance(sequences, method = "lcs")
#'
#' @export
compute_sequence_distance <- function(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  method = c("levenshtein", "lcs", "optimal_matching", "transition"),
  indel_cost = 1,
  substitution_cost = 1,
  substitution_matrix = NULL,
  transition_smoothing = 0,
  normalise = c("none", "max_length", "path_length")
) {
  method <- match.arg(method)
  normalise <- match.arg(normalise)
  .sequence_adv_scalar_number(indel_cost, "indel_cost", lower = 0)
  .sequence_adv_scalar_number(substitution_cost, "substitution_cost", lower = 0)
  .sequence_adv_scalar_number(transition_smoothing, "transition_smoothing", lower = 0)
  x <- .sequence_adv_data(data, sequence_id_col, order_col, state_col,
                          missing_state_policy = "error")
  ids <- x$sequence_ids
  seqs <- x$sequences
  n <- length(seqs)
  matrix_out <- matrix(0, nrow = n, ncol = n, dimnames = list(ids, ids))
  if (!is.null(substitution_matrix)) {
    if (!is.matrix(substitution_matrix) || !is.numeric(substitution_matrix) ||
        nrow(substitution_matrix) != ncol(substitution_matrix) ||
        is.null(rownames(substitution_matrix)) || is.null(colnames(substitution_matrix)) ||
        anyNA(substitution_matrix) || any(!is.finite(substitution_matrix)) ||
        any(substitution_matrix < 0) || anyNA(rownames(substitution_matrix)) ||
        anyNA(colnames(substitution_matrix)) || anyDuplicated(rownames(substitution_matrix)) ||
        anyDuplicated(colnames(substitution_matrix)) ||
        !setequal(rownames(substitution_matrix), colnames(substitution_matrix))) {
      stop("`substitution_matrix` must be a finite, non-negative, named square matrix.",
           call. = FALSE)
    }
    missing_states <- setdiff(x$state_levels, rownames(substitution_matrix))
    if (length(missing_states) > 0L) {
      stop("The substitution matrix does not cover all observed states: ",
           paste(missing_states, collapse = ", "), ".", call. = FALSE)
    }
    substitution_matrix <- substitution_matrix[rownames(substitution_matrix),
                                               rownames(substitution_matrix), drop = FALSE]
    tolerance <- sqrt(.Machine$double.eps)
    if (max(abs(substitution_matrix - t(substitution_matrix))) > tolerance) {
      stop("`substitution_matrix` must be symmetric for a sequence distance.",
           call. = FALSE)
    }
    if (max(abs(diag(substitution_matrix))) > tolerance) {
      stop("The diagonal of `substitution_matrix` must be zero.", call. = FALSE)
    }
  }
  pairs <- .sequence_adv_pair_grid(ids)
  if (nrow(pairs) > 0L) {
    for (r in seq_len(nrow(pairs))) {
      i <- pairs[r, 1L]
      j <- pairs[r, 2L]
      a <- seqs[[i]]
      b <- seqs[[j]]
      raw <- switch(
        method,
        levenshtein = .sequence_adv_edit_distance(a, b, 1, 1, NULL),
        lcs = length(a) + length(b) - 2L * .sequence_adv_lcs_length(a, b),
        optimal_matching = .sequence_adv_edit_distance(
          a, b, indel_cost, substitution_cost, substitution_matrix
        ),
        transition = {
          pa <- .sequence_adv_transition_profile(a, x$state_levels, transition_smoothing)
          pb <- .sequence_adv_transition_profile(b, x$state_levels, transition_smoothing)
          sqrt(sum((pa - pb)^2))
        }
      )
      denominator <- switch(
        normalise,
        none = 1,
        max_length = max(length(a), length(b), 1L),
        path_length = max(length(a) + length(b), 1L)
      )
      value <- raw / denominator
      matrix_out[i, j] <- value
      matrix_out[j, i] <- value
    }
  }
  result <- stats::as.dist(matrix_out)
  attr(result, "method") <- method
  attr(result, "sequence_ids") <- ids
  attr(result, "state_levels") <- x$state_levels
  attr(result, "settings") <- list(
    indel_cost = indel_cost,
    substitution_cost = substitution_cost,
    substitution_matrix = substitution_matrix,
    transition_smoothing = transition_smoothing,
    normalise = normalise
  )
  class(result) <- unique(c("gp3_sequence_distance", class(result)))
  result
}

#' Summarise a sequence-distance object
#'
#' @param distance A distance object returned by [compute_sequence_distance()].
#'
#' @return A list containing an overall summary and per-sequence mean, median,
#' minimum, and maximum distances.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' distance <- compute_sequence_distance(sequences)
#' summarise_sequence_distance(distance)
#'
#' @export
summarise_sequence_distance <- function(distance) {
  matrix_distance <- .sequence_adv_distance_matrix(distance)
  n <- nrow(matrix_distance)
  values <- if (n > 1L) matrix_distance[upper.tri(matrix_distance)] else numeric()
  overall <- data.frame(
    n_sequences = as.integer(n),
    n_pairs = as.integer(length(values)),
    mean_distance = if (length(values)) mean(values) else NA_real_,
    median_distance = if (length(values)) stats::median(values) else NA_real_,
    min_distance = if (length(values)) min(values) else NA_real_,
    max_distance = if (length(values)) max(values) else NA_real_,
    stringsAsFactors = FALSE
  )
  per_sequence <- lapply(seq_len(n), function(i) {
    others <- matrix_distance[i, -i, drop = TRUE]
    data.frame(
      sequence_id = rownames(matrix_distance)[i],
      mean_distance = if (length(others)) mean(others) else NA_real_,
      median_distance = if (length(others)) stats::median(others) else NA_real_,
      min_distance = if (length(others)) min(others) else NA_real_,
      max_distance = if (length(others)) max(others) else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  list(overall = overall, per_sequence = do.call(rbind, per_sequence),
       method = attr(distance, "method"), settings = attr(distance, "settings"))
}

#' Cluster sequences from a distance object
#'
#' @param distance A `dist` object or square matrix.
#' @param k Number of clusters.
#' @param method `"hierarchical"`, `"pam"`, or `"clara"`.
#' @param linkage Hierarchical linkage method.
#' @param seed Reproducibility seed for optional stochastic methods.
#' @param ... Additional arguments passed to the selected clustering function.
#'
#' @return A list of class `gp3_sequence_clustering` containing assignments,
#' model object, medoid identifiers where available, and settings.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' distance <- compute_sequence_distance(sequences)
#' cluster_sequences(distance, k = 2L)
#'
#' @export
cluster_sequences <- function(distance, k,
                              method = c("hierarchical", "pam", "clara"),
                              linkage = "average", seed = 1L, ...) {
  method <- match.arg(method)
  .sequence_adv_scalar_number(k, "k", lower = 2, integer = TRUE)
  .sequence_adv_scalar_number(seed, "seed", lower = 0, integer = TRUE)
  if (!is.character(linkage) || length(linkage) != 1L || is.na(linkage) ||
      !(linkage %in% c("ward.D", "ward.D2", "single", "complete", "average",
                      "mcquitty", "median", "centroid"))) {
    stop("`linkage` is not a supported `stats::hclust()` method.", call. = FALSE)
  }
  matrix_distance <- .sequence_adv_distance_matrix(distance)
  n <- nrow(matrix_distance)
  if (k >= n) stop("`k` must be smaller than the number of sequences.", call. = FALSE)
  ids <- rownames(matrix_distance)
  dots <- list(...)
  if (length(dots) > 0L && (is.null(names(dots)) || any(!nzchar(names(dots))))) {
    stop("All additional clustering arguments in `...` must be named.",
         call. = FALSE)
  }
  protected <- intersect(names(dots), c("x", "k", "diss", "metric"))
  if (length(protected) > 0L) {
    stop("Do not supply protected clustering arguments through `...`: ",
         paste(protected, collapse = ", "), ".", call. = FALSE)
  }
  if (method == "hierarchical") {
    allowed <- intersect(names(dots), "members")
    unexpected <- setdiff(names(dots), allowed)
    if (length(unexpected) > 0L) {
      stop("Unsupported hierarchical clustering arguments: ",
           paste(unexpected, collapse = ", "), ".", call. = FALSE)
    }
    model <- do.call(
      stats::hclust,
      c(list(d = stats::as.dist(matrix_distance), method = linkage), dots)
    )
    assignments <- stats::cutree(model, k = k)
    assignments <- assignments[ids]
    medoids <- vapply(sort(unique(assignments)), function(cluster_id) {
      members <- which(assignments == cluster_id)
      if (length(members) == 1L) return(ids[members])
      ids[members[which.min(rowSums(matrix_distance[members, members, drop = FALSE]))]]
    }, character(1))
  } else if (method == "pam") {
    .sequence_adv_require("cluster", "run partitioning around medoids")
    model <- .sequence_adv_with_seed(
      seed,
      do.call(
        cluster::pam,
        c(list(x = stats::as.dist(matrix_distance), k = k, diss = TRUE), dots)
      )
    )
    assignments <- stats::setNames(as.integer(model$clustering), ids)
    medoids <- ids[model$id.med]
  } else {
    .sequence_adv_require("cluster", "run CLARA clustering")
    embedding_dimension <- min(n - 1L, max(2L, as.integer(k)))
    embedding_result <- stats::cmdscale(
      stats::as.dist(matrix_distance),
      k = embedding_dimension,
      eig = FALSE,
      add = TRUE
    )
    embedding <- if (is.list(embedding_result)) embedding_result$points else embedding_result
    if (!is.matrix(embedding) || nrow(embedding) != n) {
      stop("Classical multidimensional scaling did not return a usable CLARA embedding.",
           call. = FALSE)
    }
    if (is.null(dots$rngR)) {
      dots$rngR <- TRUE
    } else if (!isTRUE(dots$rngR)) {
      stop("CLARA reproducibility requires `rngR = TRUE`.", call. = FALSE)
    }
    model <- .sequence_adv_with_seed(
      seed,
      do.call(
        cluster::clara,
        c(list(x = embedding, k = k, metric = "euclidean"), dots)
      )
    )
    assignments <- stats::setNames(as.integer(model$clustering), ids)
    medoids <- ids[model$i.med]
  }
  result <- list(
    assignments = assignments,
    model = model,
    medoids = as.character(medoids),
    k = as.integer(k),
    method = method,
    linkage = if (method == "hierarchical") linkage else NULL,
    distance = stats::as.dist(matrix_distance),
    seed = as.integer(seed)
  )
  class(result) <- c("gp3_sequence_clustering", "list")
  result
}

#' Validate sequence clusters descriptively
#'
#' @param clustering A result from [cluster_sequences()] or a named assignment
#' vector.
#' @param distance Optional distance object when `clustering` is an assignment
#' vector.
#'
#' @return A list containing overall validation metrics, cluster sizes, and
#' per-sequence silhouette values.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' distance <- compute_sequence_distance(sequences)
#' fit <- cluster_sequences(distance, k = 2L)
#' validate_sequence_clusters(fit)
#'
#' @export
validate_sequence_clusters <- function(clustering, distance = NULL) {
  if (inherits(clustering, "gp3_sequence_clustering")) {
    assignments <- clustering$assignments
    matrix_distance <- .sequence_adv_distance_matrix(clustering$distance)
  } else {
    assignments <- clustering
    matrix_distance <- .sequence_adv_distance_matrix(distance)
  }
  if (is.null(names(assignments)) || anyNA(names(assignments)) ||
      any(!nzchar(names(assignments))) || anyDuplicated(names(assignments))) {
    stop("Cluster assignments must have unique sequence-ID names.", call. = FALSE)
  }
  ids <- rownames(matrix_distance)
  if (!setequal(names(assignments), ids)) {
    stop("Assignment names and distance-matrix identifiers must match.", call. = FALSE)
  }
  assignments <- assignments[ids]
  if (anyNA(assignments) || length(unique(assignments)) < 2L) {
    stop("At least two non-missing clusters are required.", call. = FALSE)
  }
  silhouette <- .sequence_adv_silhouette(assignments, matrix_distance)
  clusters <- sort(unique(assignments))
  cluster_sizes <- table(factor(assignments, levels = clusters))
  max_intra <- 0
  min_inter <- Inf
  within_values <- numeric()
  between_values <- numeric()
  for (i in seq_len(nrow(matrix_distance) - 1L)) {
    for (j in seq.int(i + 1L, nrow(matrix_distance))) {
      if (assignments[i] == assignments[j]) {
        within_values <- c(within_values, matrix_distance[i, j])
        max_intra <- max(max_intra, matrix_distance[i, j])
      } else {
        between_values <- c(between_values, matrix_distance[i, j])
        min_inter <- min(min_inter, matrix_distance[i, j])
      }
    }
  }
  dunn <- if (max_intra > 0 && is.finite(min_inter)) min_inter / max_intra else NA_real_
  ratio <- if (length(within_values) && length(between_values) && mean(between_values) > 0) {
    mean(within_values) / mean(between_values)
  } else NA_real_
  overall <- data.frame(
    n_sequences = length(assignments),
    n_clusters = length(clusters),
    average_silhouette = mean(silhouette),
    minimum_silhouette = min(silhouette),
    dunn_index = dunn,
    within_between_ratio = ratio,
    singleton_clusters = sum(cluster_sizes == 1L),
    stringsAsFactors = FALSE
  )
  per_sequence <- data.frame(
    sequence_id = ids,
    cluster = as.character(assignments),
    silhouette = as.numeric(silhouette),
    stringsAsFactors = FALSE
  )
  sizes <- data.frame(cluster = as.character(clusters), size = as.integer(cluster_sizes),
                      stringsAsFactors = FALSE)
  list(overall = overall, cluster_sizes = sizes, per_sequence = per_sequence)
}

#' Extract representative sequences from clusters
#'
#' @param clustering A clustering result.
#' @param distance Optional distance when absent from `clustering`.
#' @param n_per_cluster Number of representatives per cluster.
#'
#' @return A data frame with cluster, rank, representative ID, and mean
#' within-cluster distance.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' distance <- compute_sequence_distance(sequences)
#' fit <- cluster_sequences(distance, k = 2L)
#' extract_representative_sequences(fit)
#'
#' @export
extract_representative_sequences <- function(clustering, distance = NULL,
                                             n_per_cluster = 1L) {
  .sequence_adv_scalar_number(n_per_cluster, "n_per_cluster", lower = 1, integer = TRUE)
  if (inherits(clustering, "gp3_sequence_clustering")) {
    assignments <- clustering$assignments
    matrix_distance <- .sequence_adv_distance_matrix(clustering$distance)
  } else {
    assignments <- clustering
    matrix_distance <- .sequence_adv_distance_matrix(distance)
  }
  ids <- rownames(matrix_distance)
  if (is.null(names(assignments)) || !setequal(names(assignments), ids) || anyNA(assignments)) {
    stop("Cluster assignments must be non-missing and named for every sequence.",
         call. = FALSE)
  }
  assignments <- assignments[ids]
  pieces <- lapply(sort(unique(assignments)), function(k) {
    members <- which(assignments == k)
    scores <- if (length(members) == 1L) {
      0
    } else {
      rowSums(matrix_distance[members, members, drop = FALSE]) / (length(members) - 1L)
    }
    order_members <- members[order(scores, ids[members], method = "radix")]
    selected <- utils::head(order_members, n_per_cluster)
    data.frame(cluster = as.character(k), rank = seq_along(selected),
               sequence_id = ids[selected], mean_within_distance = scores[match(selected, members)],
               stringsAsFactors = FALSE)
  })
  result <- do.call(rbind, pieces)
  row.names(result) <- NULL
  result
}

#' Bootstrap sequence-cluster stability
#'
#' Uses repeated subsampling without replacement and records pairwise
#' co-clustering agreement relative to the full-data solution.
#'
#' @param distance Sequence distance object.
#' @param k Number of clusters.
#' @param method Clustering method.
#' @param n_boot Number of subsamples.
#' @param sample_fraction Fraction of sequences sampled in each iteration.
#' @param seed Reproducibility seed.
#' @param linkage Hierarchical linkage.
#' @param ... Additional clustering arguments.
#'
#' @return An object of class `gp3_sequence_cluster_bootstrap`.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' distance <- compute_sequence_distance(sequences)
#' bootstrap_sequence_clusters(distance, k = 2L, n_boot = 5L, seed = 1L)
#'
#' @export
bootstrap_sequence_clusters <- function(distance, k,
                                        method = c("hierarchical", "pam", "clara"),
                                        n_boot = 100L, sample_fraction = 0.8,
                                        seed = 1L, linkage = "average", ...) {
  method <- match.arg(method)
  .sequence_adv_scalar_number(k, "k", lower = 2, integer = TRUE)
  .sequence_adv_scalar_number(n_boot, "n_boot", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(sample_fraction, "sample_fraction", lower = 0.2, upper = 1)
  .sequence_adv_scalar_number(seed, "seed", lower = 0, integer = TRUE)
  matrix_distance <- .sequence_adv_distance_matrix(distance)
  ids <- rownames(matrix_distance)
  n <- length(ids)
  sample_n <- max(k + 1L, floor(n * sample_fraction))
  if (sample_n > n) stop("The requested subsample is too small for `k`.", call. = FALSE)
  original <- cluster_sequences(stats::as.dist(matrix_distance), k, method, linkage, seed, ...)
  original_same <- outer(original$assignments, original$assignments, `==`)
  evaluated <- matrix(0L, n, n, dimnames = list(ids, ids))
  matched <- matrix(0L, n, n, dimnames = list(ids, ids))
  iteration_rows <- vector("list", n_boot)
  .sequence_adv_with_seed(seed, {
    for (b in seq_len(n_boot)) {
      selected <- sort(sample(seq_len(n), sample_n, replace = FALSE))
      sub_matrix <- matrix_distance[selected, selected, drop = FALSE]
      fit <- cluster_sequences(stats::as.dist(sub_matrix), k, method, linkage,
                               seed = .sequence_adv_seed(seed, b), ...)
      current_same <- outer(fit$assignments, fit$assignments, `==`)
      evaluated[selected, selected] <- evaluated[selected, selected] + 1L
      matched[selected, selected] <- matched[selected, selected] +
        (current_same == original_same[selected, selected])
      iteration_rows[[b]] <- data.frame(
        iteration = b,
        n_sampled = length(selected),
        average_silhouette = validate_sequence_clusters(fit)$overall$average_silhouette,
        stringsAsFactors = FALSE
      )
    }
  })
  stability <- matrix(NA_real_, n, n, dimnames = list(ids, ids))
  valid <- evaluated > 0L
  stability[valid] <- matched[valid] / evaluated[valid]
  diag(stability) <- 1
  pair_values <- stability[upper.tri(stability)]
  finite_pair_values <- pair_values[is.finite(pair_values)]
  result <- list(
    original = original,
    pairwise_stability = stability,
    evaluated_counts = evaluated,
    iterations = do.call(rbind, iteration_rows),
    overall = data.frame(
      n_boot = as.integer(n_boot), sample_fraction = sample_fraction,
      mean_pairwise_stability = if (length(finite_pair_values)) mean(finite_pair_values) else NA_real_,
      min_pairwise_stability = if (length(finite_pair_values)) min(finite_pair_values) else NA_real_,
      stringsAsFactors = FALSE
    ),
    settings = list(
      k = as.integer(k),
      method = method,
      linkage = linkage,
      n_boot = as.integer(n_boot),
      sample_fraction = sample_fraction,
      seed = as.integer(seed)
    )
  )
  class(result) <- c("gp3_sequence_cluster_bootstrap", "list")
  result
}

#' Summarise sequence-cluster stability
#'
#' @param bootstrap A result from [bootstrap_sequence_clusters()].
#' @param threshold Pairwise stability threshold.
#'
#' @return Overall, cluster-level, and low-stability pair summaries.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' distance <- compute_sequence_distance(sequences)
#' boot <- bootstrap_sequence_clusters(distance, k = 2L, n_boot = 5L)
#' summarise_sequence_cluster_stability(boot)
#'
#' @export
summarise_sequence_cluster_stability <- function(bootstrap, threshold = 0.8) {
  if (!inherits(bootstrap, "gp3_sequence_cluster_bootstrap")) {
    stop("`bootstrap` must be created by `bootstrap_sequence_clusters()`.", call. = FALSE)
  }
  .sequence_adv_scalar_number(threshold, "threshold", lower = 0, upper = 1)
  assignments <- bootstrap$original$assignments
  matrix_stability <- bootstrap$pairwise_stability
  clusters <- sort(unique(assignments))
  cluster_summary <- do.call(rbind, lapply(clusters, function(k) {
    ids <- names(assignments)[assignments == k]
    values <- if (length(ids) > 1L) {
      current <- matrix_stability[ids, ids, drop = FALSE]
      current[upper.tri(current)]
    } else 1
    finite_values <- values[is.finite(values)]
    evaluated_pairs <- if (length(ids) > 1L) length(finite_values) else 0L
    data.frame(
      cluster = as.character(k),
      n_sequences = length(ids),
      mean_within_stability = if (length(finite_values)) mean(finite_values) else NA_real_,
      min_within_stability = if (length(finite_values)) min(finite_values) else NA_real_,
      n_evaluated_pairs = as.integer(evaluated_pairs),
      stringsAsFactors = FALSE
    )
  }))
  pairs <- which(upper.tri(matrix_stability) & matrix_stability < threshold, arr.ind = TRUE)
  low_pairs <- if (nrow(pairs) == 0L) {
    data.frame(sequence_id_1 = character(), sequence_id_2 = character(),
               stability = numeric(), stringsAsFactors = FALSE)
  } else {
    data.frame(sequence_id_1 = rownames(matrix_stability)[pairs[, 1L]],
               sequence_id_2 = colnames(matrix_stability)[pairs[, 2L]],
               stability = matrix_stability[pairs], stringsAsFactors = FALSE)
  }
  list(overall = bootstrap$overall, clusters = cluster_summary,
       low_stability_pairs = low_pairs, threshold = threshold)
}

#' Create a sequence-cluster ensemble
#'
#' Combines multiple named cluster assignments through a co-association matrix
#' and applies hierarchical clustering to `1 - co-association`.
#'
#' @param ... Two or more `gp3_sequence_clustering` objects or named assignment
#' vectors.
#' @param k Number of consensus clusters.
#' @param linkage Hierarchical linkage applied to the co-association distance.
#'
#' @return An object of class `gp3_sequence_cluster_ensemble` containing the
#' consensus assignments, co-association matrix, model, and source solutions.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' d1 <- compute_sequence_distance(sequences, method = "lcs")
#' d2 <- compute_sequence_distance(sequences, method = "transition")
#' create_sequence_cluster_ensemble(cluster_sequences(d1, 2L),
#'                                  cluster_sequences(d2, 2L), k = 2L)
#'
#' @export
create_sequence_cluster_ensemble <- function(..., k, linkage = "average") {
  solutions <- list(...)
  if (length(solutions) < 2L) stop("Supply at least two clustering solutions.", call. = FALSE)
  .sequence_adv_scalar_number(k, "k", lower = 2, integer = TRUE)
  if (!is.character(linkage) || length(linkage) != 1L || is.na(linkage) ||
      !(linkage %in% c("ward.D", "ward.D2", "single", "complete", "average",
                       "mcquitty", "median", "centroid"))) {
    stop("`linkage` is not a supported `stats::hclust()` method.", call. = FALSE)
  }
  assignments <- lapply(solutions, function(solution) {
    if (inherits(solution, "gp3_sequence_clustering")) solution$assignments else solution
  })
  if (any(vapply(assignments, is.null, logical(1))) ||
      any(vapply(assignments, function(x) {
        is.null(names(x)) || anyNA(x) || anyNA(names(x)) || any(!nzchar(names(x))) ||
          anyDuplicated(names(x))
      }, logical(1)))) {
    stop("Every solution must provide non-missing assignments with unique sequence-ID names.",
         call. = FALSE)
  }
  ids <- names(assignments[[1L]])
  if (!all(vapply(assignments, function(x) setequal(names(x), ids), logical(1)))) {
    stop("All clustering solutions must cover the same sequence IDs.", call. = FALSE)
  }
  n <- length(ids)
  if (k >= n) stop("`k` must be smaller than the number of sequences.", call. = FALSE)
  coassociation <- matrix(0, n, n, dimnames = list(ids, ids))
  for (assignment in assignments) {
    assignment <- assignment[ids]
    coassociation <- coassociation + outer(assignment, assignment, `==`)
  }
  coassociation <- coassociation / length(assignments)
  diag(coassociation) <- 1
  ensemble_distance <- stats::as.dist(1 - coassociation)
  model <- stats::hclust(ensemble_distance, method = linkage)
  consensus <- stats::cutree(model, k = k)
  consensus <- consensus[ids]
  result <- list(
    assignments = consensus,
    coassociation = coassociation,
    distance = ensemble_distance,
    model = model,
    source_assignments = assignments,
    k = as.integer(k),
    linkage = linkage
  )
  class(result) <- c("gp3_sequence_cluster_ensemble", "list")
  result
}
