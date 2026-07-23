.sequence_adv_hmm_input <- function(data, sequence_id_col, order_col, state_col,
                                    symbol_levels = NULL) {
  x <- .sequence_adv_data(data, sequence_id_col, order_col, state_col,
                          missing_state_policy = "error")
  symbols <- if (is.null(symbol_levels)) x$state_levels else as.character(symbol_levels)
  if (!is.character(symbols) || length(symbols) < 1L || anyNA(symbols) ||
      any(!nzchar(trimws(symbols))) || anyDuplicated(symbols)) {
    stop("`symbol_levels` must contain unique, non-missing, non-blank symbols.",
         call. = FALSE)
  }
  missing <- setdiff(x$state_levels, symbols)
  if (length(missing) > 0L) {
    stop("`symbol_levels` does not cover observed symbols: ",
         paste(missing, collapse = ", "), ".", call. = FALSE)
  }
  encoded <- lapply(x$sequences, function(z) match(z, symbols))
  list(source = x, symbols = symbols, encoded = encoded)
}

.sequence_adv_hmm_initialise <- function(n_states, n_symbols, seed,
                                         initial_probs = NULL,
                                         transition_probs = NULL,
                                         emission_probs = NULL) {
  generated <- .sequence_adv_with_seed(seed, {
    list(
      initial = if (is.null(initial_probs)) stats::rexp(n_states) + 0.1 else initial_probs,
      transition = if (is.null(transition_probs)) {
        matrix(stats::rexp(n_states^2) + 0.1, n_states, n_states)
      } else {
        transition_probs
      },
      emission = if (is.null(emission_probs)) {
        matrix(stats::rexp(n_states * n_symbols) + 0.1, n_states, n_symbols)
      } else {
        emission_probs
      }
    )
  })
  initial_probs <- generated$initial
  transition_probs <- generated$transition
  emission_probs <- generated$emission
  if (!is.numeric(initial_probs) || length(initial_probs) != n_states ||
      any(!is.finite(initial_probs)) || any(initial_probs < 0)) {
    stop("Invalid `initial_probs`.", call. = FALSE)
  }
  if (!is.matrix(transition_probs) || !is.numeric(transition_probs) ||
      !all(dim(transition_probs) == c(n_states, n_states)) ||
      any(!is.finite(transition_probs)) || any(transition_probs < 0)) {
    stop("Invalid `transition_probs`.", call. = FALSE)
  }
  if (!is.matrix(emission_probs) || !is.numeric(emission_probs) ||
      !all(dim(emission_probs) == c(n_states, n_symbols)) ||
      any(!is.finite(emission_probs)) || any(emission_probs < 0)) {
    stop("Invalid `emission_probs`.", call. = FALSE)
  }
  list(
    initial = .sequence_adv_vector_normalise(initial_probs),
    transition = .sequence_adv_row_normalise(transition_probs),
    emission = .sequence_adv_row_normalise(emission_probs)
  )
}

.sequence_adv_hmm_sufficient <- function(encoded, parameters, weights = NULL,
                                         pseudocount = 0) {
  n_states <- length(parameters$initial)
  n_symbols <- ncol(parameters$emission)
  if (is.null(weights)) weights <- rep(1, length(encoded))
  if (!is.numeric(weights) || length(weights) != length(encoded) ||
      any(!is.finite(weights)) || any(weights < 0)) {
    stop("`weights` must contain one finite non-negative value per sequence.",
         call. = FALSE)
  }
  if (!is.numeric(pseudocount) || length(pseudocount) != 1L ||
      !is.finite(pseudocount) || pseudocount < 0) {
    stop("`pseudocount` must be one finite non-negative number.", call. = FALSE)
  }
  initial_count <- rep(pseudocount, n_states)
  transition_count <- matrix(pseudocount, n_states, n_states)
  emission_count <- matrix(pseudocount, n_states, n_symbols)
  log_likelihoods <- numeric(length(encoded))
  posterior <- vector("list", length(encoded))
  for (s in seq_along(encoded)) {
    fb <- .sequence_adv_forward_backward(encoded[[s]], parameters$initial,
                                         parameters$transition, parameters$emission)
    w <- weights[s]
    initial_count <- initial_count + w * fb$gamma[1L, ]
    if (length(encoded[[s]]) > 1L) transition_count <- transition_count +
      w * apply(fb$xi, c(2L, 3L), sum)
    for (t in seq_along(encoded[[s]])) {
      emission_count[, encoded[[s]][t]] <- emission_count[, encoded[[s]][t]] +
        w * fb$gamma[t, ]
    }
    log_likelihoods[s] <- fb$log_likelihood
    posterior[[s]] <- fb
  }
  list(initial = initial_count, transition = transition_count, emission = emission_count,
       log_likelihoods = log_likelihoods, posterior = posterior)
}

