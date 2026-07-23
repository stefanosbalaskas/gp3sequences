# Internal helpers for the advanced gp3sequences roadmap.

.sequence_adv_scalar_character <- function(x, argument, allow_null = FALSE) {
  if (allow_null && is.null(x)) {
    return(invisible(NULL))
  }
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    stop("`", argument, "` must be a single non-missing character value.", call. = FALSE)
  }
  invisible(NULL)
}

.sequence_adv_scalar_number <- function(x, argument, lower = -Inf, upper = Inf,
                                        integer = FALSE) {
  valid_scalar <- is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x)
  invalid_integer <- if (integer && valid_scalar) {
    x != trunc(x) || x < -.Machine$integer.max || x > .Machine$integer.max
  } else FALSE
  if (!valid_scalar || x < lower || x > upper || invalid_integer) {
    stop("`", argument, "` has an invalid numeric value.", call. = FALSE)
  }
  invisible(NULL)
}

.sequence_adv_scalar_logical <- function(x, argument) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop("`", argument, "` must be a single non-missing logical value.",
         call. = FALSE)
  }
  invisible(NULL)
}

.sequence_adv_match_cols <- function(data, columns, argument, allow_null = TRUE) {
  if (allow_null && is.null(columns)) {
    return(character())
  }
  if (!is.character(columns) || anyNA(columns) || any(!nzchar(columns)) ||
      anyDuplicated(columns)) {
    stop("`", argument, "` must contain unique, non-missing column names.", call. = FALSE)
  }
  missing <- setdiff(columns, names(data))
  if (length(missing) > 0L) {
    stop("Missing columns in `", argument, "`: ", paste(missing, collapse = ", "), ".",
         call. = FALSE)
  }
  columns
}

.sequence_adv_data <- function(data, sequence_id_col = "sequence_id",
                               order_col = "sequence_order", state_col = "state",
                               metadata_cols = NULL,
                               missing_state_policy = c("error", "drop", "state"),
                               missing_state_label = "<MISSING>") {
  missing_state_policy <- match.arg(missing_state_policy)
  if (missing_state_policy == "state") {
    .sequence_adv_scalar_character(missing_state_label, "missing_state_label")
  }
  if (is.list(data) && !is.data.frame(data) && !is.null(data$data)) {
    data <- data$data
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame or an object with a data-frame `data` component.",
         call. = FALSE)
  }
  .sequence_adv_scalar_character(sequence_id_col, "sequence_id_col")
  .sequence_adv_scalar_character(order_col, "order_col")
  .sequence_adv_scalar_character(state_col, "state_col")
  metadata_cols <- .sequence_adv_match_cols(data, metadata_cols, "metadata_cols")
  required <- c(sequence_id_col, order_col, state_col)
  overlap <- intersect(metadata_cols, required)
  if (length(overlap) > 0L) {
    stop("`metadata_cols` must not repeat core sequence columns: ",
         paste(overlap, collapse = ", "), ".", call. = FALSE)
  }
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop("Missing required sequence columns: ", paste(missing, collapse = ", "), ".",
         call. = FALSE)
  }
  if (nrow(data) == 0L) {
    stop("`data` must contain at least one sequence row.", call. = FALSE)
  }
  if (anyDuplicated(names(data))) {
    stop("`data` contains duplicated column names.", call. = FALSE)
  }
  id <- data[[sequence_id_col]]
  ord <- data[[order_col]]
  state <- data[[state_col]]
  if (is.list(id) || is.list(state)) {
    stop("Sequence identifiers and states must be atomic vectors.", call. = FALSE)
  }
  if (!is.numeric(ord) || anyNA(ord) || any(!is.finite(ord))) {
    stop("The sequence order column must contain finite, non-missing numeric values.",
         call. = FALSE)
  }
  id_text <- as.character(id)
  state_text <- as.character(state)
  missing_id <- is.na(id) | trimws(id_text) == ""
  if (any(missing_id)) {
    stop("Sequence identifiers must not be missing or blank.", call. = FALSE)
  }
  missing_state <- is.na(state) | trimws(state_text) == ""
  if (missing_state_policy == "error" && any(missing_state)) {
    stop("Missing states were found. Select an explicit non-error policy to continue.",
         call. = FALSE)
  }
  working <- data
  working$.gp3_adv_original_row <- seq_len(nrow(working))
  if (missing_state_policy == "drop") {
    working <- working[!missing_state, , drop = FALSE]
  } else if (missing_state_policy == "state") {
    replacement <- as.character(working[[state_col]])
    replacement[missing_state] <- missing_state_label
    working[[state_col]] <- replacement
  }
  if (nrow(working) == 0L) {
    stop("No sequence rows remain after applying the missing-state policy.", call. = FALSE)
  }
  keys <- paste(as.character(working[[sequence_id_col]]),
                format(working[[order_col]], digits = 17L, scientific = FALSE),
                sep = "\034")
  if (anyDuplicated(keys)) {
    stop("Duplicated sequence positions were found. Prepare the data before advanced analysis.",
         call. = FALSE)
  }
  index <- order(as.character(working[[sequence_id_col]]), working[[order_col]],
                 working$.gp3_adv_original_row, method = "radix")
  working <- working[index, , drop = FALSE]
  row.names(working) <- NULL
  seq_ids <- unique(as.character(working[[sequence_id_col]]))
  split_rows <- split(seq_len(nrow(working)),
                      factor(as.character(working[[sequence_id_col]]), levels = seq_ids),
                      drop = TRUE)
  sequences <- lapply(split_rows, function(rows) as.character(working[[state_col]][rows]))
  orders <- lapply(split_rows, function(rows) working[[order_col]][rows])
  names(sequences) <- seq_ids
  names(orders) <- seq_ids
  observed_states <- unique(as.character(working[[state_col]]))
  state_levels <- if (is.factor(working[[state_col]])) {
    levels(working[[state_col]])[levels(working[[state_col]]) %in% observed_states]
  } else {
    sort(observed_states, method = "radix")
  }
  metadata <- NULL
  if (length(metadata_cols) > 0L) {
    metadata <- do.call(rbind, lapply(seq_along(split_rows), function(i) {
      rows <- split_rows[[i]]
      values <- working[rows, metadata_cols, drop = FALSE]
      inconsistent <- vapply(values, function(x) {
        encoded <- as.character(x)
        encoded[is.na(x)] <- "<NA>"
        length(unique(encoded)) > 1L
      }, logical(1))
      if (any(inconsistent)) {
        stop("Metadata vary within sequence `", seq_ids[i], "`: ",
             paste(names(inconsistent)[inconsistent], collapse = ", "), ".", call. = FALSE)
      }
      out <- values[1L, , drop = FALSE]
      out[[sequence_id_col]] <- seq_ids[i]
      out[c(sequence_id_col, metadata_cols)]
    }))
    row.names(metadata) <- NULL
  }
  list(
    data = working,
    sequences = sequences,
    orders = orders,
    sequence_ids = seq_ids,
    state_levels = state_levels,
    metadata = metadata,
    columns = list(sequence_id = sequence_id_col, order = order_col, state = state_col,
                   metadata = metadata_cols)
  )
}

