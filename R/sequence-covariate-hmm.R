.sequence_ext_covariate_hmm_input <- function(
  data,
  sequence_id_col,
  order_col,
  state_col,
  initial_covariate_cols,
  transition_covariate_cols,
  symbol_levels = NULL,
  initial_center = NULL,
  initial_scale = NULL,
  transition_center = NULL,
  transition_scale = NULL
) {
  all_covariates <- unique(c(initial_covariate_cols, transition_covariate_cols))
  if (is.list(data) && !is.data.frame(data) && !is.null(data$data)) data <- data$data
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  missing <- setdiff(all_covariates, names(data))
  if (length(missing) > 0L) {
    stop("Missing covariate columns: ", paste(missing, collapse = ", "), ".",
         call. = FALSE)
  }
  x <- .sequence_adv_data(
    data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    missing_state_policy = "error"
  )
  working <- x$data
  observed <- x$state_levels
  if (is.null(symbol_levels)) symbol_levels <- observed
  symbol_levels <- as.character(symbol_levels)
  if (length(symbol_levels) < 1L || anyNA(symbol_levels) ||
      any(!nzchar(trimws(symbol_levels))) || anyDuplicated(symbol_levels)) {
    stop("`symbol_levels` must contain unique non-missing symbols.", call. = FALSE)
  }
  missing_symbols <- setdiff(observed, symbol_levels)
  if (length(missing_symbols) > 0L) {
    stop("`symbol_levels` does not cover observed symbols: ",
         paste(missing_symbols, collapse = ", "), ".", call. = FALSE)
  }
  split_rows <- split(seq_len(nrow(working)),
                      factor(as.character(working[[sequence_id_col]]),
                             levels = x$sequence_ids), drop = TRUE)
  for (column in initial_covariate_cols) {
    inconsistent <- vapply(split_rows, function(rows) {
      length(unique(working[[column]][rows])) > 1L
    }, logical(1))
    if (any(inconsistent)) {
      stop("Initial covariate `", column,
           "` must remain constant within each sequence.", call. = FALSE)
    }
  }
  initial_data <- working[vapply(split_rows, function(rows) rows[1L], integer(1)),
                          , drop = FALSE]
  initial_design <- .sequence_ext_numeric_matrix(
    initial_data, initial_covariate_cols,
    center = initial_center, scale = initial_scale
  )
  transition_source_rows <- unlist(lapply(split_rows, function(rows) {
    if (length(rows) < 2L) integer() else rows[-length(rows)]
  }), use.names = FALSE)
  if (length(transition_source_rows) == 0L) {
    stop("At least one transition is required.", call. = FALSE)
  }
  transition_design_all <- .sequence_ext_numeric_matrix(
    working[transition_source_rows, , drop = FALSE],
    transition_covariate_cols,
    center = transition_center, scale = transition_scale
  )
  transition_design <- vector("list", length(split_rows))
  observations <- vector("list", length(split_rows))
  orders <- vector("list", length(split_rows))
  cursor <- 1L
  for (i in seq_along(split_rows)) {
    rows <- split_rows[[i]]
    observations[[i]] <- match(as.character(working[[state_col]][rows]), symbol_levels)
    orders[[i]] <- working[[order_col]][rows]
    n_transition <- max(length(rows) - 1L, 0L)
    if (n_transition > 0L) {
      transition_design[[i]] <- transition_design_all$matrix[
        seq.int(cursor, cursor + n_transition - 1L), , drop = FALSE
      ]
      cursor <- cursor + n_transition
    } else {
      transition_design[[i]] <- matrix(
        numeric(), nrow = 0L, ncol = ncol(transition_design_all$matrix),
        dimnames = list(NULL, colnames(transition_design_all$matrix))
      )
    }
  }
  names(observations) <- x$sequence_ids
  names(orders) <- x$sequence_ids
  names(transition_design) <- x$sequence_ids
  list(
    data = working,
    sequence_ids = x$sequence_ids,
    observations = observations,
    orders = orders,
    symbol_levels = symbol_levels,
    initial_design = initial_design$matrix,
    transition_design = transition_design,
    initial_center = initial_design$center,
    initial_scale = initial_design$scale,
    transition_center = transition_design_all$center,
    transition_scale = transition_design_all$scale,
    initial_covariate_cols = initial_covariate_cols,
    transition_covariate_cols = transition_covariate_cols,
    columns = list(sequence_id = sequence_id_col, order = order_col,
                   state = state_col)
  )
}

