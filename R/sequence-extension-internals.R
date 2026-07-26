# Internal helpers for the post-0.2.0 advanced extension roadmap.

.sequence_ext_entropy <- function(probabilities, base = 2) {
  probabilities <- probabilities[is.finite(probabilities) & probabilities > 0]
  if (length(probabilities) == 0L) return(0)
  -sum(probabilities * (log(probabilities) / log(base)))
}

.sequence_ext_softmax <- function(eta) {
  eta <- as.numeric(eta)
  eta <- eta - max(eta)
  value <- exp(eta)
  value / sum(value)
}

.sequence_ext_numeric_matrix <- function(data, columns, center = NULL, scale = NULL) {
  columns <- .sequence_adv_match_cols(data, columns, "covariate columns")
  if (length(columns) == 0L) {
    x <- matrix(1, nrow = nrow(data), ncol = 1L,
                dimnames = list(NULL, "(Intercept)"))
    return(list(matrix = x, center = numeric(), scale = numeric(), columns = character()))
  }
  invalid <- vapply(data[columns], function(x) {
    !is.numeric(x) || anyNA(x) || any(!is.finite(x))
  }, logical(1))
  if (any(invalid)) {
    stop("Covariates must be finite, non-missing numeric columns: ",
         paste(columns[invalid], collapse = ", "), ".", call. = FALSE)
  }
  raw <- as.matrix(data[columns])
  storage.mode(raw) <- "double"
  if (is.null(center)) center <- colMeans(raw)
  if (is.null(scale)) {
    scale <- apply(raw, 2L, stats::sd)
    scale[!is.finite(scale) | scale <= 0] <- 1
  }
  if (!identical(names(center), columns)) names(center) <- columns
  if (!identical(names(scale), columns)) names(scale) <- columns
  standardized <- sweep(raw, 2L, center[columns], "-")
  standardized <- sweep(standardized, 2L, scale[columns], "/")
  x <- cbind("(Intercept)" = 1, standardized)
  list(matrix = x, center = center, scale = scale, columns = columns)
}

.sequence_ext_fit_softmax <- function(x, counts, start = NULL, ridge = 1e-6,
                                      maxit = 100L) {
  if (!is.matrix(x) || !is.numeric(x) || anyNA(x) || any(!is.finite(x))) {
    stop("`x` must be a finite numeric matrix.", call. = FALSE)
  }
  if (!is.matrix(counts) || !is.numeric(counts) || nrow(counts) != nrow(x) ||
      ncol(counts) < 2L || anyNA(counts) || any(!is.finite(counts)) ||
      any(counts < 0)) {
    stop("`counts` must be a non-negative finite matrix aligned with `x`.",
         call. = FALSE)
  }
  .sequence_adv_scalar_number(ridge, "ridge", lower = 0)
  .sequence_adv_scalar_number(maxit, "maxit", lower = 1, integer = TRUE)
  p <- ncol(x)
  k <- ncol(counts)
  if (is.null(start)) {
    start <- matrix(0, nrow = p, ncol = k)
  }
  if (!is.matrix(start) || !all(dim(start) == c(p, k))) {
    stop("`start` has incompatible dimensions.", call. = FALSE)
  }
  theta0 <- as.numeric(start[, seq_len(k - 1L), drop = FALSE])
  objective <- function(theta) {
    beta <- cbind(matrix(theta, nrow = p, ncol = k - 1L), 0)
    eta <- x %*% beta
    row_max <- apply(eta, 1L, max)
    exp_eta <- exp(eta - row_max)
    probabilities <- exp_eta / rowSums(exp_eta)
    probabilities <- pmax(probabilities, .Machine$double.xmin)
    value <- -sum(counts * log(probabilities)) + 0.5 * ridge * sum(theta^2)
    totals <- rowSums(counts)
    residual <- probabilities * totals - counts
    gradient <- t(x) %*% residual[, seq_len(k - 1L), drop = FALSE]
    gradient <- as.numeric(gradient) + ridge * theta
    attr(value, "gradient") <- gradient
    value
  }
  fit <- stats::optim(
    par = theta0,
    fn = function(theta) objective(theta),
    gr = function(theta) attr(objective(theta), "gradient"),
    method = "BFGS",
    control = list(maxit = as.integer(maxit), reltol = 1e-9)
  )
  beta <- cbind(matrix(fit$par, nrow = p, ncol = k - 1L), 0)
  rownames(beta) <- colnames(x)
  colnames(beta) <- colnames(counts)
  list(coefficients = beta, convergence = fit$convergence,
       value = fit$value, counts = fit$counts)
}

