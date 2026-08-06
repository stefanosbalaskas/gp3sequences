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

target <- file.path(article_dir, "results", "session-info.txt")

lines <- capture.output(
  sessionInfo()
)

writeLines(lines, target, useBytes = TRUE)

cat("PASS: refreshed manuscript session information.\n")
