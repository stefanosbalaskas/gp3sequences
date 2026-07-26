make_extension_sequence_data <- function() {
  paths <- list(
    s01 = c("A", "B", "C", "D", "D"),
    s02 = c("A", "B", "C", "D", "C"),
    s03 = c("A", "B", "B", "C", "D"),
    s04 = c("A", "C", "C", "D", "D"),
    s05 = c("D", "C", "B", "A", "A"),
    s06 = c("D", "C", "B", "A", "B"),
    s07 = c("D", "C", "C", "B", "A"),
    s08 = c("D", "B", "B", "A", "A")
  )
  rows <- lapply(seq_along(paths), function(i) {
    data.frame(
      participant_id = paste0("p", i),
      sequence_id = names(paths)[i],
      sequence_order = seq_along(paths[[i]]),
      state = paths[[i]],
      group = rep(c("g1", "g2"), each = 4L)[i],
      condition_numeric = rep(c(0, 1), each = 4L)[i],
      time_scaled = seq(-1, 1, length.out = length(paths[[i]])),
      channel_context = c("x", "x", "y", "y", "z"),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

make_extension_panel_data <- function() {
  base <- make_extension_sequence_data()
  first <- base
  first$sequence_id <- paste0(first$sequence_id, "_w1")
  first$occasion <- 1L
  second <- base
  second$sequence_id <- paste0(second$sequence_id, "_w2")
  second$occasion <- 2L
  second$state[second$sequence_order == 2L] <- ifelse(
    second$group[second$sequence_order == 2L] == "g1", "C", "B"
  )
  rbind(first, second)
}
