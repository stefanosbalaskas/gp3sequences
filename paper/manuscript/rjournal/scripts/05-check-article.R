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

if (!requireNamespace("rjtools", quietly = TRUE)) {
  stop("Install rjtools before running journal checks.", call. = FALSE)
}

tex_path <- file.path(article_dir, "gp3sequences.tex")

if (!file.exists(tex_path)) {
  stop(
    "Render gp3sequences.Rmd before running rjtools checks.",
    call. = FALSE
  )
}

rjtools::initial_check_article(
  path = article_dir,
  pkg = "gp3sequences",
  ask = FALSE
)

cat("PASS: completed rjtools initial article checks.\n")