#' Fit a categorical hidden Markov model
#'
#' Fits a finite-state, time-homogeneous categorical HMM by Baum-Welch EM.
#' Latent states are statistical model states only; they are not psychological,
#' diagnostic, or causal constructs.
#'
#' @param data Long-format sequence data.
#' @param n_states Number of latent states.
#' @param sequence_id_col,order_col,state_col Sequence columns.
#' @param symbol_levels Optional observed-symbol ordering.
#' @param state_names Optional latent-state names.
#' @param initial_probs,transition_probs,emission_probs Optional starting values.
#' @param max_iter Maximum EM iterations.
#' @param tolerance Relative log-likelihood tolerance.
#' @param pseudocount Non-negative smoothing count.
#' @param seed Reproducibility seed.
#' @param keep_posteriors Retain final forward-backward results.
#'
#' @return An object of class `gp3_sequence_hmm` containing fitted parameters,
#' log likelihood, convergence diagnostics, symbol coding, and optional
#' posteriors.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' fit_sequence_hmm(sequences, n_states = 2L, max_iter = 5L, seed = 1L)
#'
#' @export
fit_sequence_hmm <- function(
  data,
  n_states,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  symbol_levels = NULL,
  state_names = NULL,
  initial_probs = NULL,
  transition_probs = NULL,
  emission_probs = NULL,
  max_iter = 200L,
  tolerance = 1e-6,
  pseudocount = 1e-6,
  seed = 1L,
  keep_posteriors = FALSE
) {
  .sequence_adv_scalar_number(n_states, "n_states", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(max_iter, "max_iter", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(tolerance, "tolerance", lower = 0)
  .sequence_adv_scalar_number(pseudocount, "pseudocount", lower = 0)
  .sequence_adv_scalar_number(seed, "seed", lower = 0, integer = TRUE)
  .sequence_adv_scalar_logical(keep_posteriors, "keep_posteriors")
  input <- .sequence_adv_hmm_input(data, sequence_id_col, order_col, state_col,
                                   symbol_levels)
  n_symbols <- length(input$symbols)
  if (is.null(state_names)) state_names <- paste0("latent_", seq_len(n_states))
  if (!is.character(state_names) || length(state_names) != n_states || anyNA(state_names) ||
      any(!nzchar(trimws(state_names))) || anyDuplicated(state_names)) {
    stop("`state_names` must uniquely name all latent states.", call. = FALSE)
  }
  parameters <- .sequence_adv_hmm_initialise(n_states, n_symbols, seed,
                                             initial_probs, transition_probs,
                                             emission_probs)
  history <- numeric(max_iter)
  converged <- FALSE
  previous <- -Inf
  final_sufficient <- NULL
  for (iteration in seq_len(max_iter)) {
    sufficient <- .sequence_adv_hmm_sufficient(input$encoded, parameters,
                                                pseudocount = pseudocount)
    current <- sum(sufficient$log_likelihoods)
    history[iteration] <- current
    parameters$initial <- .sequence_adv_vector_normalise(sufficient$initial)
    parameters$transition <- .sequence_adv_row_normalise(sufficient$transition)
    parameters$emission <- .sequence_adv_row_normalise(sufficient$emission)
    final_sufficient <- sufficient
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
  final_sufficient <- .sequence_adv_hmm_sufficient(input$encoded, parameters,
                                                    pseudocount = 0)
  log_likelihood <- sum(final_sufficient$log_likelihoods)
  history[length(history)] <- log_likelihood
  dimnames(parameters$transition) <- list(state_names, state_names)
  dimnames(parameters$emission) <- list(state_names, input$symbols)
  names(parameters$initial) <- state_names
  n_parameters <- (n_states - 1L) + n_states * (n_states - 1L) +
    n_states * (n_symbols - 1L)
  n_observations <- sum(lengths(input$encoded))
  result <- list(
    initial_probs = parameters$initial,
    transition_probs = parameters$transition,
    emission_probs = parameters$emission,
    state_names = state_names,
    symbol_names = input$symbols,
    sequence_ids = input$source$sequence_ids,
    log_likelihood = log_likelihood,
    sequence_log_likelihoods = stats::setNames(final_sufficient$log_likelihoods,
                                        input$source$sequence_ids),
    iterations = length(history),
    converged = converged,
    tolerance = tolerance,
    pseudocount = pseudocount,
    log_likelihood_history = history,
    n_parameters = as.integer(n_parameters),
    n_observations = as.integer(n_observations),
    aic = -2 * log_likelihood + 2 * n_parameters,
    bic = -2 * log_likelihood + log(max(1, n_observations)) * n_parameters,
    seed = as.integer(seed),
    call = match.call(),
    posteriors = if (keep_posteriors) final_sufficient$posterior else NULL,
    training_sequences = input$source$sequences,
    training_orders = input$source$orders
  )
  class(result) <- c("gp3_sequence_hmm", "list")
  result
}

.sequence_adv_hmm_loglik <- function(encoded, parameters) {
  vapply(encoded, function(obs) {
    .sequence_adv_forward_backward(obs, parameters$initial,
                                   parameters$transition,
                                   parameters$emission)$log_likelihood
  }, numeric(1))
}

#' Fit a mixture of categorical hidden Markov models
#'
#' Fits sequence-level mixture components, each containing a categorical HMM.
#' Component membership is a statistical clustering device and should not be
#' interpreted as a substantive latent type without external validation.
#'
#' @param data Long-format sequence data.
#' @param n_components Number of mixture components.
#' @param n_states Number of hidden states per component; scalar or vector.
#' @param sequence_id_col,order_col,state_col Sequence columns.
#' @param symbol_levels Optional symbol ordering.
#' @param max_iter Maximum mixture-EM iterations.
#' @param inner_initial_iter Initial single-HMM iterations per component.
#' @param tolerance Relative log-likelihood tolerance.
#' @param pseudocount Smoothing count.
#' @param seed Reproducibility seed.
#'
#' @return An object of class `gp3_sequence_hmm_mixture`.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' fit_sequence_hmm_mixture(sequences, n_components = 2L, n_states = 2L,
#'                          max_iter = 5L, inner_initial_iter = 2L, seed = 1L)
#'
#' @export
fit_sequence_hmm_mixture <- function(
  data,
  n_components,
  n_states,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  symbol_levels = NULL,
  max_iter = 200L,
  inner_initial_iter = 20L,
  tolerance = 1e-6,
  pseudocount = 1e-6,
  seed = 1L
) {
  .sequence_adv_scalar_number(n_components, "n_components", lower = 2, integer = TRUE)
  if (length(n_states) == 1L) n_states <- rep(n_states, n_components)
  if (!is.numeric(n_states) || length(n_states) != n_components || anyNA(n_states) ||
      any(!is.finite(n_states)) || any(n_states < 1) ||
      any(n_states > .Machine$integer.max) || any(n_states != trunc(n_states))) {
    stop("`n_states` must be a positive integer scalar or one value per component.",
         call. = FALSE)
  }
  .sequence_adv_scalar_number(max_iter, "max_iter", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(inner_initial_iter, "inner_initial_iter", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(tolerance, "tolerance", lower = 0)
  .sequence_adv_scalar_number(pseudocount, "pseudocount", lower = 0)
  .sequence_adv_scalar_number(seed, "seed", lower = 0, integer = TRUE)
  input <- .sequence_adv_hmm_input(data, sequence_id_col, order_col, state_col,
                                   symbol_levels)
  n_sequences <- length(input$encoded)
  if (n_components > n_sequences) stop("More components than sequences were requested.", call. = FALSE)
  initial_responsibilities <- .sequence_adv_with_seed(seed, {
    raw <- matrix(
      stats::rexp(n_sequences * n_components) + 0.1,
      nrow = n_sequences,
      ncol = n_components
    )
    raw / rowSums(raw)
  })
  parameters <- vector("list", n_components)
  for (component in seq_len(n_components)) {
    parameters[[component]] <- .sequence_adv_hmm_initialise(
      n_states[component], length(input$symbols), .sequence_adv_seed(seed, component)
    )
    for (initial_iteration in seq_len(inner_initial_iter)) {
      sufficient <- .sequence_adv_hmm_sufficient(
        input$encoded,
        parameters[[component]],
        weights = initial_responsibilities[, component],
        pseudocount = pseudocount
      )
      parameters[[component]]$initial <- .sequence_adv_vector_normalise(sufficient$initial)
      parameters[[component]]$transition <- .sequence_adv_row_normalise(sufficient$transition)
      parameters[[component]]$emission <- .sequence_adv_row_normalise(sufficient$emission)
    }
  }
  mixture_weights <- .sequence_adv_vector_normalise(colMeans(initial_responsibilities))
  history <- numeric(max_iter)
  previous <- -Inf
  converged <- FALSE
  responsibilities <- initial_responsibilities
  component_loglik <- matrix(NA_real_, n_sequences, n_components)
  for (iteration in seq_len(max_iter)) {
    for (component in seq_len(n_components)) {
      component_loglik[, component] <- .sequence_adv_hmm_loglik(input$encoded,
                                                                 parameters[[component]])
    }
    log_joint <- sweep(component_loglik, 2L,
                       log(pmax(mixture_weights, .Machine$double.xmin)), "+")
    row_max <- apply(log_joint, 1L, max)
    stabilised <- exp(log_joint - row_max)
    row_total <- rowSums(stabilised)
    if (any(!is.finite(row_total) | row_total <= 0)) {
      stop("Mixture responsibilities could not be normalised.", call. = FALSE)
    }
    responsibilities <- stabilised / row_total
    current <- sum(row_max + log(row_total))
    history[iteration] <- current
    mixture_weights <- colMeans(responsibilities)
    mixture_weights <- .sequence_adv_vector_normalise(mixture_weights, pseudocount)
    for (component in seq_len(n_components)) {
      sufficient <- .sequence_adv_hmm_sufficient(
        input$encoded, parameters[[component]],
        weights = responsibilities[, component], pseudocount = pseudocount
      )
      parameters[[component]]$initial <- .sequence_adv_vector_normalise(sufficient$initial)
      parameters[[component]]$transition <- .sequence_adv_row_normalise(sufficient$transition)
      parameters[[component]]$emission <- .sequence_adv_row_normalise(sufficient$emission)
    }
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
  # Recompute component likelihoods and memberships under the final parameter
  # values. This avoids returning responsibilities from the pre-update E-step.
  for (component in seq_len(n_components)) {
    component_loglik[, component] <- .sequence_adv_hmm_loglik(
      input$encoded, parameters[[component]]
    )
  }
  final_log_joint <- sweep(
    component_loglik, 2L,
    log(pmax(mixture_weights, .Machine$double.xmin)), "+"
  )
  final_row_max <- apply(final_log_joint, 1L, max)
  final_stabilised <- exp(final_log_joint - final_row_max)
  final_row_total <- rowSums(final_stabilised)
  if (any(!is.finite(final_row_total) | final_row_total <= 0)) {
    stop("Final mixture responsibilities could not be normalised.", call. = FALSE)
  }
  responsibilities <- final_stabilised / final_row_total
  final_log_likelihood <- sum(final_row_max + log(final_row_total))
  history[length(history)] <- final_log_likelihood

  component_models <- lapply(seq_len(n_components), function(component) {
    state_names <- paste0("component_", component, "_latent_",
                          seq_len(n_states[component]))
    p <- parameters[[component]]
    names(p$initial) <- state_names
    dimnames(p$transition) <- list(state_names, state_names)
    dimnames(p$emission) <- list(state_names, input$symbols)
    list(initial_probs = p$initial, transition_probs = p$transition,
         emission_probs = p$emission, state_names = state_names,
         symbol_names = input$symbols)
  })
  hard <- max.col(responsibilities, ties.method = "first")
  n_parameters <- (n_components - 1L) + sum(vapply(seq_len(n_components), function(component) {
    k <- n_states[component]
    (k - 1L) + k * (k - 1L) + k * (length(input$symbols) - 1L)
  }, numeric(1)))
  n_observations <- sum(lengths(input$encoded))
  result <- list(
    mixture_weights = stats::setNames(mixture_weights, paste0("component_", seq_len(n_components))),
    components = component_models,
    responsibilities = data.frame(
      sequence_id = input$source$sequence_ids,
      responsibilities,
      assigned_component = hard,
      stringsAsFactors = FALSE,
      check.names = FALSE
    ),
    log_likelihood = final_log_likelihood,
    log_likelihood_history = history,
    iterations = length(history),
    converged = converged,
    tolerance = tolerance,
    pseudocount = pseudocount,
    inner_initial_iter = as.integer(inner_initial_iter),
    n_components = as.integer(n_components),
    n_states = as.integer(n_states),
    n_parameters = as.integer(n_parameters),
    n_observations = as.integer(n_observations),
    aic = -2 * final_log_likelihood + 2 * n_parameters,
    bic = -2 * final_log_likelihood +
      log(max(1, n_observations)) * n_parameters,
    symbol_names = input$symbols,
    sequence_ids = input$source$sequence_ids,
    seed = as.integer(seed),
    training_sequences = input$source$sequences,
    training_orders = input$source$orders,
    call = match.call()
  )
  names(result$responsibilities)[seq_len(n_components) + 1L] <-
    paste0("component_", seq_len(n_components))
  class(result) <- c("gp3_sequence_hmm_mixture", "list")
  result
}

#' Decode hidden states from a fitted HMM
#'
#' @param model A fitted single HMM or HMM mixture.
#' @param data Optional new long-format data. Training sequences are used when
#'   omitted.
#' @param sequence_id_col,order_col,state_col Sequence columns for new data.
#' @param method `"viterbi"` or `"posterior"`.
#' @param component Mixture component to decode. When omitted for a mixture,
#' each sequence uses its highest-responsibility component.
#'
#' @return A long data frame containing decoded latent states and posterior
#' probabilities where available.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' model <- fit_sequence_hmm(sequences, 2L, max_iter = 5L)
#' decode_sequence_states(model)
#'
#' @export
decode_sequence_states <- function(model, data = NULL,
                                   sequence_id_col = "sequence_id",
                                   order_col = "sequence_order",
                                   state_col = "state",
                                   method = c("viterbi", "posterior"),
                                   component = NULL) {
  method <- match.arg(method)
  is_single <- inherits(model, "gp3_sequence_hmm")
  is_mixture <- inherits(model, "gp3_sequence_hmm_mixture")
  if (!is_single && !is_mixture) stop("Unsupported HMM model object.", call. = FALSE)
  symbols <- model$symbol_names
  if (is.null(data)) {
    sequences <- model$training_sequences
    orders <- model$training_orders
    ids <- names(sequences)
  } else {
    input <- .sequence_adv_hmm_input(data, sequence_id_col, order_col, state_col, symbols)
    sequences <- input$source$sequences
    orders <- input$source$orders
    ids <- input$source$sequence_ids
  }
  encoded <- lapply(sequences, function(z) match(z, symbols))
  if (is_mixture) {
    if (!is.null(component)) {
      .sequence_adv_scalar_number(component, "component", lower = 1,
                                  upper = model$n_components, integer = TRUE)
      components <- rep(as.integer(component), length(ids))
    } else if (is.null(data)) {
      components <- model$responsibilities$assigned_component[
        match(ids, model$responsibilities$sequence_id)]
    } else {
      loglik <- do.call(cbind, lapply(seq_len(model$n_components), function(k) {
        current <- model$components[[k]]
        p <- list(initial = current$initial_probs,
                  transition = current$transition_probs,
                  emission = current$emission_probs)
        .sequence_adv_hmm_loglik(encoded, p) +
          log(pmax(model$mixture_weights[k], .Machine$double.xmin))
      }))
      components <- max.col(loglik, ties.method = "first")
    }
  } else {
    components <- rep(1L, length(ids))
  }
  out <- list(); h <- 0L
  for (i in seq_along(ids)) {
    current <- if (is_single) {
      list(initial_probs = model$initial_probs,
           transition_probs = model$transition_probs,
           emission_probs = model$emission_probs,
           state_names = model$state_names)
    } else model$components[[components[i]]]
    p <- list(initial = current$initial_probs,
              transition = current$transition_probs,
              emission = current$emission_probs)
    fb <- .sequence_adv_forward_backward(encoded[[i]], p$initial, p$transition, p$emission)
    if (method == "viterbi") {
      decoded <- .sequence_adv_viterbi(encoded[[i]], p$initial, p$transition, p$emission)$path
      posterior_probability <- fb$gamma[cbind(seq_along(decoded), decoded)]
    } else {
      decoded <- max.col(fb$gamma, ties.method = "first")
      posterior_probability <- apply(fb$gamma, 1L, max)
    }
    for (t in seq_along(decoded)) {
      h <- h + 1L
      out[[h]] <- data.frame(
        sequence_id = ids[i],
        sequence_order = orders[[i]][t],
        observed_state = sequences[[i]][t],
        component = components[i],
        latent_state = current$state_names[decoded[t]],
        posterior_probability = posterior_probability[t],
        decoding_method = method,
        stringsAsFactors = FALSE
      )
    }
  }
  result <- do.call(rbind, out)
  row.names(result) <- NULL
  result
}

#' Summarise a fitted sequence HMM
#'
#' @param model A single or mixture HMM.
#'
#' @return A list of convergence, fit, initial, transition, emission, and
#' mixture summaries.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' model <- fit_sequence_hmm(sequences, 2L, max_iter = 5L)
#' summarise_sequence_hmm(model)
#'
#' @export
summarise_sequence_hmm <- function(model) {
  if (inherits(model, "gp3_sequence_hmm")) {
    initial <- data.frame(latent_state = names(model$initial_probs),
                          probability = as.numeric(model$initial_probs),
                          stringsAsFactors = FALSE)
    transition <- as.data.frame(as.table(model$transition_probs), stringsAsFactors = FALSE)
    names(transition) <- c("from_state", "to_state", "probability")
    emission <- as.data.frame(as.table(model$emission_probs), stringsAsFactors = FALSE)
    names(emission) <- c("latent_state", "observed_state", "probability")
    fit <- data.frame(log_likelihood = model$log_likelihood, aic = model$aic,
                      bic = model$bic, n_parameters = model$n_parameters,
                      n_observations = model$n_observations,
                      iterations = model$iterations, converged = model$converged,
                      stringsAsFactors = FALSE)
    return(list(fit = fit, initial = initial, transition = transition,
                emission = emission, mixture = NULL))
  }
  if (inherits(model, "gp3_sequence_hmm_mixture")) {
    component_summaries <- lapply(seq_along(model$components), function(k) {
      current <- model$components[[k]]
      transition <- as.data.frame(as.table(current$transition_probs), stringsAsFactors = FALSE)
      names(transition) <- c("from_state", "to_state", "probability")
      transition$component <- k
      emission <- as.data.frame(as.table(current$emission_probs), stringsAsFactors = FALSE)
      names(emission) <- c("latent_state", "observed_state", "probability")
      emission$component <- k
      initial <- data.frame(component = k, latent_state = names(current$initial_probs),
                            probability = as.numeric(current$initial_probs),
                            stringsAsFactors = FALSE)
      list(initial = initial, transition = transition, emission = emission)
    })
    fit <- data.frame(log_likelihood = model$log_likelihood, aic = model$aic,
                      bic = model$bic, n_parameters = model$n_parameters,
                      n_observations = model$n_observations,
                      iterations = model$iterations, converged = model$converged,
                      stringsAsFactors = FALSE)
    mixture <- data.frame(component = seq_len(model$n_components),
                          weight = as.numeric(model$mixture_weights),
                          n_states = model$n_states,
                          stringsAsFactors = FALSE)
    return(list(
      fit = fit,
      initial = do.call(rbind, lapply(component_summaries, `[[`, "initial")),
      transition = do.call(rbind, lapply(component_summaries, `[[`, "transition")),
      emission = do.call(rbind, lapply(component_summaries, `[[`, "emission")),
      mixture = mixture,
      responsibilities = model$responsibilities
    ))
  }
  stop("Unsupported HMM model object.", call. = FALSE)
}

#' Compare fitted sequence HMMs descriptively
#'
#' @param ... Fitted HMM or mixture-HMM objects.
#'
#' @return A data frame containing log likelihood, AIC, BIC, parameter count,
#' convergence status, and delta criteria. Criteria are descriptive and do not
#' automatically select a substantive model.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' model_1 <- fit_sequence_hmm(sequences, 1L, max_iter = 5L)
#' model_2 <- fit_sequence_hmm(sequences, 2L, max_iter = 5L)
#' compare_sequence_hmms(one = model_1, two = model_2)
#'
#' @export
compare_sequence_hmms <- function(...) {
  models <- list(...)
  if (length(models) < 2L) stop("Supply at least two fitted HMMs.", call. = FALSE)
  valid <- vapply(models, function(x) inherits(x, "gp3_sequence_hmm") ||
                    inherits(x, "gp3_sequence_hmm_mixture"), logical(1))
  if (!all(valid)) stop("All objects must be fitted sequence HMMs.", call. = FALSE)
  observation_counts <- vapply(models, `[[`, numeric(1), "n_observations")
  if (length(unique(observation_counts)) != 1L) {
    stop("HMM fit criteria are comparable only when models use the same number of observations.",
         call. = FALSE)
  }
  reference_ids <- models[[1L]]$sequence_ids
  reference_symbols <- models[[1L]]$symbol_names
  reference_sequences <- models[[1L]]$training_sequences
  reference_orders <- models[[1L]]$training_orders
  same_ids <- vapply(models, function(model) {
    identical(model$sequence_ids, reference_ids)
  }, logical(1))
  same_symbols <- vapply(models, function(model) {
    identical(model$symbol_names, reference_symbols)
  }, logical(1))
  same_sequences <- vapply(models, function(model) {
    identical(model$training_sequences, reference_sequences) &&
      identical(model$training_orders, reference_orders)
  }, logical(1))
  if (!all(same_ids) || !all(same_symbols) || !all(same_sequences)) {
    stop("HMM fit criteria are comparable only for identical training sequences, orders, and symbol coding.",
         call. = FALSE)
  }
  labels <- names(models)
  if (is.null(labels) || anyNA(labels) || any(!nzchar(labels)) ||
      anyDuplicated(labels)) {
    labels <- paste0("model_", seq_along(models))
  }
  out <- do.call(rbind, lapply(seq_along(models), function(i) {
    model <- models[[i]]
    data.frame(model = labels[i], class = class(model)[1L],
               log_likelihood = model$log_likelihood, aic = model$aic,
               bic = model$bic, n_parameters = model$n_parameters,
               n_observations = model$n_observations,
               converged = model$converged, stringsAsFactors = FALSE)
  }))
  out$delta_aic <- out$aic - min(out$aic)
  out$delta_bic <- out$bic - min(out$bic)
  out[order(out$bic, out$aic, out$model, method = "radix"), , drop = FALSE]
}
