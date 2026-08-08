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
build_dir <- file.path(article_dir, "build")

# Always rebuild from the current repository source.
# Reusing an earlier build can silently validate stale manuscript
# artefacts after the source, bibliography, or case study changes.
source(file.path(article_dir, "scripts", "04-render-article.R"))

source(file.path(article_dir, "scripts", "05-check-article.R"))

cat(
  "PASS: actual R Journal paper rendered and checked.\n",
  "Open the PDF at:\n",
  normalizePath(
    file.path(article_dir, "build", "gp3sequences.pdf"),
    winslash = "/",
    mustWork = TRUE
  ),
  "\n",
  sep = ""
)
