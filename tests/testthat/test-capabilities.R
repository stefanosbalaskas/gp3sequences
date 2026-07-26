
test_that("sequence_capabilities is deterministic and dependency-safe", {
  first <- sequence_capabilities()
  second <- sequence_capabilities()

  expect_s3_class(
    first,
    "data.frame"
  )

  expect_identical(
    first,
    second
  )

  expect_true(
    all(
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
      ) %in% names(first)
    )
  )

  expect_true(
    any(first$role == "native")
  )

  expect_true(
    any(first$role == "reference")
  )

  expect_true(
    all(first$available %in% c(TRUE, FALSE))
  )
})

test_that("sequence_capabilities can report native capabilities only", {
  native <- sequence_capabilities(
    include_optional = FALSE
  )

  expect_true(
    nrow(native) > 0L
  )

  expect_true(
    all(native$role == "native")
  )

  expect_true(
    all(native$native)
  )
})

test_that("sequence_capabilities does not load optional backend namespaces", {
  optional_backends <- c(
    "TraMineR",
    "stringdist",
    "cluster",
    "WeightedCluster",
    "clusterCrit",
    "clue",
    "arulesSequences",
    "GrpString",
    "seqHMM",
    "igraph",
    "markovchain",
    "TraMineRextras",
    "vegan",
    "energy",
    "coin",
    "seqimpute",
    "MEDseq",
    "ggseqplot",
    "seriation",
    "quickcheck",
    "hedgehog",
    "bench",
    "microbenchmark"
  )

  before <- loadedNamespaces()

  result <- sequence_capabilities()

  after <- loadedNamespaces()

  newly_loaded_optional <- setdiff(
    intersect(
      after,
      optional_backends
    ),
    intersect(
      before,
      optional_backends
    )
  )

  expect_s3_class(
    result,
    "data.frame"
  )

  expect_identical(
    newly_loaded_optional,
    character()
  )
})
