testthat::test_that("participant transition weighting is transparent and deterministic", {
  f <- system.file("research", "october_2026_transition_unit_audit.R",
                   package = "gp3sequences")
  testthat::expect_true(nzchar(f))
  scope <- new.env(parent = baseenv())
  sys.source(f, envir = scope)
  dat <- scope$gp3sequences_october_transition_data()
  audit <- scope$gp3sequences_october_transition_audit(dat)
  testthat::expect_equal(nrow(dat), 340L)
  testthat::expect_equal(nrow(audit$participant), 16L)
  testthat::expect_equal(audit$summary$independent_participants, c(16L, 16L))
  testthat::expect_gt(audit$summary$estimate[1L],
                      audit$summary$estimate[2L])
  testthat::expect_identical(dat, scope$gp3sequences_october_transition_data())
  testthat::expect_error(scope$gp3sequences_october_transition_audit(
    data.frame(participant_id = "x", to_target = NA_real_)))
})
