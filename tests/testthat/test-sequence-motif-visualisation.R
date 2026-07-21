make_motif_visualisation_data <- function() {
  data.frame(
    id = c(
      rep("s1", 5L),
      rep("s2", 4L),
      rep("s3", 3L)
    ),
    position = c(1:5, 1:4, 1:3),
    state = c(
      "A", "B", "A", "B", "C",
      "A", "B", "C", "B",
      "B", "A", "B"
    ),
    group = c(
      rep("g1", 5L),
      rep("g1", 4L),
      rep("g2", 3L)
    ),
    stringsAsFactors = FALSE
  )
}

make_motif_visualisation_extraction <- function(
  min_length = 2L,
  max_length = 3L
) {
  extract_sequence_ngrams(
    make_motif_visualisation_data(),
    sequence_id_col = "id",
    order_col = "position",
    state_col = "state",
    metadata_cols = "group",
    min_length = min_length,
    max_length = max_length,
    overlap = "allow"
  )
}

capture_motif_plot <- function(expression) {
  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  on.exit(grDevices::dev.off(), add = TRUE)

  value <- eval.parent(substitute(expression))

  list(
    value = value,
    path = path
  )
}

test_that("absolute motif positions are summarised exactly", {
  extracted <- make_motif_visualisation_extraction()

  result <- summarise_sequence_motif_positions(
    extracted,
    position = "start",
    scale = "absolute"
  )

  expect_identical(result$status, "pass")
  expect_identical(result$settings$position, "start")
  expect_identical(result$settings$scale, "absolute")
  expect_identical(result$settings$by, character())
  expect_equal(nrow(result$occurrences), nrow(extracted$occurrences))

  ab <- result$summary[
    result$summary$motif == "A > B",
    ,
    drop = FALSE
  ]

  expect_equal(nrow(ab), 1L)
  expect_identical(ab$n_occurrences, 4L)
  expect_identical(ab$n_sequences, 3L)
  expect_equal(ab$min_position, 1)
  expect_equal(ab$max_position, 3)
  expect_equal(ab$mean_position, 1.75)
  expect_equal(ab$median_position, 1.5)
  expect_true(
    all(result$occurrences$position_value ==
      result$occurrences$absolute_position)
  )
})

test_that("relative positions are bounded and use the requested basis", {
  extracted <- make_motif_visualisation_extraction()

  start <- summarise_sequence_motif_positions(
    extracted,
    position = "start",
    scale = "relative"
  )

  centre <- summarise_sequence_motif_positions(
    extracted,
    position = "centre",
    scale = "relative"
  )

  end <- summarise_sequence_motif_positions(
    extracted,
    position = "end",
    scale = "relative"
  )

  expect_true(all(start$occurrences$position_value >= 0))
  expect_true(all(start$occurrences$position_value <= 1))
  expect_true(all(centre$occurrences$position_value >= 0))
  expect_true(all(centre$occurrences$position_value <= 1))
  expect_true(all(end$occurrences$position_value >= 0))
  expect_true(all(end$occurrences$position_value <= 1))

  ab_start <- start$summary$mean_position[
    start$summary$motif == "A > B"
  ]

  ab_centre <- centre$summary$mean_position[
    centre$summary$motif == "A > B"
  ]

  ab_end <- end$summary$mean_position[
    end$summary$motif == "A > B"
  ]

  expect_equal(ab_start, 0.25)
  expect_equal(ab_centre, 5 / 12)
  expect_equal(ab_end, 7 / 12)
})

test_that("metadata grouping produces separate deterministic summaries", {
  extracted <- make_motif_visualisation_extraction()

  result <- summarise_sequence_motif_positions(
    extracted,
    position = "start",
    scale = "absolute",
    by = "group"
  )

  ab <- result$summary[
    result$summary$motif == "A > B",
    ,
    drop = FALSE
  ]

  expect_identical(ab$group, c("g1", "g2"))
  expect_identical(ab$n_occurrences, c(3L, 1L))
  expect_identical(ab$n_sequences, c(2L, 1L))
  expect_equal(ab$mean_position, c(5 / 3, 2))
  expect_identical(result$n_groups, 2L)
  expect_identical(result$settings$by, "group")
})

test_that("position summaries retain stable empty schemas", {
  extracted <- make_motif_visualisation_extraction(
    min_length = 8L,
    max_length = 8L
  )

  result <- summarise_sequence_motif_positions(
    extracted,
    position = "centre",
    scale = "relative",
    by = "group"
  )

  expected_summary <- c(
    "group",
    "motif_id",
    "motif_key",
    "motif",
    "motif_length",
    "position_basis",
    "position_scale",
    "n_occurrences",
    "n_sequences",
    "min_position",
    "max_position",
    "mean_position",
    "median_position"
  )

  expect_equal(nrow(result$summary), 0L)
  expect_equal(nrow(result$occurrences), 0L)
  expect_identical(names(result$summary), expected_summary)
  expect_identical(result$n_occurrences, 0L)
  expect_identical(result$n_motifs, 0L)
  expect_identical(result$n_groups, 0L)
})

test_that("position formatting changes display only", {
  positions <- summarise_sequence_motif_positions(
    make_motif_visualisation_extraction(),
    position = "start",
    scale = "relative",
    by = "group"
  )

  original <- positions

  formatted <- format_sequence_motif_positions(
    positions,
    digits = 1L,
    position_units = "percent",
    include_rank = TRUE
  )

  expect_identical(positions, original)
  expect_true("rank" %in% names(formatted$table))
  expect_true("position_unit" %in% names(formatted$table))
  expect_true(all(formatted$table$position_unit == "percent"))
  expect_identical(
    formatted$settings$applied_position_units,
    "percent"
  )

  ab_g1 <- formatted$table[
    formatted$table$group == "g1" &
      formatted$table$motif == "A > B",
    ,
    drop = FALSE
  ]

  expect_equal(ab_g1$mean_position, 16.7)
})

