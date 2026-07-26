#' Fit a time-varying sequence condition model
#'
#' Fits a binary generalized additive model for either occupancy of a target
#' state or occurrence of a target transition over aligned sequence time. Group
#' specific smooths model time-varying condition differences, and a participant
#' random-effect smooth accounts for repeated observations. The optional `mgcv`
#' package is required.
#'
#' @param data Long-format sequence data or a prepared result.
#' @param group_col Group or condition column.
#' @param participant_id_col Participant or repeated-unit column.
#' @param sequence_id_col,order_col,state_col Core sequence columns.
#' @param time_col Optional numeric time column; defaults to `order_col`.
#' @param outcome `"state"` or `"transition"`.
#' @param target_state Target state for occupancy models.
#' @param from_state,to_state Target transition for transition models.
#' @param k Basis dimension for time smooths.
#' @param method Smoothing-parameter estimation method passed to
#'   [mgcv::gam()].
#' @param include_random_effect Include a participant random-effect smooth.
#'
#' @return An object of class `gp3_sequence_time_model`.
#' @examples
#' set.seed(2026)
#'
#' n_participants <- 24L
#' n_positions <- 12L
#'
#' participant_index <- rep(
#'   seq_len(n_participants),
#'   each = n_positions
#' )
#'
#' sequence_order <- rep(
#'   seq_len(n_positions),
#'   times = n_participants
#' )
#'
#' group_by_participant <- rep(
#'   c("control", "treatment"),
#'   each = n_participants %/% 2L
#' )
#'
#' group <- rep(
#'   group_by_participant,
#'   each = n_positions
#' )
#'
#' probability <- stats::plogis(
#'   -0.8 +
#'     0.08 * sequence_order +
#'     0.4 * (group == "treatment")
#' )
#'
#' observed_b <- stats::rbinom(
#'   length(probability),
#'   size = 1L,
#'   prob = probability
#' )
#'
#' sequences <- data.frame(
#'   participant_id = paste0("p", participant_index),
#'   sequence_id = paste0("s", participant_index),
#'   sequence_order = sequence_order,
#'   state = ifelse(observed_b == 1L, "B", "A"),
#'   group = group
#' )
#'
#' if (requireNamespace("mgcv", quietly = TRUE)) {
#'   fit <- fit_time_varying_sequence_model(
#'     sequences,
#'     group_col = "group",
#'     participant_id_col = "participant_id",
#'     target_state = "B",
#'     k = 4L
#'   )
#' }
#' @export
fit_time_varying_sequence_model <- function(
  data,
  group_col,
  participant_id_col,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  time_col = NULL,
  outcome = c("state", "transition"),
  target_state = NULL,
  from_state = NULL,
  to_state = NULL,
  k = 5L,
  method = "REML",
  include_random_effect = TRUE
) {
  .sequence_adv_require("mgcv", "fit time-varying sequence models")
  outcome <- match.arg(outcome)
  .sequence_adv_scalar_character(group_col, "group_col")
  .sequence_adv_scalar_character(participant_id_col, "participant_id_col")
  if (is.null(time_col)) time_col <- order_col
  .sequence_adv_scalar_character(time_col, "time_col")
  .sequence_adv_scalar_number(k, "k", lower = 3, integer = TRUE)
  .sequence_adv_scalar_character(method, "method")
  .sequence_adv_scalar_logical(include_random_effect, "include_random_effect")
  if (outcome == "state") {
    .sequence_adv_scalar_character(target_state, "target_state")
  } else {
    .sequence_adv_scalar_character(from_state, "from_state")
    .sequence_adv_scalar_character(to_state, "to_state")
  }
  required_metadata <- unique(c(group_col, participant_id_col))
  x <- .sequence_adv_data(
    data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    metadata_cols = required_metadata,
    missing_state_policy = "error"
  )
  working <- x$data
  if (!(time_col %in% names(working))) {
    stop("Missing time column `", time_col, "`.", call. = FALSE)
  }
  time_value <- working[[time_col]]
  if (!is.numeric(time_value) || anyNA(time_value) || any(!is.finite(time_value))) {
    stop("The time column must contain finite, non-missing numeric values.",
         call. = FALSE)
  }
  group_value <- as.character(working[[group_col]])
  participant_value <- as.character(working[[participant_id_col]])
  if (anyNA(group_value) || any(!nzchar(trimws(group_value)))) {
    stop("Group values must not be missing or blank.", call. = FALSE)
  }
  if (anyNA(participant_value) || any(!nzchar(trimws(participant_value)))) {
    stop("Participant identifiers must not be missing or blank.", call. = FALSE)
  }
  if (outcome == "state") {
    model_data <- data.frame(
      .outcome = as.integer(as.character(working[[state_col]]) == target_state),
      .time = as.numeric(time_value),
      .group = factor(group_value),
      .participant = factor(participant_value),
      stringsAsFactors = FALSE
    )
  } else {
    rows <- list()
    h <- 0L
    split_rows <- split(seq_len(nrow(working)),
                        factor(as.character(working[[sequence_id_col]]),
                               levels = x$sequence_ids), drop = TRUE)
    for (sequence_id in names(split_rows)) {
      current_rows <- split_rows[[sequence_id]]
      if (length(current_rows) < 2L) next
      current_state <- as.character(working[[state_col]][current_rows])
      for (j in seq_len(length(current_rows) - 1L)) {
        row <- current_rows[j]
        h <- h + 1L
        rows[[h]] <- data.frame(
          .outcome = as.integer(identical(current_state[j], from_state) &&
                                  identical(current_state[j + 1L], to_state)),
          .time = as.numeric(working[[time_col]][row]),
          .group = group_value[row],
          .participant = participant_value[row],
          stringsAsFactors = FALSE
        )
      }
    }
    if (length(rows) == 0L) stop("No transitions are available for modelling.", call. = FALSE)
    model_data <- do.call(rbind, rows)
    model_data$.group <- factor(model_data$.group)
    model_data$.participant <- factor(model_data$.participant)
  }
  if (nlevels(model_data$.group) < 2L) {
    stop("At least two groups are required.", call. = FALSE)
  }
  if (length(unique(model_data$.time)) < 4L) {
    stop("At least four distinct time values are required.", call. = FALSE)
  }
  if (length(unique(model_data$.outcome)) < 2L) {
    stop("The target outcome has no variation.", call. = FALSE)
  }
  k_used <- min(as.integer(k), length(unique(model_data$.time)) - 1L)
  formula_text <- paste0(
    ".outcome ~ .group + s(.time, by = .group, k = ",
    k_used, ")",
    if (include_random_effect) " + s(.participant, bs = 're')" else ""
  )
  model_formula <- stats::as.formula(formula_text)
  environment(model_formula) <- asNamespace("mgcv")
  fit <- mgcv::gam(
    formula = model_formula,
    family = stats::binomial(),
    data = model_data,
    method = method,
    drop.unused.levels = TRUE
  )
  result <- list(
    model = fit,
    model_data = model_data,
    outcome = outcome,
    target_state = target_state,
    from_state = from_state,
    to_state = to_state,
    group_levels = levels(model_data$.group),
    participant_levels = levels(model_data$.participant),
    time_range = range(model_data$.time),
    k = k_used,
    method = method,
    include_random_effect = include_random_effect,
    columns = list(group = group_col, participant = participant_id_col,
                   sequence_id = sequence_id_col, order = order_col,
                   state = state_col, time = time_col),
    call = match.call()
  )
  class(result) <- c("gp3_sequence_time_model", "list")
  result
}