.sequence_ext_covariate_parameters <- function(input, n_states, seed,
                                               emission_probs = NULL) {
  initial_p <- ncol(input$initial_design)
  transition_p <- ncol(input$transition_design[[1L]])
  generated <- .sequence_adv_with_seed(seed, {
    list(
      initial_coef = matrix(stats::rnorm(initial_p * n_states, sd = 0.02),
                            nrow = initial_p, ncol = n_states),
      transition_coef = lapply(seq_len(n_states), function(i) {
        matrix(stats::rnorm(transition_p * n_states, sd = 0.02),
               nrow = transition_p, ncol = n_states)
      }),
      emission = if (is.null(emission_probs)) {
        matrix(stats::rexp(n_states * length(input$symbol_levels)) + 0.1,
               nrow = n_states, ncol = length(input$symbol_levels))
      } else emission_probs
    )
  })
  generated$initial_coef[, n_states] <- 0
  generated$transition_coef <- lapply(generated$transition_coef, function(x) {
    x[, n_states] <- 0
    x
  })
  if (!is.matrix(generated$emission) ||
      !all(dim(generated$emission) == c(n_states, length(input$symbol_levels))) ||
      anyNA(generated$emission) || any(!is.finite(generated$emission)) ||
      any(generated$emission < 0)) {
    stop("Invalid `emission_probs`.", call. = FALSE)
  }
  list(
    initial_coef = generated$initial_coef,
    transition_coef = generated$transition_coef,
    emission = .sequence_adv_row_normalise(generated$emission)
  )
}

.sequence_ext_covariate_probabilities <- function(initial_x, transition_x,
                                                  parameters) {
  initial <- .sequence_ext_softmax(initial_x %*% parameters$initial_coef)
  n_time <- nrow(transition_x) + 1L
  n_states <- ncol(parameters$initial_coef)
  transition <- array(0, dim = c(max(n_time - 1L, 0L), n_states, n_states))
  if (n_time > 1L) {
    for (t in seq_len(n_time - 1L)) {
      for (origin in seq_len(n_states)) {
        transition[t, origin, ] <- .sequence_ext_softmax(
          transition_x[t, ] %*% parameters$transition_coef[[origin]]
        )
      }
    }
  }
  list(initial = initial, transition = transition)
}

