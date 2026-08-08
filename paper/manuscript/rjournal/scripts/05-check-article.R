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

result_row <- function(result, test) {
  info <- attr(result, "info")
  data.frame(
    status = as.character(result),
    test = test,
    message = if (!is.null(info$message)) {
      as.character(info$message)
    } else {
      NA_character_
    },
    stringsAsFactors = FALSE
  )
}

root <- find_repo_root()
article_dir <- file.path(root, "paper", "manuscript", "rjournal")
build_dir <- file.path(article_dir, "build")
evidence_dir <- file.path(build_dir, "evidence")
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("rjtools", quietly = TRUE)) {
  stop("Install rjtools before running journal checks.", call. = FALSE)
}

build_dir_abs <- normalizePath(
  build_dir,
  winslash = "/",
  mustWork = TRUE
)

required <- file.path(build_dir_abs, c(
  "gp3sequences.Rmd",
  "gp3sequences.bib",
  "gp3sequences.tex",
  "gp3sequences.R",
  "gp3sequences.pdf",
  "gp3sequences.html"
))

missing <- required[!file.exists(required)]
if (length(missing) > 0L) {
  stop(
    paste("Missing rendered article files:", paste(basename(missing), collapse = ", ")),
    call. = FALSE
  )
}

# Remove only transient LaTeX products that the official structure check
# explicitly asks authors to remove before submission.
transient <- list.files(
  build_dir_abs,
  pattern = "\\.(log|aux|out)$",
  full.names = TRUE,
  recursive = FALSE,
  ignore.case = TRUE
)
if (length(transient) > 0L) unlink(transient, force = TRUE)

old_wd <- getwd()
setwd(build_dir_abs)
on.exit(setwd(old_wd), add = TRUE)

logfile <- file.path(evidence_dir, "initial_checks.log")
if (file.exists(logfile)) unlink(logfile, force = TRUE)

old_file <- getOption("check.log.file")
old_journal <- getOption("check.log.journal")
old_output <- getOption("check.log.output")
on.exit(options(
  check.log.file = old_file,
  check.log.journal = old_journal,
  check.log.output = old_output
), add = TRUE)

journal <- new.env(parent = emptyenv())
options(
  check.log.file = logfile,
  check.log.journal = journal,
  check.log.output = "cli"
)

# The two CRAN-availability checks require a concrete repository URL.
# Rscript --vanilla may expose the unresolved @CRAN@ placeholder.
# Scope any temporary mirror configuration to the individual check so
# the caller's repository options are restored even when that check fails.
with_cran_repo <- function(fun, ...) {
  old_repos <- getOption("repos")
  on.exit(options(repos = old_repos), add = TRUE)

  check_repos <- old_repos

  if (is.null(check_repos) || length(check_repos) == 0L) {
    check_repos <- c(CRAN = "https://cloud.r-project.org")
  } else if (is.null(names(check_repos)) || !"CRAN" %in% names(check_repos)) {
    check_repos <- c(
      CRAN = "https://cloud.r-project.org",
      check_repos
    )
  } else if (
    is.na(check_repos[["CRAN"]]) ||
    !nzchar(check_repos[["CRAN"]]) ||
    identical(check_repos[["CRAN"]], "@CRAN@")
  ) {
    check_repos[["CRAN"]] <- "https://cloud.r-project.org"
  }

  options(repos = check_repos)
  fun(...)
}

checks <- list(
  check_filenames = function() rjtools::check_filenames(build_dir_abs),
  check_structure = function() rjtools::check_structure(build_dir_abs),
  check_folder_structure = function() rjtools::check_folder_structure(build_dir_abs),
  check_unnecessary_files = function() rjtools::check_unnecessary_files(build_dir_abs),
  check_cover_letter = function() rjtools::check_cover_letter(build_dir_abs),
  check_title = function() rjtools::check_title(
    build_dir_abs,
    ignore = "gp3sequences"
  ),
  check_section = function() rjtools::check_section(build_dir_abs),
  check_abstract = function() rjtools::check_abstract(build_dir_abs),
  check_spelling = function() rjtools::check_spelling(
    build_dir_abs,
    dic = "en_US"
  ),
  check_proposed_pkg = function() with_cran_repo(
    rjtools::check_proposed_pkg,
    "gp3sequences",
    ask = FALSE
  ),
  check_pkg_label = function() rjtools::check_pkg_label(build_dir_abs),
  check_packages_available = function() with_cran_repo(
    rjtools::check_packages_available,
    build_dir_abs,
    ignore = "gp3sequences"
  ),
  check_bib_doi = function() rjtools::check_bib_doi(build_dir_abs),
  check_csl = function() rjtools::check_csl(build_dir_abs)
)

results <- Map(
  function(fun, name) result_row(fun(), name),
  checks,
  names(checks)
)

