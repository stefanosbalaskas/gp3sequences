test_that("package namespace is available", {
  expect_true(isNamespaceLoaded("gp3sequences"))
  expect_identical(
    environmentName(asNamespace("gp3sequences")),
    "gp3sequences"
  )
})
