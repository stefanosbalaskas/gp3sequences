description <- read.dcf("DESCRIPTION")
version <- unname(description[1L, "Version"])

namespace <- readLines("NAMESPACE", warn = FALSE, encoding = "UTF-8")
export_count <- length(grep("^export\\(", namespace))

article_count <- length(
  list.files(
    "vignettes",
    pattern = "\\.Rmd$",
    full.names = TRUE
  )
)

read_text <- function(path) {
  paste(
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
}

rmd <- read_text("README.Rmd")
md <- read_text("README.md")
cff <- readLines("CITATION.cff", warn = FALSE, encoding = "UTF-8")
citation <- read_text("inst/CITATION")
pkgdown <- read_text("_pkgdown.yml")
cran <- read_text("cran-comments.md")

cff_version_line <- grep("^version:", cff, value = TRUE)
stopifnot(length(cff_version_line) == 1L)
cff_version <- sub(
  '^version:[[:space:]]*"([^"]+)"[[:space:]]*$',
  "\\1",
  cff_version_line
)

stopifnot(
  identical(cff_version, version),
  grepl(version, md, fixed = TRUE),
  grepl(paste0(export_count, " public[[:space:]]+functions"), md),
  grepl(paste0(article_count, " synthetic,[[:space:]]+reproducible articles"), md),
  !grepl("nine synthetic workflow articles", rmd, fixed = TRUE),
  !grepl("nine synthetic workflow articles", md, fixed = TRUE),
  !grepl('version: "0.1.0"', read_text("CITATION.cff"), fixed = TRUE),
  !grepl("R package version 0.1.0", citation, fixed = TRUE),
  grepl("meta$Version", citation, fixed = TRUE),
  grepl("Analysis contracts and provenance", pkgdown, fixed = TRUE),
  grepl("sequence_capabilities", pkgdown, fixed = TRUE),
  grepl("audit_sequence_analysis", pkgdown, fixed = TRUE),
  grepl("compare_sequence_analysis_results", pkgdown, fixed = TRUE),
  grepl("vignettes use synthetic data", cran, fixed = TRUE),
  grepl("\n## Encoding and structural summaries\n", md, fixed = TRUE),
  grepl("\n## Advanced sequence-analysis methods\n", md, fixed = TRUE),
  !grepl("\\## Encoding and", md, fixed = TRUE),
  !grepl("The 0.2.0 release established: -", md, fixed = TRUE),
  grepl("\n- aligned-position consensus sequences", md, fixed = TRUE)
)

cat(
  "PASS: documentation metadata is internally consistent.\n",
  "Version: ", version, "\n",
  "Exports: ", export_count, "\n",
  "Articles: ", article_count, "\n",
  sep = ""
)
