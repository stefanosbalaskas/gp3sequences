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

copy_into_build <- function(source, build_dir) {
  copied <- file.copy(
    source,
    build_dir,
    recursive = dir.exists(source),
    copy.mode = TRUE,
    copy.date = TRUE
  )

  if (!isTRUE(copied)) {
    stop(
      paste0("Could not copy manuscript source into build: ", source),
      call. = FALSE
    )
  }
}

root <- find_repo_root()
article_dir <- file.path(root, "paper", "manuscript", "rjournal")
build_dir <- file.path(article_dir, "build")

required_packages <- c("rjtools", "rmarkdown", "knitr", "callr")
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

required_system <- c(
  rmarkdown::pandoc_available(),
  nzchar(Sys.which("pdflatex")) ||
    requireNamespace("tinytex", quietly = TRUE)
)

if (!all(required_system)) {
  stop(
    paste(
      "Rendering requires Pandoc and a working LaTeX installation.",
      "RStudio Pandoc is acceptable; TinyTeX or another TeX distribution",
      "must provide PDF compilation."
    ),
    call. = FALSE
  )
}

source_items <- file.path(article_dir, c(
  "gp3sequences.Rmd",
  "gp3sequences.bib",
  "Rjournal.sty",
  "data",
  "figures",
  "results",
  "scripts",
  "motivation-letter"
))

missing_items <- source_items[!file.exists(source_items)]

if (length(missing_items) > 0L) {
  stop(
    paste(
      "Missing manuscript build inputs:",
      paste(missing_items, collapse = ", ")
    ),
    call. = FALSE
  )
}

unlink(build_dir, recursive = TRUE, force = TRUE)
dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)

for (source in source_items) {
  copy_into_build(source, build_dir)
}

# Use a literal ISO date in the build copy. The date can be overridden for
# the actual submission using RJOURNAL_SUBMISSION_DATE=YYYY-MM-DD.
build_date <- Sys.getenv(
  "RJOURNAL_SUBMISSION_DATE",
  unset = format(Sys.Date(), "%Y-%m-%d")
)

if (is.na(as.Date(build_date, format = "%Y-%m-%d"))) {
  stop(
    "RJOURNAL_SUBMISSION_DATE must use YYYY-MM-DD.",
    call. = FALSE
  )
}

build_rmd <- file.path(build_dir, "gp3sequences.Rmd")
rmd_lines <- readLines(build_rmd, warn = FALSE, encoding = "UTF-8")
date_index <- grep("^date:", rmd_lines)

if (length(date_index) != 1L) {
  stop("The manuscript must contain exactly one YAML date.", call. = FALSE)
}

rmd_lines[date_index] <- paste0('date: "', build_date, '"')
writeLines(rmd_lines, build_rmd, useBytes = TRUE)

render_result <- callr::r(
  function(build_dir) {
    setwd(build_dir)

    rendered <- rmarkdown::render(
      "gp3sequences.Rmd",
      output_format = "all",
      envir = new.env(parent = globalenv()),
      clean = TRUE,
      quiet = FALSE
    )

    master_r <- file.path(build_dir, "gp3sequences.R")

    if (!file.exists(master_r)) {
      knitr::purl(
        "gp3sequences.Rmd",
        output = master_r,
        documentation = 0L,
        quiet = TRUE
      )
    }

    list(
      rendered = rendered,
      r_version = R.version.string,
      rjtools_version = as.character(utils::packageVersion("rjtools")),
      rmarkdown_version = as.character(utils::packageVersion("rmarkdown")),
      pandoc_version = as.character(rmarkdown::pandoc_version())
    )
  },
  args = list(build_dir = normalizePath(
    build_dir,
    winslash = "/",
    mustWork = TRUE
  )),
  show = TRUE,
  spinner = FALSE
)

required_outputs <- file.path(build_dir, c(
  "gp3sequences.pdf",
  "gp3sequences.html",
  "gp3sequences.tex",
  "gp3sequences.R"
))

missing_outputs <- required_outputs[!file.exists(required_outputs)]

if (length(missing_outputs) > 0L) {
  stop(
    paste(
      "Rendering did not create required article products:",
      paste(basename(missing_outputs), collapse = ", ")
    ),
    call. = FALSE
  )
}

output_info <- file.info(required_outputs)

stopifnot(
  all(output_info$size > 0L),
  file.exists(file.path(build_dir, "gp3sequences.bib")),
  file.exists(file.path(build_dir, "Rjournal.sty")),
  dir.exists(file.path(build_dir, "motivation-letter"))
)

render_summary <- data.frame(
  output = basename(required_outputs),
  bytes = as.numeric(output_info$size),
  md5 = unname(tools::md5sum(required_outputs)),
  build_date = build_date,
  source_commit = system2(
    "git",
    c("-C", root, "rev-parse", "HEAD"),
    stdout = TRUE
  )[1L],
  r_version = render_result$r_version,
  rjtools_version = render_result$rjtools_version,
  rmarkdown_version = render_result$rmarkdown_version,
  pandoc_version = render_result$pandoc_version,
  stringsAsFactors = FALSE
)

evidence_dir <- file.path(build_dir, "evidence")
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

utils::write.csv(
  render_summary,
  file.path(evidence_dir, "render-summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

cat(
  "PASS: rendered the actual R Journal article.\n",
  "PDF: ", normalizePath(required_outputs[1L], winslash = "/"), "\n",
  "HTML: ", normalizePath(required_outputs[2L], winslash = "/"), "\n",
  "TeX: ", normalizePath(required_outputs[3L], winslash = "/"), "\n",
  "Master R: ", normalizePath(required_outputs[4L], winslash = "/"), "\n",
  "Build date: ", build_date, "\n",
  sep = ""
)
