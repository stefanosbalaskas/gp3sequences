setwd("C:/Users/Stefanos-PC/Documents/Rstudio/gp3sequences")
description <- read.dcf("DESCRIPTION")
namespace <- readLines("NAMESPACE", warn = FALSE, encoding = "UTF-8")
inventory <- data.frame(
  metric = c("package", "version", "exports", "vignettes", "test_files", "license", "package_doi"),
  value = c(
    unname(description[1L, "Package"]),
    unname(description[1L, "Version"]),
    sum(grepl("^export\\(", namespace)),
    length(list.files("vignettes", pattern = "\\.Rmd$")),
    length(list.files("tests/testthat", pattern = "^test-.*\\.[Rr]$")),
    unname(description[1L, "License"]),
    "10.32614/CRAN.package.gp3sequences"
  ), stringsAsFactors = FALSE
)
dir.create("paper/results", recursive = TRUE, showWarnings = FALSE)
write.csv(inventory, "paper/results/package-inventory.csv", row.names = FALSE)
writeLines(capture.output(sessionInfo()), "paper/results/session-info.txt", useBytes = TRUE)
cat("PASS: package inventory and session information written.\n")