#' Predict a time-varying sequence model
#'
#' @param model A fitted time-varying sequence model.
#' @param time Optional numeric prediction grid.
#' @param groups Optional subset of fitted groups.
#' @param level Confidence level for pointwise intervals.
#'
#' @return A data frame with fitted probabilities and pointwise intervals.
#' @examples
#' # See `fit_time_varying_sequence_model()`.
#' @export
predict_time_varying_sequence_model <- function(
  model,
  time = NULL,
  groups = NULL,
  level = 0.95
) {
  if (!inherits(model, "gp3_sequence_time_model")) {
    stop("`model` must be created by `fit_time_varying_sequence_model()`.",
         call. = FALSE)
  }
  .sequence_adv_scalar_number(level, "level", lower = 0.5, upper = 0.999999)
  if (is.null(time)) time <- seq(model$time_range[1L], model$time_range[2L], length.out = 100L)
  if (!is.numeric(time) || anyNA(time) || any(!is.finite(time))) {
    stop("`time` must contain finite numeric values.", call. = FALSE)
  }
  if (is.null(groups)) groups <- model$group_levels
  groups <- as.character(groups)
  if (any(!groups %in% model$group_levels)) {
    stop("Unknown groups requested for prediction.", call. = FALSE)
  }
  grid <- expand.grid(
    .time = sort(unique(as.numeric(time))),
    .group = groups,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  grid$.group <- factor(grid$.group, levels = model$group_levels)
  grid$.participant <- factor(model$participant_levels[1L],
                              levels = model$participant_levels)
  excluded <- if (model$include_random_effect) "s(.participant)" else NULL
  prediction <- stats::predict(
    model$model,
    newdata = grid,
    type = "link",
    se.fit = TRUE,
    exclude = excluded
  )
  z <- stats::qnorm(1 - (1 - level) / 2)
  grid$estimate <- stats::plogis(as.numeric(prediction$fit))
  grid$lower <- stats::plogis(as.numeric(prediction$fit) - z * as.numeric(prediction$se.fit))
  grid$upper <- stats::plogis(as.numeric(prediction$fit) + z * as.numeric(prediction$se.fit))
  names(grid)[names(grid) == ".time"] <- "time"
  names(grid)[names(grid) == ".group"] <- "group"
  grid$.participant <- NULL
  grid$group <- as.character(grid$group)
  grid$outcome <- model$outcome
  grid
}

#' Summarise a time-varying sequence model
#'
#' @param model A fitted time-varying sequence model.
#'
#' @return A list containing model metadata, parametric terms, smooth terms,
#'   deviance explained, and convergence information.
#' @examples
#' # See `fit_time_varying_sequence_model()`.
#' @export
summarise_time_varying_sequence_model <- function(model) {
  if (!inherits(model, "gp3_sequence_time_model")) {
    stop("`model` must be created by `fit_time_varying_sequence_model()`.",
         call. = FALSE)
  }
  summary_value <- summary(model$model)
  list(
    metadata = data.frame(
      outcome = model$outcome,
      target_state = if (is.null(model$target_state)) NA_character_ else model$target_state,
      from_state = if (is.null(model$from_state)) NA_character_ else model$from_state,
      to_state = if (is.null(model$to_state)) NA_character_ else model$to_state,
      n_observations = nrow(model$model_data),
      n_groups = length(model$group_levels),
      n_participants = length(model$participant_levels),
      k = model$k,
      deviance_explained = summary_value$dev.expl,
      adjusted_r_squared = summary_value$r.sq,
      stringsAsFactors = FALSE
    ),
    parametric_terms = as.data.frame(summary_value$p.table),
    smooth_terms = as.data.frame(summary_value$s.table),
    converged = isTRUE(model$model$converged),
    method = model$method
  )
}

#' Plot predicted time-varying sequence probabilities
#'
#' @param model A fitted time-varying sequence model.
#' @param time Optional prediction grid.
#' @param level Pointwise confidence level.
#' @param show_interval Draw pointwise confidence ribbons.
#' @param ... Additional arguments passed to [graphics::plot()].
#'
#' @return Prediction data, invisibly.
#' @examples
#' # See `fit_time_varying_sequence_model()`.
#' @export
plot_time_varying_sequence_model <- function(
  model,
  time = NULL,
  level = 0.95,
  show_interval = TRUE,
  ...
) {
  .sequence_adv_scalar_logical(show_interval, "show_interval")
  prediction <- predict_time_varying_sequence_model(model, time = time, level = level)
  groups <- unique(prediction$group)
  colors <- .sequence_ext_base_colors(length(groups))
  graphics::plot(
    range(prediction$time), range(c(prediction$lower, prediction$upper), finite = TRUE),
    type = "n", xlab = "Sequence time", ylab = "Estimated probability", ...
  )
  for (i in seq_along(groups)) {
    current <- prediction[prediction$group == groups[i], , drop = FALSE]
    current <- current[order(current$time), , drop = FALSE]
    if (show_interval) {
      polygon_x <- c(current$time, rev(current$time))
      polygon_y <- c(current$lower, rev(current$upper))
      graphics::polygon(polygon_x, polygon_y,
                        col = grDevices::adjustcolor(colors[i], alpha.f = 0.2),
                        border = NA)
    }
    graphics::lines(current$time, current$estimate, col = colors[i], lwd = 2)
  }
  graphics::legend("topright", legend = groups, col = colors, lwd = 2, bty = "n")
  invisible(prediction)
}
