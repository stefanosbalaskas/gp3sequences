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

required_packages <- c("rjtools", "rmarkdown", "knitr")
missing <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]

if (length(missing) > 0L) {
  stop(
    paste(
      "Install required manuscript packages:",
      paste(missing, collapse = ", ")
    ),
    call. = FALSE
  )
}

old_wd <- getwd()
setwd(article_dir)
on.exit(setwd(old_wd), add = TRUE)

rmarkdown::render(
  "gp3sequences.Rmd",
  output_format = "all",
  envir = new.env(parent = globalenv()),
  clean = TRUE
)

cat("PASS: rendered the R Journal article.\n")
