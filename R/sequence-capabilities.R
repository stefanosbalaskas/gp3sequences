
#' Report gp3sequences capabilities and optional integrations
#'
#' Returns a deterministic, machine-readable inventory of native analytical
#' capabilities, optional adapters, reference implementations, and specialist
#' handoffs relevant to the current gp3sequences development series.
#'
#' @param include_optional Logical; include optional/reference capabilities.
#' @param check_versions Logical; report installed optional-package versions.
#'
#' @return A data frame with capability family, capability, implementation role,
#' backend, availability, and version information. The function never installs,
#' attaches, or loads optional packages.
#'
#' @examples
#' capabilities <- sequence_capabilities()
#' capabilities[c("family", "capability", "role", "available")]
#'
#' @export
sequence_capabilities <- function(
  include_optional = TRUE,
  check_versions = TRUE
) {
  if (
    !is.logical(include_optional) ||
      length(include_optional) != 1L ||
      is.na(include_optional)
  ) {
    stop(
      "`include_optional` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  if (
    !is.logical(check_versions) ||
      length(check_versions) != 1L ||
      is.na(check_versions)
  ) {
    stop(
      "`check_versions` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  rows <- data.frame(
    family = c(
      "Data contract",
      "Distances",
      "Distances",
      "Clustering",
      "Patterns",
      "Patterns",
      "HMMs",
      "HMMs",
      "Networks",
      "Networks",
      "Networks",
      "Inference",
      "Missingness",
      "Model-based clustering",
      "Graphics",
      "Graphics",
      "Property testing",
      "Performance"
    ),
    capability = c(
      "Validation and preparation",
      "Native sequence distances",
      "Reference distance validation",
      "Native clustering and stability",
      "Frequent pattern reference validation",
      "String/AOI pattern interoperability",
      "Native categorical HMMs",
      "HMM reference validation",
      "Native transition networks",
      "Graph interoperability",
      "Markov-chain interoperability",
      "Permutation/distance reference validation",
      "Sequence-imputation handoff",
      "Specialist model-based clustering handoff",
      "Sequence-plot handoff",
      "Seriation/ordering handoff",
      "Property-based testing",
      "Benchmarking"
    ),
    role = c(
      "native",
      "native",
      "reference",
      "native",
      "reference",
      "adapter",
      "native",
      "reference",
      "native",
      "adapter",
      "planned_adapter",
      "reference",
      "handoff",
      "handoff",
      "handoff",
      "handoff",
      "development",
      "development"
    ),
    backend = c(
      NA,
      NA,
      "TraMineR|stringdist",
      "cluster|WeightedCluster|clusterCrit|clue",
      "TraMineR|arulesSequences",
      "GrpString",
      NA,
      "seqHMM",
      NA,
      "igraph",
      "markovchain",
      "TraMineRextras|vegan|energy|coin",
      "seqimpute",
      "MEDseq",
      "ggseqplot",
      "seriation",
      "quickcheck|hedgehog",
      "bench|microbenchmark"
    ),
    reference_only = c(
      FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE, TRUE, FALSE,
      FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
    ),
    stringsAsFactors = FALSE
  )

  package_groups <- lapply(
    rows$backend,
    function(value) {
      if (is.na(value)) {
        return(character())
      }

      strsplit(
        value,
        "\\|"
      )[[1L]]
    }
  )

  installed <- utils::installed.packages(
    fields = "Version"
  )

  installed_names <- rownames(installed)

  rows$available <- vapply(
    package_groups,
    function(packages) {
      if (length(packages) == 0L) {
        return(TRUE)
      }

      all(
        packages %in% installed_names
      )
    },
    logical(1)
  )

  rows$installed_version <- vapply(
    package_groups,
    function(packages) {
      if (
        !check_versions ||
          length(packages) == 0L
      ) {
        return(NA_character_)
      }

      versions <- vapply(
        packages,
        function(package) {
          if (package %in% installed_names) {
            paste0(
              package,
              " ",
              installed[
                package,
                "Version"
              ]
            )
          } else {
            paste0(
              package,
              " <not installed>"
            )
          }
        },
        character(1)
      )

      paste(
        versions,
        collapse = "; "
      )
    },
    character(1)
  )

  rows$native <- rows$role == "native"

  rows$backend_required <- rows$role %in% c(
    "adapter",
    "planned_adapter"
  )

  rows$minimum_tested_version <- NA_character_

  rows$notes <- ifelse(
    rows$role == "native",
    "Available without the optional backend.",
    paste0(
      "Optional integration, reference validation, development QA, ",
      "or documented handoff."
    )
  )

  if (!include_optional) {
    rows <- rows[
      rows$role == "native",
      ,
      drop = FALSE
    ]
  }

  rows <- rows[
    order(
      rows$family,
      rows$capability,
      rows$role,
      method = "radix"
    ),
    c(
      "family",
      "capability",
      "role",
      "native",
      "backend",
      "backend_required",
      "available",
      "installed_version",
      "minimum_tested_version",
      "reference_only",
      "notes"
    ),
    drop = FALSE
  ]

  row.names(rows) <- NULL

  rows
}
