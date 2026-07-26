.sequence_ext_multichannel_input <- function(
  data,
  sequence_id_col,
  order_col,
  channel_cols,
  symbol_levels = NULL
) {
  if (!is.character(channel_cols) || length(channel_cols) < 2L ||
      anyNA(channel_cols) || any(!nzchar(channel_cols)) || anyDuplicated(channel_cols)) {
    stop("`channel_cols` must contain at least two unique channel names.",
         call. = FALSE)
  }
  if (is.list(data) && !is.data.frame(data) && !is.null(data$data)) data <- data$data
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  missing <- setdiff(channel_cols, names(data))
  if (length(missing) > 0L) {
    stop("Missing channel columns: ", paste(missing, collapse = ", "), ".",
         call. = FALSE)
  }
  x <- .sequence_adv_data(
    data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = channel_cols[1L],
    missing_state_policy = "error"
  )
  working <- x$data
  for (channel in channel_cols) {
    values <- working[[channel]]
    text <- as.character(values)
    if (is.list(values) || anyNA(values) || any(!nzchar(trimws(text)))) {
      stop("Channel `", channel, "` contains missing, blank, or non-atomic values.",
           call. = FALSE)
    }
  }
  if (is.null(symbol_levels)) symbol_levels <- vector("list", length(channel_cols))
  if (!is.list(symbol_levels) || !(length(symbol_levels) %in% c(0L, length(channel_cols)))) {
    stop("`symbol_levels` must be `NULL` or one list element per channel.",
         call. = FALSE)
  }
  if (length(symbol_levels) == 0L) symbol_levels <- vector("list", length(channel_cols))
  names(symbol_levels) <- channel_cols
  symbols <- vector("list", length(channel_cols))
  names(symbols) <- channel_cols
  for (i in seq_along(channel_cols)) {
    channel <- channel_cols[i]
    observed <- unique(as.character(working[[channel]]))
    current <- symbol_levels[[i]]
    if (is.null(current)) {
      current <- if (is.factor(working[[channel]])) {
        levels(working[[channel]])[levels(working[[channel]]) %in% observed]
      } else sort(observed, method = "radix")
    }
    current <- as.character(current)
    if (length(current) < 1L || anyNA(current) || any(!nzchar(trimws(current))) ||
        anyDuplicated(current)) {
      stop("Invalid symbol levels for channel `", channel, "`.", call. = FALSE)
    }
    missing_symbols <- setdiff(observed, current)
    if (length(missing_symbols) > 0L) {
      stop("Symbol levels for channel `", channel,
           "` do not cover: ", paste(missing_symbols, collapse = ", "), ".",
           call. = FALSE)
    }
    symbols[[channel]] <- current
  }
  ids <- x$sequence_ids
  split_rows <- split(seq_len(nrow(working)),
                      factor(as.character(working[[sequence_id_col]]), levels = ids),
                      drop = TRUE)
  observations <- lapply(split_rows, function(rows) {
    out <- matrix(NA_integer_, nrow = length(rows), ncol = length(channel_cols),
                  dimnames = list(NULL, channel_cols))
    for (j in seq_along(channel_cols)) {
      out[, j] <- match(as.character(working[[channel_cols[j]]][rows]),
                        symbols[[channel_cols[j]]])
    }
    out
  })
  orders <- lapply(split_rows, function(rows) working[[order_col]][rows])
  names(observations) <- ids
  names(orders) <- ids
  list(
    data = working,
    sequence_ids = ids,
    observations = observations,
    orders = orders,
    channel_cols = channel_cols,
    symbols = symbols,
    columns = list(sequence_id = sequence_id_col, order = order_col)
  )
}

.sequence_ext_multichannel_emission <- function(observation, emission_probs) {
  n_time <- nrow(observation)
  n_states <- nrow(emission_probs[[1L]])
  likelihood <- matrix(1, nrow = n_time, ncol = n_states)
  for (channel in seq_along(emission_probs)) {
    current <- emission_probs[[channel]]
    likelihood <- likelihood * t(current[, observation[, channel], drop = FALSE])
  }
  likelihood
}

