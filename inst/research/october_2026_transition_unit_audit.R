# Source-only October 2026 sensitivity example, not an exported package API.
# The same transitions are summarized under two different observational units.
gp3sequences_october_transition_data <- function(seed = 20261022L) {
  set.seed(seed)
  participants <- sprintf("P%02d", seq_len(16L))
  n <- c(160L, rep(12L, 15L))
  id <- rep(participants, times = n)
  p <- rep(c(0.92, rep(0.25, 15L)), times = n)
  data.frame(participant_id = id, to_target = stats::rbinom(length(p), 1L, p),
             stringsAsFactors = FALSE)
}

gp3sequences_october_transition_audit <- function(x) {
  stopifnot(is.data.frame(x),
            all(c("participant_id", "to_target") %in% names(x)),
            !anyNA(x$participant_id), !anyNA(x$to_target),
            all(x$to_target %in% c(0, 1)))
  split_x <- split(x$to_target, x$participant_id)
  person <- data.frame(participant_id = names(split_x),
                       n = lengths(split_x),
                       participant_rate = vapply(split_x, mean, numeric(1)))
  summary <- data.frame(
    estimand = c("transition-weighted", "participant-equal"),
    estimate = c(mean(x$to_target), mean(person$participant_rate)),
    independent_participants = nrow(person),
    observed_transitions = nrow(x),
    stringsAsFactors = FALSE)
  list(summary = summary, participant = person)
}

gp3sequences_october_transition_plot <- function(audit) {
  stopifnot(is.list(audit), all(c("summary", "participant") %in% names(audit)))
  op <- graphics::par(mfrow = c(1L, 2L), mar = c(5, 4, 3, 1))
  on.exit(graphics::par(op), add = TRUE)
  graphics::barplot(audit$summary$estimate,
                    names.arg = c("All transitions", "Equal participants"),
                    ylim = c(0, 1), las = 1, ylab = "Target-transition fraction",
                    main = "Two different estimands",
                    col = c("#C7DCEC", "#EAD7CD"), border = "#53677A")
  graphics::plot(audit$participant$n, audit$participant$participant_rate,
                 pch = 19, xlab = "Transitions per participant",
                 ylab = "Within-participant target fraction",
                 main = "Participant contribution", ylim = c(0, 1),
                 col = "#24577B")
  graphics::abline(h = mean(audit$participant$participant_rate),
                   lty = 2, col = "#C05B43")
  invisible(audit)
}