.sequence_adv_group_key <- function(data, group_cols) {
  if (length(group_cols) == 0L) {
    return(rep("__all__", nrow(data)))
  }
  values <- lapply(data[group_cols], function(x) {
    y <- as.character(x)
    y[is.na(y)] <- "<NA>"
    y
  })
  do.call(paste, c(values, sep = "\035"))
}

.sequence_adv_state_order <- function(values, state_levels = NULL) {
  observed <- unique(as.character(values[!is.na(values)]))
  if (is.null(state_levels)) {
    return(sort(observed, method = "radix"))
  }
  if (is.list(state_levels)) {
    stop("`state_levels` must be an atomic vector.", call. = FALSE)
  }
  state_levels <- as.character(state_levels)
  if (anyNA(state_levels) || any(!nzchar(trimws(state_levels))) ||
      anyDuplicated(state_levels)) {
    stop("`state_levels` must contain unique, non-missing, non-blank values.",
         call. = FALSE)
  }
  c(state_levels[state_levels %in% observed],
    sort(setdiff(observed, state_levels), method = "radix"))
}

.sequence_adv_tie <- function(states, weights, state_levels, tie_method) {
  totals <- tapply(weights, states, sum)
  totals <- totals[!is.na(names(totals))]
  max_total <- max(totals)
  tied <- names(totals)[abs(totals - max_total) <= sqrt(.Machine$double.eps)]
  ordered <- .sequence_adv_state_order(tied, state_levels)
  selected <- switch(
    tie_method,
    first = ordered[1L],
    last = ordered[length(ordered)],
    missing = if (length(ordered) == 1L) ordered else NA_character_,
    all = paste(ordered, collapse = " | ")
  )
  list(selected = selected, tied = ordered, total = max_total,
       agreement = max_total / sum(weights))
}

.sequence_adv_pair_grid <- function(ids) {
  if (length(ids) < 2L) {
    return(matrix(integer(), nrow = 0L, ncol = 2L))
  }
  t(utils::combn(seq_along(ids), 2L))
}

