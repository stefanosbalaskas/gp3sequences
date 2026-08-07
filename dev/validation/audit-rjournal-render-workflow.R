setwd("C:/Users/Stefanos-PC/Documents/Rstudio/gp3sequences")

article_dir <- file.path("paper", "manuscript", "rjournal")
build_dir <- file.path(article_dir, "build")
results_dir <- file.path(article_dir, "results", "render")

required <- c(
  file.path(article_dir, "scripts", c(
    "04-render-article.R",
    "05-check-article.R",
    "07-render-and-check-article.R"
  )),
  file.path(results_dir, c(
    "README.md",
    "render-summary.csv",
    "rjtools-check-summary.csv",
    "rjtools-check-results.csv"
  ))
)

missing <- required[!file.exists(required)]
stopifnot(length(missing) == 0L)

for (script in required[grepl("\\.R$", required)]) {
  parse(script, keep.source = TRUE)
}

gitignore <- readLines(".gitignore", warn = FALSE, encoding = "UTF-8")
stopifnot("paper/manuscript/rjournal/build/" %in% gitignore)

rmd <- readLines(
  file.path(article_dir, "gp3sequences.Rmd"),
  warn = FALSE,
  encoding = "UTF-8"
)

stopifnot(
  any(rmd == 'date: "2026-08-07"'),
  any(grepl("evaluated-states, fig.alt=", rmd, fixed = TRUE)),
  any(grepl("evaluated-clustering, fig.alt=", rmd, fixed = TRUE)),
  any(grepl("evaluated-network-inference, fig.alt=", rmd, fixed = TRUE)),
  !any(rmd == "## Planned package analysis")
)

readme <- readLines(
  file.path(article_dir, "README.md"),
  warn = FALSE,
  encoding = "UTF-8"
)

stopifnot(
  !any(readme == "NA"),
  sum(readme == "analysis script used to generate the frozen outputs.") == 1L,
  any(readme == "## Local rendered paper")
)

render_summary <- read.csv(
  file.path(results_dir, "render-summary.csv"),
  stringsAsFactors = FALSE
)

check_summary <- read.csv(
  file.path(results_dir, "rjtools-check-summary.csv"),
  stringsAsFactors = FALSE
)

check_results <- read.csv(
  file.path(results_dir, "rjtools-check-results.csv"),
  stringsAsFactors = FALSE
)

required_summary_cols <- c(
  "successes", "notes", "warnings", "accepted_warnings",
  "unresolved_warnings", "errors", "pdf_pages"
)

required_result_cols <- c(
  "status", "test", "message", "accepted_exception", "exception_reason"
)

stopifnot(
  setequal(
    render_summary$output,
    c(
      "gp3sequences.pdf",
      "gp3sequences.html",
      "gp3sequences.tex",
      "gp3sequences.R"
    )
  ),
  all(render_summary$bytes > 0L),
  all(nzchar(render_summary$md5)),
  nrow(check_summary) == 1L,
  all(required_summary_cols %in% names(check_summary)),
  all(required_result_cols %in% names(check_results)),
  check_summary$successes == 13L,
  check_summary$notes == 1L,
  check_summary$warnings == 1L,
  check_summary$accepted_warnings == 1L,
  check_summary$unresolved_warnings == 0L,
  check_summary$errors == 0L,
  check_summary$pdf_pages == 13L,
  check_summary$pdf_pages <= 20L,
  nrow(check_results) == 15L,
  !any(check_results$status == "ERROR"),
  sum(check_results$status == "WARNING") == 1L,
  sum(check_results$accepted_exception) == 1L,
  all(
    check_results$accepted_exception[
      check_results$status == "WARNING"
    ]
  ),
  any(
    check_results$status == "WARNING" &
      check_results$accepted_exception &
      grepl("Rjournal\\.sty", check_results$message)
  ),
  any(check_results$test == "check_date_path_safe")
)

stopifnot(
  identical(
    unname(tools::md5sum(file.path(article_dir, "Rjournal.sty"))),
    unname(tools::md5sum(file.path(build_dir, "Rjournal.sty")))
  )
)

generated_outputs <- list.files(
  article_dir,
  pattern = "\\.(html|pdf|tex|log)$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)

if (length(generated_outputs) > 0L) {
  article_norm <- normalizePath(
    article_dir,
    winslash = "/",
    mustWork = TRUE
  )
  generated_relative <- substring(
    normalizePath(generated_outputs, winslash = "/", mustWork = TRUE),
    nchar(article_norm) + 2L
  )
  outside_build <- generated_relative[
    !startsWith(generated_relative, "build/")
  ]
  stopifnot(length(outside_build) == 0L)
}

required_local <- c(
  file.path(build_dir, c(
    "gp3sequences.pdf",
    "gp3sequences.html",
    "gp3sequences.tex",
    "gp3sequences.R"
  )),
  file.path(build_dir, "evidence", c(
    "render-summary.csv",
    "rjtools-check-summary.csv",
    "rjtools-check-results.csv"
  ))
)

stopifnot(
  all(file.exists(required_local)),
  all(file.info(required_local)$size > 0L)
)

cat(
  "PASS: R Journal render-and-check workflow is complete.\n",
  "Rendered products: ", nrow(render_summary), "\n",
  "R Journal successes: ", check_summary$successes, "\n",
  "Notes: ", check_summary$notes, "\n",
  "Raw warnings: ", check_summary$warnings, "\n",
  "Accepted template warnings: ", check_summary$accepted_warnings, "\n",
  "Unresolved warnings: ", check_summary$unresolved_warnings, "\n",
  "Errors: ", check_summary$errors, "\n",
  "PDF pages: ", check_summary$pdf_pages, "\n",
  "Public API changes: none\n",
  sep = ""
)