.sequence_ext_multichannel_initialise <- function(n_states, symbols, seed,
                                                   initial_probs = NULL,
                                                   transition_probs = NULL,
                                                   emission_probs = NULL) {
  generated <- .sequence_adv_with_seed(seed, {
    list(
      initial = if (is.null(initial_probs)) stats::rexp(n_states) + 0.1 else initial_probs,
      transition = if (is.null(transition_probs)) {
        matrix(stats::rexp(n_states * n_states) + 0.1,
               nrow = n_states, ncol = n_states)
      } else transition_probs,
      emissions = if (is.null(emission_probs)) {
        lapply(symbols, function(levels) {
          matrix(stats::rexp(n_states * length(levels)) + 0.1,
                 nrow = n_states, ncol = length(levels))
        })
      } else emission_probs
    )
  })
  if (!is.numeric(generated$initial) || length(generated$initial) != n_states ||
      anyNA(generated$initial) || any(!is.finite(generated$initial)) ||
      any(generated$initial < 0)) {
    stop("Invalid `initial_probs`.", call. = FALSE)
  }
  if (!is.matrix(generated$transition) ||
      !all(dim(generated$transition) == c(n_states, n_states)) ||
      anyNA(generated$transition) || any(!is.finite(generated$transition)) ||
      any(generated$transition < 0)) {
    stop("Invalid `transition_probs`.", call. = FALSE)
  }
  if (!is.list(generated$emissions) || length(generated$emissions) != length(symbols)) {
    stop("`emission_probs` must contain one matrix per channel.", call. = FALSE)
  }
  for (i in seq_along(symbols)) {
    current <- generated$emissions[[i]]
    if (!is.matrix(current) || !all(dim(current) == c(n_states, length(symbols[[i]]))) ||
        anyNA(current) || any(!is.finite(current)) || any(current < 0)) {
      stop("Invalid emission probabilities for channel `", names(symbols)[i], "`.",
           call. = FALSE)
    }
  }
  list(
    initial = .sequence_adv_vector_normalise(generated$initial),
    transition = .sequence_adv_row_normalise(generated$transition),
    emissions = lapply(generated$emissions, .sequence_adv_row_normalise)
  )
}

