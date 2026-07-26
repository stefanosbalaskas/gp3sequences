#' Declare a sequence group-comparison design
#'
#' Records the unit of assignment and the design under which a sequence-group
#' contrast will be evaluated. Causal interpretation is permitted only for an
#' explicitly randomized design and still depends on the validity of the study
#' implementation.
#'
#' @param group_col Group or treatment column.
#' @param unit_col Independent assignment or analysis-unit column.
#' @param design `"observational"`, `"randomized"`, or
#'   `"paired_randomized"`.
#' @param pair_col Pair or block column required for paired randomization.
#' @param cluster_col Optional higher-level assignment cluster.
#'
#' @return An object of class `gp3_sequence_comparison_design`.
#' @examples
#' declare_sequence_comparison_design("group", "participant_id",
#'                                    design = "randomized")
#' @export
declare_sequence_comparison_design <- function(
  group_col,
  unit_col,
  design = c("observational", "randomized", "paired_randomized"),
  pair_col = NULL,
  cluster_col = NULL
) {
  design <- match.arg(design)
  .sequence_adv_scalar_character(group_col, "group_col")
  .sequence_adv_scalar_character(unit_col, "unit_col")
  .sequence_adv_scalar_character(pair_col, "pair_col", allow_null = TRUE)
  .sequence_adv_scalar_character(cluster_col, "cluster_col", allow_null = TRUE)
  if (design == "paired_randomized" && is.null(pair_col)) {
    stop("`pair_col` is required for a paired randomized design.", call. = FALSE)
  }
  result <- list(
    group_col = group_col,
    unit_col = unit_col,
    design = design,
    pair_col = pair_col,
    cluster_col = cluster_col,
    interpretation = if (design == "observational") "associational" else "randomization-based",
    call = match.call()
  )
  class(result) <- c("gp3_sequence_comparison_design", "list")
  result
}

