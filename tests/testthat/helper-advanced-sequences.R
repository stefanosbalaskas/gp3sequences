make_advanced_sequence_data <- function() {
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
  group <- rep(c("g1", "g2"), each = 4L)
  participant <- paste0("p", seq_along(paths))
  rows <- lapply(seq_along(paths), function(i) {
    data.frame(
      sequence_id = names(paths)[i],
      sequence_order = seq_along(paths[[i]]),
      state = paths[[i]],
      group = group[i],
      participant_id = participant[i],
      weight = 1,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}