.sequence_adv_edit_distance <- function(a, b, indel_cost = 1,
                                        substitution_cost = 1,
                                        substitution_matrix = NULL) {
  n <- length(a)
  m <- length(b)
  d <- matrix(0, nrow = n + 1L, ncol = m + 1L)
  d[, 1L] <- (0:n) * indel_cost
  d[1L, ] <- (0:m) * indel_cost
  if (n == 0L || m == 0L) {
    return(d[n + 1L, m + 1L])
  }
  cost_fun <- function(x, y) {
    if (identical(x, y)) return(0)
    if (is.null(substitution_matrix)) return(substitution_cost)
    if (!(x %in% rownames(substitution_matrix)) || !(y %in% colnames(substitution_matrix))) {
      stop("The substitution matrix does not cover all observed states.", call. = FALSE)
    }
    substitution_matrix[x, y]
  }
  for (i in seq_len(n)) {
    for (j in seq_len(m)) {
      d[i + 1L, j + 1L] <- min(
        d[i, j + 1L] + indel_cost,
        d[i + 1L, j] + indel_cost,
        d[i, j] + cost_fun(a[i], b[j])
      )
    }
  }
  d[n + 1L, m + 1L]
}

.sequence_adv_lcs_length <- function(a, b) {
  n <- length(a)
  m <- length(b)
  if (n == 0L || m == 0L) return(0L)
  previous <- integer(m + 1L)
  for (i in seq_len(n)) {
    current <- integer(m + 1L)
    for (j in seq_len(m)) {
      current[j + 1L] <- if (identical(a[i], b[j])) {
        previous[j] + 1L
      } else {
        max(previous[j + 1L], current[j])
      }
    }
    previous <- current
  }
  previous[m + 1L]
}

.sequence_adv_transition_profile <- function(sequence, states, smoothing = 0) {
  p <- length(states)
  out <- matrix(smoothing, nrow = p, ncol = p, dimnames = list(states, states))
  if (length(sequence) > 1L) {
    for (i in seq_len(length(sequence) - 1L)) {
      out[sequence[i], sequence[i + 1L]] <- out[sequence[i], sequence[i + 1L]] + 1
    }
  }
  row_totals <- rowSums(out)
  nonzero <- row_totals > 0
  out[nonzero, ] <- out[nonzero, , drop = FALSE] / row_totals[nonzero]
  as.numeric(out)
}

.sequence_adv_distance_matrix <- function(x) {
  if (inherits(x, "dist")) {
    matrix_x <- as.matrix(x)
  } else if (is.matrix(x) && nrow(x) == ncol(x)) {
    matrix_x <- x
  } else {
    stop("A `dist` object or square distance matrix is required.", call. = FALSE)
  }
  if (!is.numeric(matrix_x) || anyNA(matrix_x) || any(!is.finite(matrix_x)) ||
      any(matrix_x < 0)) {
    stop("Sequence distances must be finite, non-missing, and non-negative.",
         call. = FALSE)
  }
  if (nrow(matrix_x) == 0L) {
    stop("The distance object must contain at least one sequence.", call. = FALSE)
  }
  row_ids <- rownames(matrix_x)
  col_ids <- colnames(matrix_x)
  if (is.null(row_ids) && is.null(col_ids)) {
    row_ids <- col_ids <- as.character(seq_len(nrow(matrix_x)))
  } else if (is.null(row_ids) || is.null(col_ids) || !identical(row_ids, col_ids) ||
             anyNA(row_ids) || any(!nzchar(row_ids)) || anyDuplicated(row_ids)) {
    stop("Distance rows and columns must have identical, unique sequence identifiers.",
         call. = FALSE)
  }
  rownames(matrix_x) <- row_ids
  colnames(matrix_x) <- col_ids
  tolerance <- sqrt(.Machine$double.eps)
  if (max(abs(matrix_x - t(matrix_x))) > tolerance) {
    stop("The distance matrix must be symmetric.", call. = FALSE)
  }
  if (max(abs(diag(matrix_x))) > tolerance) {
    stop("The distance-matrix diagonal must be zero.", call. = FALSE)
  }
  matrix_x
}

.sequence_adv_seed <- function(seed, offset = 0L) {
  .sequence_adv_scalar_number(seed, "seed", lower = 0, integer = TRUE)
  .sequence_adv_scalar_number(offset, "offset", lower = 0, integer = TRUE)
  modulus <- as.double(.Machine$integer.max)
  as.integer((as.double(seed) + as.double(offset)) %% modulus)
}