test_that("absolute positions remain indices during formatting", {
  positions <- summarise_sequence_motif_positions(
    make_motif_visualisation_extraction(),
    position = "centre",
    scale = "absolute"
  )

  formatted <- format_sequence_motif_positions(
    positions,
    digits = 2L,
    position_units = "percent",
    include_rank = FALSE
  )

  expect_false("rank" %in% names(formatted$table))
  expect_true(all(formatted$table$position_unit == "index"))
  expect_identical(
    formatted$settings$applied_position_units,
    "index"
  )
  expect_equal(
    formatted$table$mean_position,
    round(positions$summary$mean_position, 2L)
  )
})

test_that("motif plot data applies deterministic top-n ties", {
  summary <- summarise_sequence_motifs(
    make_motif_visualisation_extraction()
  )

  included <- .sequence_motif_plot_data(
    summary,
    type = "motifs",
    metric = "sequence_prevalence",
    top_n = 2L,
    ties = "include"
  )

  first <- .sequence_motif_plot_data(
    summary,
    type = "motifs",
    metric = "sequence_prevalence",
    top_n = 2L,
    ties = "first"
  )

  expect_true(nrow(included) > 2L)
  expect_equal(nrow(first), 2L)
  expect_identical(first$plot_rank, 1:2)
  expect_true(
    all(diff(first$sequence_prevalence) <= 0)
  )
})

test_that("motif bar plots return the exact plotted table", {
  summary <- summarise_sequence_motifs(
    make_motif_visualisation_extraction()
  )

  horizontal <- capture_motif_plot(
    plot_sequence_motifs(
      summary,
      metric = "n_occurrences",
      top_n = 3L,
      ties = "first",
      horizontal = TRUE
    )
  )

  vertical <- capture_motif_plot(
    plot_sequence_motifs(
      summary,
      metric = "occurrence_share",
      top_n = 3L,
      ties = "first",
      horizontal = FALSE
    )
  )

  expect_equal(nrow(horizontal$value), 3L)
  expect_equal(nrow(vertical$value), 3L)
  expect_true(all(is.finite(horizontal$value$bar_midpoint)))
  expect_true(all(is.finite(vertical$value$bar_midpoint)))
  expect_identical(horizontal$value$plot_rank, 1:3)
  expect_true(file.exists(horizontal$path))
  expect_true(file.exists(vertical$path))
})

test_that("motif plots handle empty filtered inputs", {
  empty <- filter_sequence_motifs(
    summarise_sequence_motifs(
      make_motif_visualisation_extraction()
    ),
    min_occurrences = 100L
  )

  plotted <- capture_motif_plot(
    plot_sequence_motifs(
      empty,
      top_n = 5L
    )
  )

  expect_equal(nrow(plotted$value), 0L)
  expect_true("bar_midpoint" %in% names(plotted$value))
  expect_true(file.exists(plotted$path))
})

test_that("strip position plots are deterministic and bounded", {
  extracted <- make_motif_visualisation_extraction()

  plotted <- capture_motif_plot(
    plot_sequence_motif_positions(
      extracted,
      position = "centre",
      scale = "relative",
      top_n = 2L,
      display = "strip"
    )
  )

  motif_table <- attr(plotted$value, "motif_table")

  expect_equal(nrow(motif_table), 2L)
  expect_true(all(plotted$value$position_value >= 0))
  expect_true(all(plotted$value$position_value <= 1))
  expect_true(all(is.finite(plotted$value$plot_y)))
  expect_identical(sort(unique(plotted$value$plot_rank)), 1:2)
  expect_true(file.exists(plotted$path))
})

test_that("position plots accept motif identifiers labels and summaries", {
  extracted <- make_motif_visualisation_extraction()
  positions <- summarise_sequence_motif_positions(
    extracted,
    position = "start",
    scale = "absolute"
  )

  motif_id <- positions$summary$motif_id[
    positions$summary$motif == "A > B"
  ][1L]

  by_label <- capture_motif_plot(
    plot_sequence_motif_positions(
      positions,
      motifs = "A > B",
      position = "end",
      scale = "absolute",
      display = "distribution"
    )
  )

  by_id <- capture_motif_plot(
    plot_sequence_motif_positions(
      extracted,
      motifs = motif_id,
      position = "start",
      scale = "relative",
      display = "strip"
    )
  )

  expect_identical(unique(by_label$value$motif), "A > B")
  expect_identical(unique(by_id$value$motif_id), motif_id)
  expect_true(all(by_label$value$position_basis == "end"))
  expect_true(all(by_id$value$position_scale == "relative"))
})

test_that("invalid positional and plotting settings are rejected", {
  extracted <- make_motif_visualisation_extraction()

  expect_error(
    summarise_sequence_motif_positions(
      extracted,
      position = "middle"
    ),
    "position"
  )

  expect_error(
    summarise_sequence_motif_positions(
      extracted,
      by = "missing_group"
    ),
    "not preserved"
  )

  positions <- summarise_sequence_motif_positions(extracted)

  expect_error(
    format_sequence_motif_positions(
      positions,
      digits = 16L
    ),
    "must not exceed"
  )

  expect_error(
    plot_sequence_motifs(
      extracted,
      top_n = 0L
    ),
    "top_n"
  )

  expect_error(
    plot_sequence_motif_positions(
      extracted,
      motifs = "not-a-motif"
    ),
    "not found"
  )

  expect_error(
    plot_sequence_motif_positions(
      extracted,
      display = "heatmap"
    ),
    "display"
  )
})