.sequence_ext_forward_backward <- function(emission_likelihood, initial,
                                           transition) {
  if (!is.matrix(emission_likelihood) || !is.numeric(emission_likelihood) ||
      nrow(emission_likelihood) < 1L || ncol(emission_likelihood) < 1L ||
      anyNA(emission_likelihood) || any(!is.finite(emission_likelihood)) ||
      any(emission_likelihood < 0)) {
    stop("Invalid emission-likelihood matrix.", call. = FALSE)
  }
  n_time <- nrow(emission_likelihood)
  n_states <- ncol(emission_likelihood)
  if (!is.numeric(initial) || length(initial) != n_states || any(initial < 0)) {
    stop("Invalid initial probabilities.", call. = FALSE)
  }
  transition_at <- function(t) {
    if (is.matrix(transition)) return(transition)
    transition[t, , , drop = TRUE]
  }
  if (is.matrix(transition)) {
    if (!all(dim(transition) == c(n_states, n_states))) {
      stop("Invalid transition matrix.", call. = FALSE)
    }
  } else if (!is.array(transition) || length(dim(transition)) != 3L ||
             !all(dim(transition) == c(max(n_time - 1L, 0L), n_states, n_states))) {
    stop("Invalid time-varying transition array.", call. = FALSE)
  }
  alpha <- matrix(0, nrow = n_time, ncol = n_states)
  scales <- numeric(n_time)
  alpha[1L, ] <- initial * emission_likelihood[1L, ]
  scales[1L] <- sum(alpha[1L, ])
  if (!is.finite(scales[1L]) || scales[1L] <= 0) scales[1L] <- .Machine$double.xmin
  alpha[1L, ] <- alpha[1L, ] / scales[1L]
  if (n_time > 1L) {
    for (t in 2:n_time) {
      current_transition <- transition_at(t - 1L)
      alpha[t, ] <- as.numeric(alpha[t - 1L, ] %*% current_transition) *
        emission_likelihood[t, ]
      scales[t] <- sum(alpha[t, ])
      if (!is.finite(scales[t]) || scales[t] <= 0) scales[t] <- .Machine$double.xmin
      alpha[t, ] <- alpha[t, ] / scales[t]
    }
  }
  beta <- matrix(1, nrow = n_time, ncol = n_states)
  if (n_time > 1L) {
    for (t in seq.int(n_time - 1L, 1L)) {
      current_transition <- transition_at(t)
      beta[t, ] <- current_transition %*%
        (emission_likelihood[t + 1L, ] * beta[t + 1L, ])
      beta[t, ] <- beta[t, ] / scales[t + 1L]
    }
  }
  gamma <- alpha * beta
  gamma_total <- rowSums(gamma)
  invalid <- !is.finite(gamma_total) | gamma_total <= 0
  if (any(invalid)) {
    gamma[invalid, ] <- 1 / n_states
    gamma_total[invalid] <- 1
  }
  gamma <- gamma / gamma_total
  xi <- array(0, dim = c(max(n_time - 1L, 0L), n_states, n_states))
  if (n_time > 1L) {
    for (t in seq_len(n_time - 1L)) {
      current_transition <- transition_at(t)
      current <- outer(alpha[t, ],
                       emission_likelihood[t + 1L, ] * beta[t + 1L, ]) *
        current_transition
      total <- sum(current)
      if (is.finite(total) && total > 0) current <- current / total
      xi[t, , ] <- current
    }
  }
  list(alpha = alpha, beta = beta, gamma = gamma, xi = xi,
       log_likelihood = sum(log(scales)))
}

.sequence_ext_viterbi <- function(emission_likelihood, initial, transition) {
  n_time <- nrow(emission_likelihood)
  n_states <- ncol(emission_likelihood)
  transition_at <- function(t) {
    if (is.matrix(transition)) transition else transition[t, , , drop = TRUE]
  }
  delta <- matrix(-Inf, nrow = n_time, ncol = n_states)
  psi <- matrix(0L, nrow = n_time, ncol = n_states)
  delta[1L, ] <- log(pmax(initial, .Machine$double.xmin)) +
    log(pmax(emission_likelihood[1L, ], .Machine$double.xmin))
  if (n_time > 1L) {
    for (t in 2:n_time) {
      current_transition <- transition_at(t - 1L)
      for (j in seq_len(n_states)) {
        candidates <- delta[t - 1L, ] +
          log(pmax(current_transition[, j], .Machine$double.xmin))
        psi[t, j] <- which.max(candidates)
        delta[t, j] <- max(candidates) +
          log(pmax(emission_likelihood[t, j], .Machine$double.xmin))
      }
    }
  }
  path <- integer(n_time)
  path[n_time] <- which.max(delta[n_time, ])
  if (n_time > 1L) {
    for (t in seq.int(n_time - 1L, 1L)) {
      path[t] <- psi[t + 1L, path[t + 1L]]
    }
  }
  list(path = path, log_probability = max(delta[n_time, ]))
}

.sequence_ext_subsequence_present <- function(sequence, pattern) {
  sequence <- as.character(sequence)
  pattern <- as.character(pattern)
  if (length(pattern) == 0L) return(TRUE)
  position <- 1L
  for (value in sequence) {
    if (identical(value, pattern[position])) position <- position + 1L
    if (position > length(pattern)) return(TRUE)
  }
  FALSE
}

.sequence_ext_base_colors <- function(n, palette = "Dark 3") {
  if (n < 1L) return(character())
  grDevices::hcl.colors(n, palette = palette)
}