.sequence_adv_with_seed <- function(seed, code) {
  seed <- .sequence_adv_seed(seed)
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) {
    old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  }
  on.exit({
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(as.integer(seed))
  force(code)
}

.sequence_adv_silhouette <- function(assignments, distance_matrix) {
  ids <- names(assignments)
  if (is.null(ids)) ids <- rownames(distance_matrix)
  assignments <- assignments[ids]
  out <- numeric(length(ids))
  names(out) <- ids
  clusters <- sort(unique(assignments))
  for (i in seq_along(ids)) {
    own <- assignments[i]
    same <- which(assignments == own)
    same <- setdiff(same, i)
    if (length(same) == 0L) {
      out[i] <- 0
      next
    }
    a <- mean(distance_matrix[i, same])
    other_means <- vapply(setdiff(clusters, own), function(k) {
      mean(distance_matrix[i, assignments == k])
    }, numeric(1))
    b <- if (length(other_means) == 0L) 0 else min(other_means)
    out[i] <- if (max(a, b) == 0) 0 else (b - a) / max(a, b)
  }
  out
}

.sequence_adv_row_normalise <- function(x, pseudocount = 0) {
  x <- x + pseudocount
  totals <- rowSums(x)
  zero <- totals <= 0 | !is.finite(totals)
  if (any(zero)) x[zero, ] <- 1
  x / rowSums(x)
}

.sequence_adv_vector_normalise <- function(x, pseudocount = 0) {
  x <- x + pseudocount
  total <- sum(x)
  if (!is.finite(total) || total <= 0) x[] <- 1
  x / sum(x)
}

.sequence_adv_forward_backward <- function(obs, initial, transition, emission) {
  n_states <- length(initial)
  n_time <- length(obs)
  alpha <- matrix(0, nrow = n_time, ncol = n_states)
  scales <- numeric(n_time)
  alpha[1L, ] <- initial * emission[, obs[1L]]
  scales[1L] <- sum(alpha[1L, ])
  if (!is.finite(scales[1L]) || scales[1L] <= 0) scales[1L] <- .Machine$double.xmin
  alpha[1L, ] <- alpha[1L, ] / scales[1L]
  if (n_time > 1L) {
    for (t in 2:n_time) {
      alpha[t, ] <- as.numeric(alpha[t - 1L, ] %*% transition) * emission[, obs[t]]
      scales[t] <- sum(alpha[t, ])
      if (!is.finite(scales[t]) || scales[t] <= 0) scales[t] <- .Machine$double.xmin
      alpha[t, ] <- alpha[t, ] / scales[t]
    }
  }
  beta <- matrix(1, nrow = n_time, ncol = n_states)
  if (n_time > 1L) {
    for (t in seq.int(n_time - 1L, 1L)) {
      beta[t, ] <- transition %*% (emission[, obs[t + 1L]] * beta[t + 1L, ])
      beta[t, ] <- beta[t, ] / scales[t + 1L]
    }
  }
  gamma <- alpha * beta
  gamma_totals <- rowSums(gamma)
  invalid_gamma <- !is.finite(gamma_totals) | gamma_totals <= 0
  if (any(invalid_gamma)) {
    gamma[invalid_gamma, ] <- 1 / n_states
    gamma_totals[invalid_gamma] <- 1
  }
  gamma <- gamma / gamma_totals
  xi <- array(0, dim = c(max(n_time - 1L, 0L), n_states, n_states))
  if (n_time > 1L) {
    for (t in seq_len(n_time - 1L)) {
      current <- outer(alpha[t, ], emission[, obs[t + 1L]] * beta[t + 1L, ]) * transition
      total <- sum(current)
      if (total > 0) current <- current / total
      xi[t, , ] <- current
    }
  }
  list(alpha = alpha, beta = beta, gamma = gamma, xi = xi,
       log_likelihood = sum(log(scales)))
}

.sequence_adv_viterbi <- function(obs, initial, transition, emission) {
  n_states <- length(initial)
  n_time <- length(obs)
  log_initial <- log(pmax(initial, .Machine$double.xmin))
  log_transition <- log(pmax(transition, .Machine$double.xmin))
  log_emission <- log(pmax(emission, .Machine$double.xmin))
  delta <- matrix(-Inf, nrow = n_time, ncol = n_states)
  psi <- matrix(0L, nrow = n_time, ncol = n_states)
  delta[1L, ] <- log_initial + log_emission[, obs[1L]]
  if (n_time > 1L) {
    for (t in 2:n_time) {
      for (j in seq_len(n_states)) {
        candidates <- delta[t - 1L, ] + log_transition[, j]
        psi[t, j] <- which.max(candidates)
        delta[t, j] <- max(candidates) + log_emission[j, obs[t]]
      }
    }
  }
  path <- integer(n_time)
  path[n_time] <- which.max(delta[n_time, ])
  if (n_time > 1L) {
    for (t in seq.int(n_time - 1L, 1L)) path[t] <- psi[t + 1L, path[t + 1L]]
  }
  list(path = path, log_probability = max(delta[n_time, ]))
}

.sequence_adv_require <- function(package, purpose) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop("Optional package `", package, "` is required to ", purpose, ".",
         call. = FALSE)
  }
  invisible(TRUE)
}

.sequence_adv_zero_column_frame <- function(n = 0L) {
  data.frame(
    .gp3_adv_row = seq_len(n),
    stringsAsFactors = FALSE
  )[, FALSE, drop = FALSE]
}
