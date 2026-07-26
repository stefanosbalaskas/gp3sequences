.sequence_test_case <- function(
  case = c(
    "minimal",
    "empty",
    "single_row",
    "single_sequence",
    "single_state",
    "equal_sequences",
    "variable_length",
    "unicode_states",
    "whitespace_states",
    "high_repetition",
    "missing_internal",
    "duplicate_positions",
    "unordered_rows",
    "order_gaps",
    "noninteger_order",
    "negative_duration",
    "zero_duration",
    "inconsistent_metadata"
  ),
  seed = 2026L
) {
  case <- match.arg(case)

  .sequence_check_seed(
    seed,
    allow_null = FALSE
  )

  base <- data.frame(
    sequence_id = rep(
      c("s1", "s2", "s3", "s4"),
      each = 4L
    ),
    sequence_order = rep(
      1:4,
      times = 4L
    ),
    state = c(
      "A", "B", "C", "D",
      "A", "B", "C", "C",
      "D", "C", "B", "A",
      "D", "C", "A", "A"
    ),
    duration = rep(
      c(1, 2, 1, 3),
      times = 4L
    ),
    group = rep(
      c("g1", "g2"),
      each = 8L
    ),
    stringsAsFactors = FALSE
  )

  if (case == "minimal") {
    return(base)
  }

  if (case == "empty") {
    return(
      base[0L, , drop = FALSE]
    )
  }

  if (case == "single_row") {
    return(
      base[1L, , drop = FALSE]
    )
  }

  if (case == "single_sequence") {
    return(
      base[
        base$sequence_id == "s1",
        ,
        drop = FALSE
      ]
    )
  }

  if (case == "single_state") {
    out <- base
    out$state <- "A"
    return(out)
  }

  if (case == "equal_sequences") {
    out <- base
    out$state <- rep(
      c("A", "B", "C", "D"),
      times = 4L
    )
    return(out)
  }

  if (case == "variable_length") {
    return(
      base[
        -c(8L, 15L, 16L),
        ,
        drop = FALSE
      ]
    )
  }

  if (case == "unicode_states") {
    out <- base
    out$state[
      out$state == "A"
    ] <- "\u0391"
    out$state[
      out$state == "B"
    ] <- "\u03b2"
    return(out)
  }

  if (case == "whitespace_states") {
    out <- base
    out$state[2L] <- " "
    return(out)
  }

  if (case == "high_repetition") {
    out <- base
    out$state <- rep(
      c("A", "A", "A", "B"),
      times = 4L
    )
    return(out)
  }

  if (case == "missing_internal") {
    out <- base
    out$state[2L] <- NA_character_
    return(out)
  }

  if (case == "duplicate_positions") {
    out <- base
    out$sequence_order[2L] <-
      out$sequence_order[1L]
    return(out)
  }

  if (case == "unordered_rows") {
    out <- base
    index <- c(
      2L,
      1L,
      seq.int(
        3L,
        nrow(base)
      )
    )
    return(
      out[
        index,
        ,
        drop = FALSE
      ]
    )
  }

  if (case == "order_gaps") {
    out <- base
    out$sequence_order[
      out$sequence_id == "s1"
    ] <- c(1, 2, 4, 5)
    return(out)
  }

  if (case == "noninteger_order") {
    out <- base
    out$sequence_order[2L] <- 1.5
    return(out)
  }

  if (case == "negative_duration") {
    out <- base
    out$duration[2L] <- -1
    return(out)
  }

  if (case == "zero_duration") {
    out <- base
    out$duration[2L] <- 0
    return(out)
  }

  if (case == "inconsistent_metadata") {
    out <- base
    out$group[2L] <- "other"
    return(out)
  }

  stop(
    "Unhandled sequence test case.",
    call. = FALSE
  )
}
