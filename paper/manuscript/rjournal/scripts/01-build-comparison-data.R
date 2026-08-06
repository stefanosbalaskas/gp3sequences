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

source_path <- file.path(root, "paper", "results", "manuscript-comparison-table.csv")
target_path <- file.path(article_dir, "data", "software-comparison.csv")

comparison <- read.csv(
  source_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

stopifnot(
  nrow(comparison) == 8L,
  "Package" %in% names(comparison),
  setequal(
    comparison$Package,
    c(
      "gp3sequences", "TraMineR", "seqHMM", "arulesSequences",
      "WeightedCluster", "ClickClust", "PST", "march"
    )
  )
)

write.csv(
  comparison,
  target_path,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

cat("PASS: refreshed manuscript software-comparison data.\n")
