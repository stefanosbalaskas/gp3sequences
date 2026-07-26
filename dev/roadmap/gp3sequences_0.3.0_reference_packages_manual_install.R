# gp3sequences 0.3.0 reference + QA environment
# This file intentionally DOES NOT install anything automatically.
# Review the vectors, then manually run the commented install.packages() calls.

reference_packages <- c(
  "TraMineR", "TraMineRextras", "WeightedCluster",
  "cluster", "clusterCrit", "clue", "stringdist",
  "arules", "arulesSequences", "GrpString", "seqHMM",
  "igraph", "markovchain", "tna", "Nestimate",
  "seqimpute", "MEDseq", "seqhandbook", "ggseqplot", "seriation",
  "vegan", "energy", "coin"
)

qa_packages <- c(
  "quickcheck", "hedgehog", "bench", "microbenchmark",
  "covr", "waldo", "lintr", "cyclocomp"
)

local_comparison_only <- c("fpc")

all_requested <- unique(c(reference_packages, qa_packages, local_comparison_only))

status <- data.frame(
  package = all_requested,
  installed = vapply(all_requested, requireNamespace, logical(1), quietly = TRUE),
  version = vapply(
    all_requested,
    function(pkg) if (requireNamespace(pkg, quietly = TRUE)) as.character(utils::packageVersion(pkg)) else NA_character_,
    character(1)
  ),
  stringsAsFactors = FALSE
)

print(status, row.names = FALSE)

# MANUAL INSTALLATION — uncomment only after reviewing:
# install.packages(reference_packages)
# install.packages(qa_packages)
# install.packages(local_comparison_only)

# Re-run this file after installation to verify versions.
