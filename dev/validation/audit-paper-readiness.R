setwd("C:/Users/Stefanos-PC/Documents/Rstudio/gp3sequences")
required <- c(
  ".Rbuildignore", "paper/README.md", "paper/STATUS.md",
  "paper/manuscript-outline.md", "paper/abstract-draft.md",
  "paper/comparison-inventory.csv", "paper/feature-comparison-template.csv",
  "paper/benchmark-plan.csv", "paper/manuscript/references.bib",
  "paper/scripts/create-rjournal-template.R",
  "paper/scripts/build-package-inventory.R"
)
missing <- required[!file.exists(required)]
stopifnot(length(missing) == 0L)
stopifnot(any(readLines(".Rbuildignore", warn = FALSE) == "^paper$"))
description <- read.dcf("DESCRIPTION")
version <- unname(description[1L, "Version"])
exports <- sum(grepl("^export\\(", readLines("NAMESPACE", warn = FALSE)))
articles <- length(list.files("vignettes", pattern = "\\.Rmd$"))
comparison <- read.csv("paper/comparison-inventory.csv", stringsAsFactors = FALSE)
benchmarks <- read.csv("paper/benchmark-plan.csv", stringsAsFactors = FALSE)
stopifnot(
  nrow(comparison) >= 8L,
  all(c("TraMineR", "seqHMM", "arulesSequences", "ClickClust") %in% comparison$package),
  nrow(benchmarks) >= 8L,
  all(nzchar(benchmarks$benchmark_id))
)
cat(
  "PASS: paper workspace is structurally complete.\n",
  "Version: ", version, "\n",
  "Exports: ", exports, "\n",
  "Articles: ", articles, "\n",
  "CRAN 0.2.0 release gate: ", if (identical(version, "0.2.0")) "PASS" else "BLOCKED", "\n",
  sep = ""
)