# rjtools 1.0.21 check_date() lists the Rmd inside `path` but then passes
# only its basename to yaml_front_matter(). Use the same substantive rule
# with the full path to avoid that upstream path-resolution defect.
rmd_path <- file.path(build_dir_abs, "gp3sequences.Rmd")
yaml <- rmarkdown::yaml_front_matter(rmd_path)
article_date <- as.character(yaml$date)
expected_date <- format(Sys.Date(), "%Y-%m-%d")

date_status <- if (
  length(article_date) == 1L &&
  !is.na(as.Date(article_date, format = "%Y-%m-%d")) &&
  identical(article_date, expected_date)
) {
  "SUCCESS"
} else {
  "ERROR"
}

date_message <- if (identical(date_status, "SUCCESS")) {
  "Article date is fixed in YYYY-MM-DD format and matches the check date."
} else {
  paste0(
    "Article date must be fixed in YYYY-MM-DD format and match the check date. ",
    "Observed: ", paste(article_date, collapse = ", "),
    "; expected: ", expected_date, "."
  )
}

date_result <- data.frame(
  status = date_status,
  test = "check_date_path_safe",
  message = date_message,
  stringsAsFactors = FALSE
)

if (identical(date_status, "SUCCESS")) {
  cli::cli_alert_success(date_message)
} else {
  cli::cli_alert_danger(date_message)
}

check_details <- do.call(rbind, c(results, list(date_result)))
row.names(check_details) <- NULL

# Official R Journal tooling currently reports Rjournal.sty as a non-standard
# root file even though the official article template creates it and the
# submission guidance requires .sty source files needed to rebuild.
style_warning <-
  check_details$status == "WARNING" &
  grepl(
    "Rjournal\\.sty",
    check_details$message,
    ignore.case = FALSE,
    perl = TRUE
  ) &
  grepl(
    "non-standard file",
    check_details$message,
    ignore.case = TRUE,
    perl = TRUE
  )

check_details$accepted_exception <- style_warning
check_details$exception_reason <- ifelse(
  style_warning,
  paste(
    "Official R Journal template/source requirement:",
    "Rjournal.sty retained unchanged for reproducible PDF rebuilding."
  ),
  ""
)

status_levels <- c("SUCCESS", "NOTE", "WARNING", "ERROR")
status_counts <- table(factor(check_details$status, levels = status_levels))
accepted_warnings <- sum(
  check_details$status == "WARNING" & check_details$accepted_exception
)
unresolved_warnings <- sum(
  check_details$status == "WARNING" & !check_details$accepted_exception
)

pdf_pages <- NA_integer_
pdf_path <- file.path(build_dir_abs, "gp3sequences.pdf")

if (requireNamespace("qpdf", quietly = TRUE)) {
  pdf_pages <- qpdf::pdf_length(pdf_path)
} else if (requireNamespace("pdftools", quietly = TRUE)) {
  pdf_pages <- pdftools::pdf_info(pdf_path)$pages
}

check_summary <- data.frame(
  successes = unname(status_counts[["SUCCESS"]]),
  notes = unname(status_counts[["NOTE"]]),
  warnings = unname(status_counts[["WARNING"]]),
  accepted_warnings = accepted_warnings,
  unresolved_warnings = unresolved_warnings,
  errors = unname(status_counts[["ERROR"]]),
  pdf_pages = pdf_pages,
  checked_on = expected_date,
  rjtools_version = as.character(utils::packageVersion("rjtools")),
  date_check = "path-safe equivalent of rjtools::check_date()",
  stringsAsFactors = FALSE
)

utils::write.csv(
  check_details,
  file.path(evidence_dir, "rjtools-check-results.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

utils::write.csv(
  check_summary,
  file.path(evidence_dir, "rjtools-check-summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

cat(
  "R Journal checks completed with path-safe date verification.\n",
  "Successes: ", check_summary$successes, "\n",
  "Notes: ", check_summary$notes, "\n",
  "Warnings: ", check_summary$warnings, "\n",
  "Accepted template warnings: ", check_summary$accepted_warnings, "\n",
  "Unresolved warnings: ", check_summary$unresolved_warnings, "\n",
  "Errors: ", check_summary$errors, "\n",
  "PDF pages: ",
  ifelse(is.na(pdf_pages), "not measured", pdf_pages),
  "\n",
  sep = ""
)

if (!is.na(pdf_pages) && pdf_pages > 20L) {
  stop(
    paste0(
      "The rendered article has ", pdf_pages,
      " pages; the R Journal limit is 20."
    ),
    call. = FALSE
  )
}

if (check_summary$errors > 0L) {
  stop(
    paste0(
      "R Journal checks reported ", check_summary$errors,
      " error(s). Review build/evidence/rjtools-check-results.csv."
    ),
    call. = FALSE
  )
}

if (check_summary$unresolved_warnings > 0L) {
  stop(
    paste0(
      "R Journal checks reported ", check_summary$unresolved_warnings,
      " unresolved warning(s). Review build/evidence/rjtools-check-results.csv."
    ),
    call. = FALSE
  )
}

cat("PASS: R Journal automated checks contain zero errors and zero unresolved warnings.\n")
