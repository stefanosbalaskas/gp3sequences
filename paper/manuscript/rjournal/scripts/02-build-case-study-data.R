find_repo_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (
      file.exists(file.path(current, "DESCRIPTION")) &&
      dir.exists(file.path(current, "paper"))
    ) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not locate the gp3sequences repository root.", call. = FALSE)
    }
    current <- parent
  }
}

root <- find_repo_root()
article_dir <- file.path(root, "paper", "manuscript", "rjournal")

n_sequences <- 72L
n_positions <- 24L
states <- c("A", "B", "C", "D")

case_data <- expand.grid(
  sequence_id = sprintf("S%03d", seq_len(n_sequences)),
  position = seq_len(n_positions),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)

sequence_number <- as.integer(sub("^S", "", case_data$sequence_id))
case_data$group <- ifelse(sequence_number %% 2L == 0L, "comparison", "reference")

reference_index <- (
  sequence_number +
    case_data$position +
    (case_data$position - 1L) %/% 6L
) %% length(states) + 1L

comparison_index <- (
  sequence_number +
    2L * case_data$position +
    2L * as.integer(case_data$position > 12L)
) %% length(states) + 1L

case_data$state <- states[ifelse(
  case_data$group == "reference",
  reference_index,
  comparison_index
)]
case_data$channel <- "primary"
case_data$weight <- 1

case_data <- case_data[, c(
  "sequence_id", "position", "state", "group", "channel", "weight"
)]

target <- file.path(article_dir, "data", "case-study-sequences.csv")

write.csv(
  case_data,
  target,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

stopifnot(
  nrow(case_data) == 1728L,
  length(unique(case_data$sequence_id)) == 72L,
  setequal(unique(case_data$state), states)
)

cat("PASS: rebuilt deterministic case-study data.\n")