#' Fit a multichannel categorical hidden Markov model
#'
#' Fits a finite-state, time-homogeneous HMM to two or more categorical
#' channels under conditional independence of channels given the latent state.
#' Latent states are statistical model states only.
#'
#' @param data Long-format multichannel sequence data.
#' @param n_states Number of latent states.
#' @param channel_cols Names of categorical observation channels.
#' @param sequence_id_col,order_col Core sequence columns.
#' @param symbol_levels Optional named list of symbol orders by channel.
#' @param state_names Optional latent-state names.
#' @param initial_probs,transition_probs,emission_probs Optional starting values.
#' @param max_iter Maximum EM iterations.
#' @param tolerance Relative log-likelihood tolerance.
#' @param pseudocount Non-negative smoothing count.
#' @param seed Reproducibility seed.
#' @param keep_posteriors Retain final forward-backward results.
#'
#' @return An object of class `gp3_multichannel_sequence_hmm`.
#' @examples
#' multichannel <- data.frame(
#'   sequence_id = rep(paste0("s", 1:4), each = 5L),
#'   sequence_order = rep(1:5, times = 4L),
#'   action = c("A", "B", "C", "C", "D", "A", "B", "B", "C", "D",
#'              "D", "C", "B", "A", "A", "D", "C", "C", "B", "A"),
#'   context = rep(c("x", "x", "y", "y", "z"), times = 4L)
#' )
#' fit_multichannel_sequence_hmm(multichannel, 2L,
#'                               channel_cols = c("action", "context"),
#'                               max_iter = 5L, seed = 1L)
#' @export
fit_multichannel_sequence_hmm <- function(
  data,
  n_states,
  channel_cols,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
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
  input <- .sequence_ext_multichannel_input(
    data, sequence_id_col, order_col, channel_cols, symbol_levels
  )
  if (is.null(state_names)) state_names <- paste0("latent_", seq_len(n_states))
  if (!is.character(state_names) || length(state_names) != n_states ||
      anyNA(state_names) || any(!nzchar(trimws(state_names))) ||
      anyDuplicated(state_names)) {
    stop("`state_names` must uniquely name all latent states.", call. = FALSE)
  }
  parameters <- .sequence_ext_multichannel_initialise(
    n_states, input$symbols, seed, initial_probs, transition_probs,
    emission_probs
  )
  history <- numeric(max_iter)
  converged <- FALSE
  previous <- -Inf
  posteriors <- NULL
  for (iteration in seq_len(max_iter)) {
    initial_count <- rep(pseudocount, n_states)
    transition_count <- matrix(pseudocount, nrow = n_states, ncol = n_states)
    emission_count <- lapply(input$symbols, function(levels) {
      matrix(pseudocount, nrow = n_states, ncol = length(levels))
    })
    sequence_loglik <- numeric(length(input$observations))
    posterior_current <- vector("list", length(input$observations))
    for (s in seq_along(input$observations)) {
      obs <- input$observations[[s]]
      likelihood <- .sequence_ext_multichannel_emission(obs, parameters$emissions)
      fb <- .sequence_ext_forward_backward(
        likelihood, parameters$initial, parameters$transition
      )
      initial_count <- initial_count + fb$gamma[1L, ]
      if (nrow(obs) > 1L) {
        transition_count <- transition_count + apply(fb$xi, c(2L, 3L), sum)
      }
      for (channel in seq_along(input$symbols)) {
        for (t in seq_len(nrow(obs))) {
          emission_count[[channel]][, obs[t, channel]] <-
            emission_count[[channel]][, obs[t, channel]] + fb$gamma[t, ]
        }
      }
      sequence_loglik[s] <- fb$log_likelihood
      posterior_current[[s]] <- fb
    }
    current <- sum(sequence_loglik)
    history[iteration] <- current
    parameters$initial <- .sequence_adv_vector_normalise(initial_count)
    parameters$transition <- .sequence_adv_row_normalise(transition_count)
    parameters$emissions <- lapply(emission_count, .sequence_adv_row_normalise)
    if (iteration > 1L) {
      relative <- abs(current - previous) / max(1, abs(previous))
      if (relative <= tolerance) {
        converged <- TRUE
        history <- history[seq_len(iteration)]
        posteriors <- posterior_current
        break
      }
    }
    previous <- current
    posteriors <- posterior_current
    if (iteration == max_iter) history <- history[seq_len(iteration)]
  }
  final_loglik <- numeric(length(input$observations))
  final_posteriors <- vector("list", length(input$observations))
  for (s in seq_along(input$observations)) {
    likelihood <- .sequence_ext_multichannel_emission(
      input$observations[[s]], parameters$emissions
    )
    fb <- .sequence_ext_forward_backward(
      likelihood, parameters$initial, parameters$transition
    )
    final_loglik[s] <- fb$log_likelihood
    final_posteriors[[s]] <- fb
  }
  log_likelihood <- sum(final_loglik)
  history[length(history)] <- log_likelihood
  names(parameters$initial) <- state_names
  dimnames(parameters$transition) <- list(state_names, state_names)
  names(parameters$emissions) <- input$channel_cols
  for (channel in seq_along(parameters$emissions)) {
    dimnames(parameters$emissions[[channel]]) <-
      list(state_names, input$symbols[[channel]])
  }
  n_parameters <- (n_states - 1L) + n_states * (n_states - 1L) +
    sum(vapply(input$symbols, function(levels) {
      n_states * (length(levels) - 1L)
    }, numeric(1)))
  n_observations <- sum(vapply(input$observations, nrow, integer(1)))
  result <- list(
    initial_probs = parameters$initial,
    transition_probs = parameters$transition,
    emission_probs = parameters$emissions,
    state_names = state_names,
    channel_names = input$channel_cols,
    symbol_names = input$symbols,
    sequence_ids = input$sequence_ids,
    sequence_log_likelihoods = stats::setNames(final_loglik, input$sequence_ids),
    log_likelihood = log_likelihood,
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
    training_observations = input$observations,
    training_orders = input$orders,
    posteriors = if (keep_posteriors) final_posteriors else NULL,
    columns = input$columns,
    call = match.call()
  )
  class(result) <- c("gp3_multichannel_sequence_hmm", "list")
  result
}