.sequence_ext_sequence_metric <- function(
  data,
  design,
  sequence_id_col,
  order_col,
  state_col,
  metric,
  target_state,
  target_subsequence,
  separator
) {
  metadata_cols <- unique(c(design$group_col, design$unit_col,
                            design$pair_col, design$cluster_col))
  metadata_cols <- metadata_cols[!is.na(metadata_cols)]
  x <- .sequence_adv_data(
    data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    metadata_cols = metadata_cols,
    missing_state_policy = "error"
  )
  meta <- x$metadata
  names(meta)[names(meta) == sequence_id_col] <- "sequence_id"
  values <- vapply(x$sequence_ids, function(id) {
    sequence <- x$sequences[[id]]
    switch(
      metric,
      sequence_length = length(sequence),
      transition_count = max(length(sequence) - 1L, 0L),
      state_prevalence = mean(sequence == target_state),
      subsequence_presence = as.numeric(
        .sequence_ext_subsequence_present(
          sequence,
          strsplit(target_subsequence, separator, fixed = TRUE)[[1L]]
        )
      )
    )
  }, numeric(1))
  metric_data <- data.frame(
    sequence_id = x$sequence_ids,
    metric = as.numeric(values[x$sequence_ids]),
    stringsAsFactors = FALSE
  )
  merged <- merge(metric_data, meta, by = "sequence_id", sort = FALSE)
  unit_cols <- unique(c(design$unit_col, design$group_col,
                        design$pair_col, design$cluster_col))
  unit_cols <- unit_cols[!is.na(unit_cols)]
  key <- .sequence_adv_group_key(merged, unit_cols)
  pieces <- split(seq_len(nrow(merged)), key, drop = TRUE)
  unit_data <- do.call(rbind, lapply(pieces, function(rows) {
    prefix <- merged[rows[1L], unit_cols, drop = FALSE]
    cbind(prefix, data.frame(
      metric = mean(merged$metric[rows]),
      n_sequences = length(rows),
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
  }))
  row.names(unit_data) <- NULL
  list(sequence_data = merged, unit_data = unit_data, state_levels = x$state_levels)
}

.sequence_ext_difference <- function(metric, group, levels) {
  means <- tapply(metric, factor(group, levels = levels), mean)
  unname(means[2L] - means[1L])
}

.sequence_ext_permuted_groups <- function(unit_data, design, group_levels) {
  group <- as.character(unit_data[[design$group_col]])
  if (design$design == "paired_randomized") {
    pair <- as.character(unit_data[[design$pair_col]])
    output <- group
    for (value in unique(pair)) {
      rows <- which(pair == value)
      if (length(rows) != 2L || !setequal(group[rows], group_levels)) {
        stop("Each randomized pair must contain exactly one unit from each group.",
             call. = FALSE)
      }
      if (stats::runif(1) < 0.5) output[rows] <- rev(group[rows])
    }
    return(output)
  }
  assignment_col <- if (is.null(design$cluster_col)) design$unit_col else design$cluster_col
  assignment <- as.character(unit_data[[assignment_col]])
  cluster_group <- tapply(group, assignment, function(x) {
    value <- unique(x)
    if (length(value) != 1L) {
      stop("Assignment clusters must have one group label.", call. = FALSE)
    }
    value
  })
  permuted <- sample(cluster_group, length(cluster_group), replace = FALSE)
  names(permuted) <- names(cluster_group)
  unname(permuted[assignment])
}

#' Test a sequence group difference
#'
#' Aggregates sequence metrics to the declared independent unit and performs a
#' permutation or randomization test. For observational data the p-value tests
#' exchangeability-based association only; it is not a causal estimate.
#'
#' @param data Long-format sequence data.
#' @param design A comparison design.
#' @param metric `"sequence_length"`, `"transition_count"`,
#'   `"state_prevalence"`, or `"subsequence_presence"`.
#' @param target_state Required for state prevalence.
#' @param target_subsequence Required for subsequence presence, expressed using
#'   `separator`.
#' @param sequence_id_col,order_col,state_col Core sequence columns.
#' @param separator Subsequence label separator.
#' @param n_permutations Number of permutations.
#' @param alternative Alternative hypothesis.
#' @param seed Reproducibility seed.
#'
#' @return An object of class `gp3_sequence_group_inference`.
#' @examples
#' data <- data.frame(
#'   participant_id = rep(paste0("p", 1:8), each = 4L),
#'   sequence_id = rep(paste0("s", 1:8), each = 4L),
#'   sequence_order = rep(1:4, times = 8L),
#'   state = c(rep(c("A", "B", "C", "D"), 4L),
#'             rep(c("A", "A", "C", "D"), 4L)),
#'   group = rep(rep(c("control", "treatment"), each = 4L), each = 4L)
#' )
#' design <- declare_sequence_comparison_design("group", "participant_id",
#'                                              design = "randomized")
#' test_sequence_group_difference(data, design, metric = "state_prevalence",
#'                                target_state = "A", n_permutations = 99L)
#' @export
test_sequence_group_difference <- function(
  data,
  design,
  metric = c("sequence_length", "transition_count", "state_prevalence",
             "subsequence_presence"),
  target_state = NULL,
  target_subsequence = NULL,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  separator = " > ",
  n_permutations = 999L,
  alternative = c("two.sided", "greater", "less"),
  seed = 1L
) {
  if (!inherits(design, "gp3_sequence_comparison_design")) {
    stop("`design` must be created by `declare_sequence_comparison_design()`.",
         call. = FALSE)
  }
  metric <- match.arg(metric)
  alternative <- match.arg(alternative)
  if (metric == "state_prevalence") {
    .sequence_adv_scalar_character(target_state, "target_state")
  }
  if (metric == "subsequence_presence") {
    .sequence_adv_scalar_character(target_subsequence, "target_subsequence")
  }
  .sequence_adv_scalar_character(separator, "separator")
  .sequence_adv_scalar_number(n_permutations, "n_permutations", lower = 1,
                              integer = TRUE)
  .sequence_adv_scalar_number(seed, "seed", lower = 0, integer = TRUE)
  metric_value <- .sequence_ext_sequence_metric(
    data, design, sequence_id_col, order_col, state_col, metric,
    target_state, target_subsequence, separator
  )
  unit_data <- metric_value$unit_data
  groups <- as.character(unit_data[[design$group_col]])
  if (anyNA(groups) || any(!nzchar(trimws(groups)))) {
    stop("Group values must not be missing or blank.", call. = FALSE)
  }
  group_levels <- sort(unique(groups), method = "radix")
  if (length(group_levels) != 2L) {
    stop("The current inferential contrast requires exactly two groups.",
         call. = FALSE)
  }
  observed <- .sequence_ext_difference(unit_data$metric, groups, group_levels)
  permuted <- numeric(n_permutations)
  .sequence_adv_with_seed(seed, {
    for (i in seq_len(n_permutations)) {
      current_group <- .sequence_ext_permuted_groups(unit_data, design, group_levels)
      permuted[i] <- .sequence_ext_difference(unit_data$metric, current_group,
                                              group_levels)
    }
  })
  extreme <- switch(
    alternative,
    two.sided = abs(permuted) >= abs(observed),
    greater = permuted >= observed,
    less = permuted <= observed
  )
  p_value <- (1 + sum(extreme)) / (n_permutations + 1)
  means <- tapply(unit_data$metric, factor(groups, levels = group_levels), mean)
  result <- list(
    estimate = data.frame(
      group_1 = group_levels[1L],
      group_2 = group_levels[2L],
      mean_group_1 = unname(means[1L]),
      mean_group_2 = unname(means[2L]),
      difference_group_2_minus_group_1 = observed,
      p_value = p_value,
      alternative = alternative,
      n_permutations = as.integer(n_permutations),
      stringsAsFactors = FALSE
    ),
    permutation_distribution = permuted,
    unit_data = unit_data,
    sequence_data = metric_value$sequence_data,
    design = design,
    metric = metric,
    target_state = target_state,
    target_subsequence = target_subsequence,
    interpretation = if (design$design == "observational") {
      "Associational permutation contrast; causal interpretation is not supported."
    } else {
      "Randomization-based contrast, conditional on valid assignment and study implementation."
    },
    seed = as.integer(seed),
    call = match.call()
  )
  class(result) <- c("gp3_sequence_group_inference", "list")
  result
}

#' Bootstrap a sequence group difference
#'
#' Resamples declared independent units within groups and returns a percentile
#' interval for the mean difference. This interval does not by itself license
#' causal interpretation.
#'
#' @param inference A result from [test_sequence_group_difference()].
#' @param n_boot Number of bootstrap samples.
#' @param level Confidence level.
#' @param seed Reproducibility seed.
#'
#' @return The inference object with a `bootstrap` component.
#' @examples
#' # See `test_sequence_group_difference()`.
#' @export
bootstrap_sequence_group_difference <- function(
  inference,
  n_boot = 999L,
  level = 0.95,
  seed = 1L
) {
  if (!inherits(inference, "gp3_sequence_group_inference")) {
    stop("`inference` must be created by `test_sequence_group_difference()`.",
         call. = FALSE)
  }
  .sequence_adv_scalar_number(n_boot, "n_boot", lower = 1, integer = TRUE)
  .sequence_adv_scalar_number(level, "level", lower = 0.5, upper = 0.999999)
  .sequence_adv_scalar_number(seed, "seed", lower = 0, integer = TRUE)
  unit_data <- inference$unit_data
  groups <- as.character(unit_data[[inference$design$group_col]])
  group_levels <- c(inference$estimate$group_1, inference$estimate$group_2)
  boot <- numeric(n_boot)
  .sequence_adv_with_seed(seed, {
    for (b in seq_len(n_boot)) {
      means <- numeric(2L)
      for (g in seq_along(group_levels)) {
        values <- unit_data$metric[groups == group_levels[g]]
        means[g] <- mean(sample(values, length(values), replace = TRUE))
      }
      boot[b] <- means[2L] - means[1L]
    }
  })
  alpha <- (1 - level) / 2
  interval <- stats::quantile(boot, probs = c(alpha, 1 - alpha), names = FALSE,
                              type = 6)
  inference$bootstrap <- list(
    estimates = boot,
    interval = data.frame(
      level = level,
      lower = interval[1L],
      upper = interval[2L],
      n_boot = as.integer(n_boot),
      seed = as.integer(seed),
      stringsAsFactors = FALSE
    )
  )
  inference
}

#' Summarise sequence group inference
#'
#' @param inference A sequence group-inference object.
#'
#' @return A list containing the estimate, optional interval, design, and
#'   interpretation statement.
#' @examples
#' # See `test_sequence_group_difference()`.
#' @export
summarise_sequence_group_inference <- function(inference) {
  if (!inherits(inference, "gp3_sequence_group_inference")) {
    stop("`inference` must be created by `test_sequence_group_difference()`.",
         call. = FALSE)
  }
  list(
    estimate = inference$estimate,
    bootstrap_interval = if (is.null(inference$bootstrap)) NULL else inference$bootstrap$interval,
    design = data.frame(
      design = inference$design$design,
      group_col = inference$design$group_col,
      unit_col = inference$design$unit_col,
      pair_col = if (is.null(inference$design$pair_col)) NA_character_ else inference$design$pair_col,
      cluster_col = if (is.null(inference$design$cluster_col)) NA_character_ else inference$design$cluster_col,
      stringsAsFactors = FALSE
    ),
    metric = inference$metric,
    interpretation = inference$interpretation
  )
}

#' Plot sequence group inference
#'
#' @param inference A sequence group-inference object.
#' @param type `"permutation"` or `"group_means"`.
#' @param ... Additional base-graphics arguments.
#'
#' @return The inference object, invisibly.
#' @examples
#' # See `test_sequence_group_difference()`.
#' @export
plot_sequence_group_inference <- function(
  inference,
  type = c("permutation", "group_means"),
  ...
) {
  if (!inherits(inference, "gp3_sequence_group_inference")) {
    stop("`inference` must be created by `test_sequence_group_difference()`.",
         call. = FALSE)
  }
  type <- match.arg(type)
  if (type == "permutation") {
    observed <- inference$estimate$difference_group_2_minus_group_1
    graphics::hist(inference$permutation_distribution,
                   xlab = "Permuted mean difference", main = "Permutation distribution", ...)
    graphics::abline(v = observed, lwd = 2, lty = 2)
  } else {
    means <- c(inference$estimate$mean_group_1,
               inference$estimate$mean_group_2)
    names(means) <- c(inference$estimate$group_1, inference$estimate$group_2)
    graphics::barplot(means, ylab = inference$metric, ...)
  }
  invisible(inference)
}
