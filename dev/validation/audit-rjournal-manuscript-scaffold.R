setwd("C:/Users/Stefanos-PC/Documents/Rstudio/gp3sequences")

article_dir <- file.path("paper", "manuscript", "rjournal")

required <- file.path(article_dir, c(
  "README.md",
  "ARTICLE-STATUS.md",
  "gp3sequences.Rmd",
  "gp3sequences.bib",
  "Rjournal.sty",
  "data/software-comparison.csv",
  "data/package-inventory.csv",
  "data/case-study-sequences.csv",
  "data/case-study-data-dictionary.csv",
  "data/case-study-workflow.csv",
  "figures/README.md",
  "results/README.md",
  "motivation-letter/motivation-letter.md",
  "scripts/01-build-comparison-data.R",
  "scripts/02-build-case-study-data.R",
  "scripts/03-refresh-session-info.R",
  "scripts/04-render-article.R",
  "scripts/05-check-article.R",
  "scripts/07-render-and-check-article.R"
))

missing <- required[!file.exists(required)]
stopifnot(length(missing) == 0L)

scripts <- list.files(
  file.path(article_dir, "scripts"),
  pattern = "\\.R$",
  full.names = TRUE
)

for (script in scripts) {
  parse(script, keep.source = TRUE)
}

rmd_path <- file.path(article_dir, "gp3sequences.Rmd")
rmd <- readLines(rmd_path, warn = FALSE, encoding = "UTF-8")

required_sections <- c(
  "# Introduction",
  "# Design goals and scope",
  "# Package architecture",
  "# Integrated workflow",
  "# Software comparison",
  "# Reproducible case study",
  "# Discussion",
  "# Limitations",
  "# Reproducibility statement",
  "# Acknowledgements"
)

stopifnot(
  any(grepl("^title: \"gp3sequences:", rmd)),
  any(rmd == "  rjtools::rjournal_article:"),
  any(rmd == "bibliography: gp3sequences.bib"),
  all(required_sections %in% rmd)
)

abstract_start <- which(rmd == "abstract: >")
author_start <- which(rmd == "author:")

stopifnot(
  length(abstract_start) == 1L,
  length(author_start) == 1L,
  author_start > abstract_start
)

abstract_lines <- rmd[seq.int(abstract_start + 1L, author_start - 1L)]
abstract_text <- paste(trimws(abstract_lines), collapse = " ")
abstract_words <- strsplit(abstract_text, "[[:space:]]+")[[1L]]
abstract_words <- abstract_words[nzchar(abstract_words)]

stopifnot(
  length(abstract_words) <= 250L,
  !grepl("@", abstract_text, fixed = TRUE),
  !grepl("$", abstract_text, fixed = TRUE),
  !grepl("\\\\pkg", abstract_text)
)

comparison <- read.csv(
  file.path(article_dir, "data", "software-comparison.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

case_data <- read.csv(
  file.path(article_dir, "data", "case-study-sequences.csv"),
  stringsAsFactors = FALSE
)

workflow <- read.csv(
  file.path(article_dir, "data", "case-study-workflow.csv"),
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(comparison) == 8L,
  nrow(case_data) == 1728L,
  length(unique(case_data$sequence_id)) == 72L,
  setequal(unique(case_data$position), 1:24),
  setequal(unique(case_data$state), c("A", "B", "C", "D")),
  setequal(unique(case_data$group), c("reference", "comparison")),
  nrow(workflow) == 9L
)

bib <- readLines(file.path(article_dir, "gp3sequences.bib"), warn = FALSE)
bib_entries <- sum(grepl("^@", bib))
stopifnot(bib_entries >= 8L)

namespace <- readLines("NAMESPACE", warn = FALSE)
exports <- sum(grepl("^export\\(", namespace))
stopifnot(exports == 81L)

rbuildignore <- readLines(".Rbuildignore", warn = FALSE)
stopifnot(any(rbuildignore == "^paper$"))

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
  generated_outputs <- generated_outputs[
    !startsWith(generated_relative, "build/")
  ]
}

stopifnot(length(generated_outputs) == 0L)

git_status <- system2(
  "git",
  c("status", "--porcelain=v1", "-uall"),
  stdout = TRUE,
  stderr = TRUE
)

status_paths <- if (length(git_status) > 0L) {
  trimws(sub("^..", "", git_status))
} else {
  character()
}

forbidden <- grepl(
  "^(R/|man/|tests/|NAMESPACE$|DESCRIPTION$)",
  status_paths
)

stopifnot(!any(forbidden))

cat(
  "PASS: R Journal manuscript scaffold is structurally complete.\n",
  "Article: gp3sequences.Rmd\n",
  "Sections: ", length(required_sections), "\n",
  "Abstract words: ", length(abstract_words), "\n",
  "Bibliography entries: ", bib_entries, "\n",
  "Comparator rows: ", nrow(comparison), "\n",
  "Case-study rows: ", nrow(case_data), "\n",
  "Public API changes: none\n",
  sep = ""
)
