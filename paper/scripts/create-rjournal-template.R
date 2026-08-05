setwd("C:/Users/Stefanos-PC/Documents/Rstudio/gp3sequences")

if (!requireNamespace("rjtools", quietly = TRUE)) {
  stop("Install rjtools from CRAN first.", call. = FALSE)
}
dir.create("paper/manuscript", recursive = TRUE, showWarnings = FALSE)
old <- setwd("paper/manuscript")
on.exit(setwd(old), add = TRUE)
rjtools::create_article(
  name = "balaskas-gp3sequences",
  file = "balaskas-gp3sequences.Rmd",
  create_dir = FALSE,
  edit = FALSE
)
cat("PASS: R Journal template created in paper/manuscript.\n")