#' Fit a covariate-dependent categorical hidden Markov model
#'
#' Fits a categorical HMM whose initial-state and transition probabilities may
#' depend on explicitly declared numeric covariates. Multinomial-logit
#' coefficients are estimated inside the EM algorithm with a small ridge
#' penalty. Emission probabilities remain time-homogeneous.
#'
#' @param data Long-format sequence data.
#' @param n_states Number of latent states.
#' @param initial_covariate_cols Numeric sequence-constant covariates for
#'   initial-state probabilities.
#' @param transition_covariate_cols Numeric row-level covariates for transition
#'   probabilities.
#' @param sequence_id_col,order_col,state_col Core sequence columns.
#' @param symbol_levels Optional observed-symbol order.
#' @param state_names Optional latent-state names.
#' @param emission_probs Optional starting emission matrix.
#' @param max_iter Maximum EM iterations.
#' @param inner_maxit Maximum BFGS iterations in each multinomial M-step.
#' @param tolerance Relative log-likelihood tolerance.
#' @param pseudocount Emission smoothing count.
#' @param ridge Non-negative coefficient penalty.
#' @param seed Reproducibility seed.
#' @param keep_posteriors Retain final posteriors.
#'
#' @return An object of class `gp3_covariate_sequence_hmm`.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(paste0("s", 1:8), each = 5L),
#'   sequence_order = rep(1:5, times = 8L),
#'   state = rep(c("A", "B", "C", "B", "A"), times = 8L),
#'   condition = rep(rep(c(0, 1), each = 4L), each = 5L),
#'   time_scaled = rep(seq(-1, 1, length.out = 5L), times = 8L)
#' )
#' fit_covariate_sequence_hmm(
#'   sequences, 2L,
#'   initial_covariate_cols = "condition",
#'   transition_covariate_cols = c("condition", "time_scaled"),
#'   max_iter = 3L, inner_maxit = 10L, seed = 1L
#' )
#' @export
fit_covariate_sequence_hmm <- function(
  data,
  n_states,
  initial_covariate_cols = NULL,
  transition_covariate_cols = NULL,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  symbol_levels = NULL,
  state_names = NULL,
  emission_probs = NULL,
  max_iter = 100L,
  inner_maxit = 100L,
  tolerance = 1e-6,
  pseudocount = 1e-6,
  ridge = 1e-6,
  seed = 1L,
  keep_posteriors = FALSE
) {
  .sequence_adv_scalar_number(n_states, "n_states", lower = 2, integer = TRUE)
  .sequence_adv_scalar_number(max_iter, "max_iter", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(inner_maxit, "inner_maxit", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(tolerance, "tolerance", lower = 0)
  .sequence_adv_scalar_number(pseudocount, "pseudocount", lower = 0)
  .sequence_adv_scalar_number(ridge, "ridge", lower = 0)
  .sequence_adv_scalar_number(seed, "seed", lower = 0, integer = TRUE)
  .sequence_adv_scalar_logical(keep_posteriors, "keep_posteriors")
  initial_covariate_cols <- if (is.null(initial_covariate_cols)) character() else initial_covariate_cols
  transition_covariate_cols <- if (is.null(transition_covariate_cols)) character() else transition_covariate_cols
  if (!is.character(initial_covariate_cols) || anyNA(initial_covariate_cols) ||
      any(!nzchar(initial_covariate_cols)) || anyDuplicated(initial_covariate_cols)) {
    stop("Invalid `initial_covariate_cols`.", call. = FALSE)
  }
  if (!is.character(transition_covariate_cols) || anyNA(transition_covariate_cols) ||
      any(!nzchar(transition_covariate_cols)) || anyDuplicated(transition_covariate_cols)) {
    stop("Invalid `transition_covariate_cols`.", call. = FALSE)
  }
  input <- .sequence_ext_covariate_hmm_input(
    data, sequence_id_col, order_col, state_col,
    initial_covariate_cols, transition_covariate_cols, symbol_levels
  )
  if (is.null(state_names)) state_names <- paste0("latent_", seq_len(n_states))
  if (!is.character(state_names) || length(state_names) != n_states ||
      anyNA(state_names) || any(!nzchar(trimws(state_names))) ||
      anyDuplicated(state_names)) {
    stop("`state_names` must uniquely name all latent states.", call. = FALSE)
  }
  parameters <- .sequence_ext_covariate_parameters(input, n_states, seed,
                                                   emission_probs)
  colnames(parameters$initial_coef) <- state_names
  rownames(parameters$initial_coef) <- colnames(input$initial_design)
  for (origin in seq_len(n_states)) {
    colnames(parameters$transition_coef[[origin]]) <- state_names
    rownames(parameters$transition_coef[[origin]]) <-
      colnames(input$transition_design[[1L]])
  }
  history <- numeric(max_iter)
  converged <- FALSE
  previous <- -Inf
  optimizer_convergence <- integer()
  final_posteriors <- NULL
  for (iteration in seq_len(max_iter)) {
    n_sequences <- length(input$observations)
    initial_counts <- matrix(0, nrow = n_sequences, ncol = n_states,
                             dimnames = list(input$sequence_ids, state_names))
    transition_x <- do.call(rbind, input$transition_design)
    transition_counts <- lapply(seq_len(n_states), function(origin) {
      matrix(0, nrow = nrow(transition_x), ncol = n_states,
             dimnames = list(NULL, state_names))
    })
    emission_count <- matrix(pseudocount, nrow = n_states,
                             ncol = length(input$symbol_levels))
    sequence_loglik <- numeric(n_sequences)
    posterior_current <- vector("list", n_sequences)
    cursor <- 1L
    for (s in seq_len(n_sequences)) {
      obs <- input$observations[[s]]
      probabilities <- .sequence_ext_covariate_probabilities(
        input$initial_design[s, ], input$transition_design[[s]], parameters
      )
      emission_likelihood <- t(parameters$emission[, obs, drop = FALSE])
      fb <- .sequence_ext_forward_backward(
        emission_likelihood, probabilities$initial, probabilities$transition
      )
      initial_counts[s, ] <- fb$gamma[1L, ]
      n_transition <- max(length(obs) - 1L, 0L)
      if (n_transition > 0L) {
        rows <- seq.int(cursor, cursor + n_transition - 1L)
        for (origin in seq_len(n_states)) {
          current_xi <- fb$xi[, origin, , drop = FALSE]
          dim(current_xi) <- c(n_transition, n_states)
          transition_counts[[origin]][rows, ] <- current_xi
        }
        cursor <- cursor + n_transition
      }
      for (t in seq_along(obs)) {
        emission_count[, obs[t]] <- emission_count[, obs[t]] + fb$gamma[t, ]
      }
      sequence_loglik[s] <- fb$log_likelihood
      posterior_current[[s]] <- fb
    }
    current <- sum(sequence_loglik)
    history[iteration] <- current
    initial_fit <- .sequence_ext_fit_softmax(
      input$initial_design, initial_counts,
      start = parameters$initial_coef, ridge = ridge, maxit = inner_maxit
    )
    parameters$initial_coef <- initial_fit$coefficients
    transition_fits <- vector("list", n_states)
    for (origin in seq_len(n_states)) {
      transition_fits[[origin]] <- .sequence_ext_fit_softmax(
        transition_x, transition_counts[[origin]],
        start = parameters$transition_coef[[origin]],
        ridge = ridge, maxit = inner_maxit
      )
      parameters$transition_coef[[origin]] <- transition_fits[[origin]]$coefficients
    }
    optimizer_convergence <- c(
      initial_fit$convergence,
      vapply(transition_fits, function(x) x$convergence, integer(1))
    )
    parameters$emission <- .sequence_adv_row_normalise(emission_count)
    final_posteriors <- posterior_current
    if (iteration > 1L) {
      relative <- abs(current - previous) / max(1, abs(previous))
      if (relative <= tolerance) {
        converged <- TRUE
        history <- history[seq_len(iteration)]
        break
      }
    }
    previous <- current
    if (iteration == max_iter) history <- history[seq_len(iteration)]
  }
  final_loglik <- numeric(length(input$observations))
  final_posteriors <- vector("list", length(input$observations))
  for (s in seq_along(input$observations)) {
    probabilities <- .sequence_ext_covariate_probabilities(
      input$initial_design[s, ], input$transition_design[[s]], parameters
    )
    emission_likelihood <- t(parameters$emission[, input$observations[[s]], drop = FALSE])
    fb <- .sequence_ext_forward_backward(
      emission_likelihood, probabilities$initial, probabilities$transition
    )
    final_loglik[s] <- fb$log_likelihood
    final_posteriors[[s]] <- fb
  }
  log_likelihood <- sum(final_loglik)
  history[length(history)] <- log_likelihood
  dimnames(parameters$emission) <- list(state_names, input$symbol_levels)
  n_parameters <- ncol(input$initial_design) * (n_states - 1L) +
    n_states * ncol(input$transition_design[[1L]]) * (n_states - 1L) +
    n_states * (length(input$symbol_levels) - 1L)
  n_observations <- sum(lengths(input$observations))
  result <- list(
    initial_coefficients = parameters$initial_coef,
    transition_coefficients = stats::setNames(parameters$transition_coef,
                                               state_names),
    emission_probs = parameters$emission,
    state_names = state_names,
    symbol_names = input$symbol_levels,
    sequence_ids = input$sequence_ids,
    sequence_log_likelihoods = stats::setNames(final_loglik, input$sequence_ids),
    log_likelihood = log_likelihood,
    iterations = length(history),
    converged = converged,
    optimizer_convergence = optimizer_convergence,
    tolerance = tolerance,
    pseudocount = pseudocount,
    ridge = ridge,
    log_likelihood_history = history,
    n_parameters = as.integer(n_parameters),
    n_observations = as.integer(n_observations),
    aic = -2 * log_likelihood + 2 * n_parameters,
    bic = -2 * log_likelihood + log(max(1, n_observations)) * n_parameters,
    seed = as.integer(seed),
    initial_covariate_cols = input$initial_covariate_cols,
    transition_covariate_cols = input$transition_covariate_cols,
    initial_center = input$initial_center,
    initial_scale = input$initial_scale,
    transition_center = input$transition_center,
    transition_scale = input$transition_scale,
    training_observations = input$observations,
    training_orders = input$orders,
    training_initial_design = input$initial_design,
    training_transition_design = input$transition_design,
    training_data = input$data,
    columns = input$columns,
    posteriors = if (keep_posteriors) final_posteriors else NULL,
    call = match.call()
  )
  class(result) <- c("gp3_covariate_sequence_hmm", "list")
  result
}

#' Predict covariate-dependent transition probabilities
#'
#' @param model A fitted covariate HMM.
#' @param newdata Data frame containing transition covariates.
#'
#' @return A long data frame with one row per input row, origin state, and
#'   destination state.
#' @examples
#' # See `fit_covariate_sequence_hmm()`.
#' @export
predict_covariate_transition_probabilities <- function(model, newdata) {
  if (!inherits(model, "gp3_covariate_sequence_hmm")) {
    stop("`model` must be created by `fit_covariate_sequence_hmm()`.",
         call. = FALSE)
  }
  if (!is.data.frame(newdata) || nrow(newdata) < 1L) {
    stop("`newdata` must be a non-empty data frame.", call. = FALSE)
  }
  design <- .sequence_ext_numeric_matrix(
    newdata,
    model$transition_covariate_cols,
    center = model$transition_center,
    scale = model$transition_scale
  )$matrix
  rows <- list()
  h <- 0L
  for (r in seq_len(nrow(design))) {
    for (origin in seq_along(model$state_names)) {
      probabilities <- .sequence_ext_softmax(
        design[r, ] %*% model$transition_coefficients[[origin]]
      )
      for (destination in seq_along(model$state_names)) {
        h <- h + 1L
        rows[[h]] <- data.frame(
          row = r,
          from_state = model$state_names[origin],
          to_state = model$state_names[destination],
          probability = probabilities[destination],
          stringsAsFactors = FALSE
        )
      }
    }
  }
  do.call(rbind, rows)
}

#' Decode states from a covariate-dependent HMM
#'
#' @param model A fitted covariate HMM.
#' @param data Optional new data. Training data are used when omitted.
#' @param sequence_id_col,order_col,state_col Core columns for new data.
#' @param method `"viterbi"` or `"posterior"`.
#'
#' @return A long decoded-state data frame.
#' @examples
#' # See `fit_covariate_sequence_hmm()`.
#' @export
decode_covariate_sequence_states <- function(
  model,
  data = NULL,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  method = c("viterbi", "posterior")
) {
  if (!inherits(model, "gp3_covariate_sequence_hmm")) {
    stop("`model` must be created by `fit_covariate_sequence_hmm()`.",
         call. = FALSE)
  }
  method <- match.arg(method)
  if (is.null(data)) {
    input <- list(
      sequence_ids = model$sequence_ids,
      observations = model$training_observations,
      orders = model$training_orders,
      initial_design = model$training_initial_design,
      transition_design = model$training_transition_design
    )
  } else {
    input <- .sequence_ext_covariate_hmm_input(
      data, sequence_id_col, order_col, state_col,
      model$initial_covariate_cols, model$transition_covariate_cols,
      symbol_levels = model$symbol_names,
      initial_center = model$initial_center,
      initial_scale = model$initial_scale,
      transition_center = model$transition_center,
      transition_scale = model$transition_scale
    )
  }
  rows <- list()
  h <- 0L
  parameters <- list(
    initial_coef = model$initial_coefficients,
    transition_coef = model$transition_coefficients,
    emission = model$emission_probs
  )
  for (s in seq_along(input$sequence_ids)) {
    probabilities <- .sequence_ext_covariate_probabilities(
      input$initial_design[s, ], input$transition_design[[s]], parameters
    )
    emission_likelihood <- t(model$emission_probs[, input$observations[[s]], drop = FALSE])
    fb <- .sequence_ext_forward_backward(
      emission_likelihood, probabilities$initial, probabilities$transition
    )
    decoded <- if (method == "viterbi") {
      .sequence_ext_viterbi(
        emission_likelihood, probabilities$initial, probabilities$transition
      )$path
    } else max.col(fb$gamma, ties.method = "first")
    posterior_probability <- fb$gamma[cbind(seq_along(decoded), decoded)]
    for (t in seq_along(decoded)) {
      h <- h + 1L
      rows[[h]] <- data.frame(
        sequence_id = input$sequence_ids[s],
        sequence_order = input$orders[[s]][t],
        observed_state = model$symbol_names[input$observations[[s]][t]],
        latent_state = model$state_names[decoded[t]],
        posterior_probability = posterior_probability[t],
        decoding_method = method,
        stringsAsFactors = FALSE
      )
    }
  }
  result <- do.call(rbind, rows)
  row.names(result) <- NULL
  result
}

#' Summarise a covariate-dependent HMM
#'
#' @param model A fitted covariate HMM.
#'
#' @return A list of fit, coefficient, and emission summaries.
#' @examples
#' # See `fit_covariate_sequence_hmm()`.
#' @export
summarise_covariate_sequence_hmm <- function(model) {
  if (!inherits(model, "gp3_covariate_sequence_hmm")) {
    stop("`model` must be created by `fit_covariate_sequence_hmm()`.",
         call. = FALSE)
  }
  transition <- do.call(rbind, lapply(seq_along(model$transition_coefficients),
                                     function(origin) {
    current <- model$transition_coefficients[[origin]]
    data.frame(
      from_state = model$state_names[origin],
      covariate = rep(rownames(current), times = ncol(current)),
      to_state = rep(colnames(current), each = nrow(current)),
      coefficient = as.numeric(current),
      stringsAsFactors = FALSE
    )
  }))
  initial <- data.frame(
    covariate = rep(rownames(model$initial_coefficients),
                    times = ncol(model$initial_coefficients)),
    latent_state = rep(colnames(model$initial_coefficients),
                       each = nrow(model$initial_coefficients)),
    coefficient = as.numeric(model$initial_coefficients),
    stringsAsFactors = FALSE
  )
  list(
    fit = data.frame(
      n_states = length(model$state_names),
      n_sequences = length(model$sequence_ids),
      n_observations = model$n_observations,
      log_likelihood = model$log_likelihood,
      aic = model$aic,
      bic = model$bic,
      iterations = model$iterations,
      converged = model$converged,
      optimizers_converged = all(model$optimizer_convergence == 0L),
      ridge = model$ridge,
      stringsAsFactors = FALSE
    ),
    initial_coefficients = initial,
    transition_coefficients = transition,
    emission = as.data.frame(as.table(model$emission_probs),
                              stringsAsFactors = FALSE)
  )
}
