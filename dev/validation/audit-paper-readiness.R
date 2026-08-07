setwd("C:/Users/Stefanos-PC/Documents/Rstudio/gp3sequences")

required <- c(
  ".Rbuildignore",
  "paper/README.md",
  "paper/STATUS.md",
  "paper/manuscript-outline.md",
  "paper/abstract-draft.md",
  "paper/comparison-inventory.csv",
  "paper/feature-comparison-matrix.csv",
  "paper/comparator-source-registry.csv",
  "paper/comparator-classification-definitions.csv",
  "paper/results/manuscript-comparison-table.csv",
  "paper/manuscript/comparator-evidence.md",
  "paper/benchmark-plan.csv",
  "paper/manuscript/references.bib",
  "paper/scripts/create-rjournal-template.R",
  "paper/scripts/build-package-inventory.R",
  "dev/validation/audit-comparator-matrix.R"
)

missing <- required[!file.exists(required)]
stopifnot(length(missing) == 0L)

rbuildignore <- readLines(
  ".Rbuildignore",
  warn = FALSE,
  encoding = "UTF-8"
)

stopifnot(any(rbuildignore == "^paper$"))

description <- read.dcf("DESCRIPTION")
version <- unname(description[1L, "Version"])

namespace <- readLines(
  "NAMESPACE",
  warn = FALSE,
  encoding = "UTF-8"
)

exports <- sum(grepl("^export\\(", namespace))

articles <- length(list.files(
  "vignettes",
  pattern = "\\.Rmd$"
))

comparison <- read.csv(
  "paper/comparison-inventory.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

benchmarks <- read.csv(
  "paper/benchmark-plan.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

expected_packages <- c(
  "gp3sequences",
  "TraMineR",
  "seqHMM",
  "arulesSequences",
  "WeightedCluster",
  "ClickClust",
  "PST",
  "march"
)

stopifnot(
  nrow(comparison) == length(expected_packages),
  setequal(comparison$package, expected_packages),
  all(comparison$verification_status == "verified from primary sources"),
  nrow(benchmarks) >= 8L,
  all(nzchar(benchmarks$benchmark_id))
)

source("dev/validation/audit-comparator-matrix.R")
source("dev/validation/audit-rjournal-manuscript-scaffold.R")
source("dev/validation/audit-rjournal-render-workflow.R")
source("dev/validation/audit-rjournal-evaluated-case-study.R")

release_ready <- identical(version, "0.2.0")

cat(
  "PASS: paper workspace is structurally complete.\n",
  "Version: ", version, "\n",
  "Exports: ", exports, "\n",
  "Articles: ", articles, "\n",
  "CRAN 0.2.0 release gate: ",
  if (release_ready) "PASS" else "BLOCKED",
  "\n",
  sep = ""
)