#' Decode latent states from a multichannel HMM
#'
#' @param model A fitted multichannel HMM.
#' @param data Optional new long-format multichannel data.
#' @param sequence_id_col,order_col Core sequence columns for new data.
#' @param channel_cols Channel columns for new data; defaults to training names.
#' @param method `"viterbi"` or `"posterior"`.
#'
#' @return A long data frame of decoded states and posterior probabilities.
#' @examples
#' # See `fit_multichannel_sequence_hmm()`.
#' @export
decode_multichannel_sequence_states <- function(
  model,
  data = NULL,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  channel_cols = NULL,
  method = c("viterbi", "posterior")
) {
  if (!inherits(model, "gp3_multichannel_sequence_hmm")) {
    stop("`model` must be created by `fit_multichannel_sequence_hmm()`.",
         call. = FALSE)
  }
  method <- match.arg(method)
  if (is.null(channel_cols)) channel_cols <- model$channel_names
  if (is.null(data)) {
    observations <- model$training_observations
    orders <- model$training_orders
    ids <- model$sequence_ids
  } else {
    input <- .sequence_ext_multichannel_input(
      data, sequence_id_col, order_col, channel_cols,
      symbol_levels = model$symbol_names
    )
    observations <- input$observations
    orders <- input$orders
    ids <- input$sequence_ids
  }
  rows <- list()
  h <- 0L
  for (i in seq_along(ids)) {
    likelihood <- .sequence_ext_multichannel_emission(
      observations[[i]], model$emission_probs
    )
    fb <- .sequence_ext_forward_backward(
      likelihood, model$initial_probs, model$transition_probs
    )
    if (method == "viterbi") {
      decoded <- .sequence_ext_viterbi(
        likelihood, model$initial_probs, model$transition_probs
      )$path
    } else {
      decoded <- max.col(fb$gamma, ties.method = "first")
    }
    posterior_probability <- fb$gamma[cbind(seq_along(decoded), decoded)]
    for (t in seq_along(decoded)) {
      h <- h + 1L
      row <- data.frame(
        sequence_id = ids[i],
        sequence_order = orders[[i]][t],
        latent_state = model$state_names[decoded[t]],
        posterior_probability = posterior_probability[t],
        decoding_method = method,
        stringsAsFactors = FALSE
      )
      for (channel in seq_along(model$channel_names)) {
        row[[model$channel_names[channel]]] <-
          model$symbol_names[[channel]][observations[[i]][t, channel]]
      }
      rows[[h]] <- row
    }
  }
  result <- do.call(rbind, rows)
  row.names(result) <- NULL
  result
}

#' Summarise a multichannel sequence HMM
#'
#' @param model A fitted multichannel HMM.
#'
#' @return A list of convergence, fit, transition, initial, and channel-specific
#'   emission summaries.
#' @examples
#' # See `fit_multichannel_sequence_hmm()`.
#' @export
summarise_multichannel_sequence_hmm <- function(model) {
  if (!inherits(model, "gp3_multichannel_sequence_hmm")) {
    stop("`model` must be created by `fit_multichannel_sequence_hmm()`.",
         call. = FALSE)
  }
  list(
    fit = data.frame(
      n_states = length(model$state_names),
      n_channels = length(model$channel_names),
      n_sequences = length(model$sequence_ids),
      n_observations = model$n_observations,
      log_likelihood = model$log_likelihood,
      aic = model$aic,
      bic = model$bic,
      iterations = model$iterations,
      converged = model$converged,
      stringsAsFactors = FALSE
    ),
    initial = data.frame(latent_state = names(model$initial_probs),
                         probability = as.numeric(model$initial_probs),
                         stringsAsFactors = FALSE),
    transition = as.data.frame(as.table(model$transition_probs),
                               stringsAsFactors = FALSE),
    emission = lapply(model$emission_probs, function(x) {
      as.data.frame(as.table(x), stringsAsFactors = FALSE)
    })
  )
}

#' Plot multichannel HMM emission profiles
#'
#' @param model A fitted multichannel HMM.
#' @param channel Channel name to plot.
#' @param ... Additional arguments passed to [graphics::barplot()].
#'
#' @return The selected emission matrix, invisibly.
#' @examples
#' # See `fit_multichannel_sequence_hmm()`.
#' @export
plot_multichannel_sequence_hmm <- function(model, channel = model$channel_names[1L], ...) {
  if (!inherits(model, "gp3_multichannel_sequence_hmm")) {
    stop("`model` must be created by `fit_multichannel_sequence_hmm()`.",
         call. = FALSE)
  }
  .sequence_adv_scalar_character(channel, "channel")
  if (!(channel %in% model$channel_names)) stop("Unknown channel.", call. = FALSE)
  matrix_value <- model$emission_probs[[channel]]
  graphics::barplot(
    t(matrix_value),
    beside = TRUE,
    legend.text = colnames(matrix_value),
    args.legend = list(x = "topright", bty = "n"),
    ylab = "Emission probability",
    xlab = "Latent state",
    names.arg = rownames(matrix_value),
    ...
  )
  invisible(matrix_value)
}
