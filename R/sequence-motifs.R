.sequence_motif_match_arg <- function(value, choices, argument) {
  invalid_message <- paste0(
    "`",
    argument,
    "` must be one of: ",
    paste(
      paste0("`", choices, "`"),
      collapse = ", "
    ),
    "."
  )

  if (
    !is.character(value) ||
      length(value) < 1L ||
      anyNA(value)
  ) {
    stop(
      invalid_message,
      call. = FALSE
    )
  }

  tryCatch(
    match.arg(value, choices),
    error = function(error) {
      stop(
        invalid_message,
        call. = FALSE
      )
    }
  )
}

.sequence_motif_assert_whole_number <- function(
  value,
  argument,
  minimum = 0L,
  allow_null = FALSE
) {
  if (allow_null && is.null(value)) {
    return(invisible(NULL))
  }

  if (
    !is.numeric(value) ||
      length(value) != 1L ||
      is.na(value) ||
      !is.finite(value) ||
      value < minimum ||
      value != floor(value)
  ) {
    stop(
      "`",
      argument,
      "` must be one whole number greater than or equal to ",
      minimum,
      ".",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.sequence_motif_assert_proportion <- function(value, argument) {
  if (
    !is.numeric(value) ||
      length(value) != 1L ||
      is.na(value) ||
      !is.finite(value) ||
      value < 0 ||
      value > 1
  ) {
    stop(
      "`",
      argument,
      "` must be one finite number between 0 and 1.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.sequence_motif_assert_lengths <- function(min_length, max_length) {
  .sequence_motif_assert_whole_number(
    min_length,
    "min_length",
    minimum = 1L
  )

  .sequence_motif_assert_whole_number(
    max_length,
    "max_length",
    minimum = 1L
  )

  if (max_length < min_length) {
    stop(
      "`max_length` must be greater than or equal to `min_length`.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.sequence_motif_assert_motif_lengths <- function(value) {
  if (is.null(value)) {
    return(invisible(NULL))
  }

  if (
    !is.numeric(value) ||
      length(value) == 0L ||
      anyNA(value) ||
      any(!is.finite(value)) ||
      any(value < 1) ||
      any(value != floor(value))
  ) {
    stop(
      "`motif_lengths` must contain positive whole numbers or be `NULL`.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.sequence_motif_empty_occurrences <- function(metadata_cols) {
  result <- data.frame(
    sequence_id = character(),
    motif_id = character(),
    motif_key = character(),
    motif = character(),
    motif_length = integer(),
    start_index = integer(),
    end_index = integer(),
    start_order = double(),
    end_order = double(),
    start_original_row = integer(),
    end_original_row = integer(),
    occurrence_index = integer(),
    stringsAsFactors = FALSE
  )

  for (column in metadata_cols) {
    result[[column]] <- character()
  }

  result[
    c(
      "sequence_id",
      metadata_cols,
      "motif_id",
      "motif_key",
      "motif",
      "motif_length",
      "start_index",
      "end_index",
      "start_order",
      "end_order",
      "start_original_row",
      "end_original_row",
      "occurrence_index"
    )
  ]
}

.sequence_motif_empty_dictionary <- function() {
  data.frame(
    motif_id = character(),
    motif_key = character(),
    motif = character(),
    motif_length = integer(),
    stringsAsFactors = FALSE
  )
}

.sequence_motif_empty_sequences <- function(metadata_cols) {
  result <- data.frame(
    sequence_id = character(),
    n_states = integer(),
    n_candidate_occurrences = integer(),
    n_retained_occurrences = integer(),
    n_distinct_motifs = integer(),
    stringsAsFactors = FALSE
  )

  for (column in metadata_cols) {
    result[[column]] <- character()
  }

  result[
    c(
      "sequence_id",
      metadata_cols,
      "n_states",
      "n_candidate_occurrences",
      "n_retained_occurrences",
      "n_distinct_motifs"
    )
  ]
}

.sequence_motif_empty_by_sequence <- function(metadata_cols) {
  result <- data.frame(
    sequence_id = character(),
    motif_id = character(),
    motif_key = character(),
    motif = character(),
    motif_length = integer(),
    n_occurrences = integer(),
    first_start_index = integer(),
    last_start_index = integer(),
    stringsAsFactors = FALSE
  )

  for (column in metadata_cols) {
    result[[column]] <- character()
  }

  result[
    c(
      "sequence_id",
      metadata_cols,
      "motif_id",
      "motif_key",
      "motif",
      "motif_length",
      "n_occurrences",
      "first_start_index",
      "last_start_index"
    )
  ]
}

.sequence_motif_empty_overall <- function() {
  data.frame(
    motif_id = character(),
    motif_key = character(),
    motif = character(),
    motif_length = integer(),
    n_occurrences = integer(),
    n_sequences = integer(),
    sequence_prevalence = double(),
    occurrence_share = double(),
    mean_occurrences_per_sequence = double(),
    mean_occurrences_when_present = double(),
    stringsAsFactors = FALSE
  )
}

.sequence_motif_make_id <- function(motif_length, state_codes) {
  paste0(
    "L",
    motif_length,
    ":",
    paste(state_codes, collapse = "|")
  )
}

.sequence_motif_sort_overall <- function(data, primary) {
  if (nrow(data) == 0L) {
    return(data)
  }

  secondary <- c(
    "sequence_prevalence",
    "n_occurrences",
    "n_sequences"
  )

  secondary <- setdiff(secondary, primary)

  order_arguments <- list(-data[[primary]])

  for (column in secondary) {
    order_arguments[[length(order_arguments) + 1L]] <- -data[[column]]
  }

  order_arguments[[length(order_arguments) + 1L]] <- data$motif_length
  order_arguments[[length(order_arguments) + 1L]] <- data$motif_key
  order_arguments$method <- "radix"

  data <- data[do.call(order, order_arguments), , drop = FALSE]
  row.names(data) <- NULL
  data
}

.sequence_motif_select_non_overlapping <- function(occurrences) {
  if (nrow(occurrences) == 0L) {
    return(occurrences)
  }

  group <- interaction(
    occurrences$sequence_id,
    occurrences$motif_id,
    drop = TRUE,
    lex.order = TRUE
  )

  groups <- split(seq_len(nrow(occurrences)), group)
  keep <- logical(nrow(occurrences))

  for (indices in groups) {
    indices <- indices[
      order(
        occurrences$start_index[indices],
        occurrences$end_index[indices],
        method = "radix"
      )
    ]

    last_end <- -Inf

    for (index in indices) {
      if (occurrences$start_index[index] > last_end) {
        keep[index] <- TRUE
        last_end <- occurrences$end_index[index]
      }
    }
  }

  occurrences[keep, , drop = FALSE]
}

.sequence_motif_add_occurrence_index <- function(occurrences) {
  if (nrow(occurrences) == 0L) {
    occurrences$occurrence_index <- integer()
    return(occurrences)
  }

  group <- interaction(
    occurrences$sequence_id,
    occurrences$motif_id,
    drop = TRUE,
    lex.order = TRUE
  )

  groups <- split(seq_len(nrow(occurrences)), group)
  occurrence_index <- integer(nrow(occurrences))

  for (indices in groups) {
    indices <- indices[
      order(
        occurrences$start_index[indices],
        occurrences$end_index[indices],
        method = "radix"
      )
    ]

    occurrence_index[indices] <- seq_along(indices)
  }

  occurrences$occurrence_index <- as.integer(occurrence_index)
  occurrences
}

.sequence_motif_validate_extraction <- function(x) {
  if (
    !is.list(x) ||
      is.null(x$occurrences) ||
      is.null(x$motifs) ||
      is.null(x$sequences) ||
      is.null(x$settings)
  ) {
    stop(
      "`x` must be an object returned by `extract_sequence_ngrams()`.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

.sequence_motif_as_summary <- function(x) {
  if (!is.list(x)) {
    stop(
      "`x` must be a motif extraction, summary, or filtered-motif object.",
      call. = FALSE
    )
  }

  if (!is.null(x$overall) && !is.null(x$by_sequence)) {
    return(x)
  }

  if (!is.null(x$motifs) && !is.null(x$by_sequence)) {
    result <- x
    result$overall <- x$motifs
    return(result)
  }

  if (!is.null(x$occurrences) && !is.null(x$sequences)) {
    return(summarise_sequence_motifs(x))
  }

  stop(
    "`x` must be a motif extraction, summary, or filtered-motif object.",
    call. = FALSE
  )
}

#' Extract Contiguous Sequence N-Grams
#'
#' Enumerates contiguous state motifs from validated long-format sequence data.
#'
#' @inheritParams audit_sequence_data
#' @param min_length Positive whole number giving the shortest motif length.
#' @param max_length Positive whole number giving the longest motif length.
#' @param overlap Character value specifying whether overlapping occurrences of
#'   the same motif within the same sequence are `"allow"`ed or
#'   `"disallow"`ed.
#' @param separator Character value used only to display state labels in the
#'   human-readable `motif` column.
#' @param state_levels Optional atomic vector defining the complete state
#'   ordering. When omitted, factor levels are respected; otherwise observed
#'   labels are sorted deterministically.
#'
#' @return A named list containing:
#'
#' * `occurrences`: one row per retained contiguous motif occurrence;
#' * `motifs`: the distinct motif dictionary;
#' * `sequences`: sequence-level counts of candidate and retained occurrences;
#' * `state_dictionary`: the deterministic state dictionary;
#' * `audit`, `status`, and `mapping` from input validation;
#' * `settings`: the resolved motif extraction settings.
#'
#' @details
#' Motifs are contiguous windows only. No subsequence gaps, edit distances,
#' statistical tests, or substantive interpretations are introduced.
#' Consecutive repeated states are used exactly as supplied; any repeat
#' collapsing should be performed explicitly with `prepare_sequence_data()`
#' before extraction.
#'
#' With `overlap = "disallow"`, overlap is resolved independently within each
#' sequence-motif pair by a deterministic left-to-right greedy rule. Different
#' motifs and different motif lengths do not compete for positions.
#'
#' The collision-resistant `motif_id` and `motif_key` columns are derived from
#' deterministic state codes. The display separator may therefore also occur
#' inside a state label without changing motif identity.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c(rep("s1", 5L), rep("s2", 4L)),
#'   position = c(1:5, 1:4),
#'   state = c("A", "B", "A", "B", "A", "A", "B", "A", "C")
#' )
#'
#' ngrams <- extract_sequence_ngrams(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state",
#'   min_length = 2,
#'   max_length = 3,
#'   overlap = "allow"
#' )
#'
#' ngrams$occurrences
#' ngrams$motifs
#'
#' @export
extract_sequence_ngrams <- function(
  data,
  sequence_id_col,
  order_col,
  state_col,
  duration_col = NULL,
  metadata_cols = NULL,
  expected_states = NULL,
  min_length = 2L,
  max_length = 3L,
  overlap = c("allow", "disallow"),
  separator = " > ",
  state_levels = NULL
) {
  .sequence_motif_assert_lengths(min_length, max_length)
  overlap <- .sequence_motif_match_arg(
    overlap,
    c("allow", "disallow"),
    "overlap"
  )
  .sequence_assert_text_scalar(separator, "separator")

  .sequence_assert_output_names(
    metadata_cols = metadata_cols,
    reserved = c(
      "motif_id",
      "motif_key",
      "motif",
      "motif_length",
      "start_index",
      "end_index",
      "start_order",
      "end_order",
      "start_original_row",
      "end_original_row",
      "occurrence_index",
      "n_states",
      "n_candidate_occurrences",
      "n_retained_occurrences",
      "n_distinct_motifs"
    ),
    context = "motif"
  )

  encoded <- encode_sequence_data(
    data = data,
    sequence_id_col = sequence_id_col,
    order_col = order_col,
    state_col = state_col,
    duration_col = duration_col,
    metadata_cols = metadata_cols,
    expected_states = expected_states,
    state_levels = state_levels,
    prefix = "S"
  )

  sequence_data <- encoded$data
  sequence_ids <- unique(sequence_data$sequence_id)
  occurrence_rows <- list()
  sequence_rows <- list()

  for (sequence_id in sequence_ids) {
    rows <- which(sequence_data$sequence_id == sequence_id)
    n_states <- length(rows)

    metadata <- .sequence_metadata_values(
      data = sequence_data,
      rows = rows,
      metadata_cols = metadata_cols
    )

    candidate_count <- 0L

    if (n_states >= min_length) {
      upper_length <- min(max_length, n_states)

      for (motif_length in seq.int(min_length, upper_length)) {
        n_windows <- n_states - motif_length + 1L
        candidate_count <- candidate_count + n_windows

        for (start_index in seq_len(n_windows)) {
          end_index <- start_index + motif_length - 1L
          window_rows <- rows[start_index:end_index]
          state_codes <- sequence_data$state_code[window_rows]
          state_labels <- sequence_data$state[window_rows]
          motif_key <- paste(state_codes, collapse = "|")

          values <- c(
            list(sequence_id = sequence_id),
            metadata,
            list(
              motif_id = .sequence_motif_make_id(
                motif_length,
                state_codes
              ),
              motif_key = motif_key,
              motif = paste(state_labels, collapse = separator),
              motif_length = as.integer(motif_length),
              start_index = as.integer(start_index),
              end_index = as.integer(end_index),
              start_order = sequence_data$sequence_order[
                window_rows[1L]
              ],
              end_order = sequence_data$sequence_order[
                window_rows[length(window_rows)]
              ],
              start_original_row = sequence_data$original_row[
                window_rows[1L]
              ],
              end_original_row = sequence_data$original_row[
                window_rows[length(window_rows)]
              ]
            )
          )

          occurrence_rows[[length(occurrence_rows) + 1L]] <-
            as.data.frame(
              values,
              stringsAsFactors = FALSE,
              check.names = FALSE
            )
        }
      }
    }

    sequence_rows[[length(sequence_rows) + 1L]] <-
      as.data.frame(
        c(
          list(sequence_id = sequence_id),
          metadata,
          list(
            n_states = as.integer(n_states),
            n_candidate_occurrences = as.integer(candidate_count),
            n_retained_occurrences = 0L,
            n_distinct_motifs = 0L
          )
        ),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
  }

  occurrences <- .sequence_bind_frames(
    frames = occurrence_rows,
    empty = .sequence_motif_empty_occurrences(metadata_cols)
  )

  sequences <- .sequence_bind_frames(
    frames = sequence_rows,
    empty = .sequence_motif_empty_sequences(metadata_cols)
  )

  if (overlap == "disallow") {
    occurrences <- .sequence_motif_select_non_overlapping(occurrences)
  }

  if (nrow(occurrences) > 0L) {
    sequence_rank <- match(occurrences$sequence_id, sequence_ids)

    occurrences <- occurrences[
      order(
        sequence_rank,
        occurrences$start_index,
        occurrences$motif_length,
        occurrences$motif_key,
        method = "radix"
      ),
      ,
      drop = FALSE
    ]

    row.names(occurrences) <- NULL
    occurrences <- .sequence_motif_add_occurrence_index(occurrences)
  }

  if (nrow(sequences) > 0L) {
    for (index in seq_len(nrow(sequences))) {
      sequence_id <- sequences$sequence_id[index]
      occurrence_rows_for_sequence <- which(
        occurrences$sequence_id == sequence_id
      )

      sequences$n_retained_occurrences[index] <- as.integer(
        length(occurrence_rows_for_sequence)
      )

      sequences$n_distinct_motifs[index] <- as.integer(
        length(unique(occurrences$motif_id[occurrence_rows_for_sequence]))
      )
    }
  }

  motifs <- if (nrow(occurrences) == 0L) {
    .sequence_motif_empty_dictionary()
  } else {
    unique(
      occurrences[
        c("motif_id", "motif_key", "motif", "motif_length")
      ]
    )
  }

  if (nrow(motifs) > 0L) {
    motifs <- motifs[
      order(
        motifs$motif_length,
        motifs$motif_key,
        method = "radix"
      ),
      ,
      drop = FALSE
    ]
    row.names(motifs) <- NULL
  }

  list(
    occurrences = occurrences,
    motifs = motifs,
    sequences = sequences,
    state_dictionary = encoded$dictionary,
    audit = encoded$audit,
    status = encoded$status,
    mapping = encoded$mapping,
    settings = list(
      min_length = as.integer(min_length),
      max_length = as.integer(max_length),
      overlap = overlap,
      overlap_scope = "within_sequence_motif",
      overlap_rule = if (overlap == "disallow") {
        "left_to_right_greedy"
      } else {
        "all_contiguous_windows"
      },
      separator = separator,
      n_sequences = as.integer(length(sequence_ids))
    )
  )
}

#' Summarise Contiguous Sequence Motifs
#'
#' Aggregates extracted contiguous motif occurrences by sequence and overall.
#'
#' @param x An object returned by `extract_sequence_ngrams()`.
#'
#' @return A named list containing:
#'
#' * `by_sequence`: occurrence counts for each sequence-motif pair;
#' * `overall`: total occurrence counts, sequence counts, sequence prevalence,
#'   occurrence share, and mean occurrence rates;
#' * `sequences` and `state_dictionary` from extraction;
#' * `audit`, `status`, `mapping`, and extraction settings;
#' * scalar counts for sequences, occurrences, and distinct motifs.
#'
#' @details
#' Sequence prevalence uses every validated sequence in the extraction object as
#' its denominator, including sequences too short to contain a requested motif.
#' Results are sorted deterministically by sequence prevalence, occurrence
#' count, motif length, and motif key.
#'
#' The function reports structural recurrence only. It does not perform
#' significance testing or infer psychological, cognitive, emotional, or
#' diagnostic attributes.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c(rep("s1", 5L), rep("s2", 4L)),
#'   position = c(1:5, 1:4),
#'   state = c("A", "B", "A", "B", "A", "A", "B", "A", "C")
#' )
#'
#' extracted <- extract_sequence_ngrams(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state",
#'   min_length = 2,
#'   max_length = 3
#' )
#'
#' summaries <- summarise_sequence_motifs(extracted)
#' summaries$by_sequence
#' summaries$overall
#'
#' @export
summarise_sequence_motifs <- function(x) {
  .sequence_motif_validate_extraction(x)

  occurrences <- x$occurrences
  sequences <- x$sequences
  metadata_cols <- setdiff(
    names(sequences),
    c(
      "sequence_id",
      "n_states",
      "n_candidate_occurrences",
      "n_retained_occurrences",
      "n_distinct_motifs"
    )
  )

  total_sequences <- nrow(sequences)
  total_occurrences <- nrow(occurrences)

  if (total_occurrences == 0L) {
    by_sequence <- .sequence_motif_empty_by_sequence(metadata_cols)
    overall <- .sequence_motif_empty_overall()
  } else {
    pair_key <- interaction(
      occurrences$sequence_id,
      occurrences$motif_id,
      drop = TRUE,
      lex.order = TRUE
    )

    pair_groups <- split(seq_len(total_occurrences), pair_key)
    by_sequence_rows <- list()

    for (indices in pair_groups) {
      first <- indices[1L]
      sequence_id <- occurrences$sequence_id[first]
      metadata <- vector("list", length(metadata_cols))
      names(metadata) <- metadata_cols

      for (column in metadata_cols) {
        metadata[[column]] <- occurrences[[column]][first]
      }

      by_sequence_rows[[length(by_sequence_rows) + 1L]] <-
        as.data.frame(
          c(
            list(sequence_id = sequence_id),
            metadata,
            list(
              motif_id = occurrences$motif_id[first],
              motif_key = occurrences$motif_key[first],
              motif = occurrences$motif[first],
              motif_length = as.integer(
                occurrences$motif_length[first]
              ),
              n_occurrences = as.integer(length(indices)),
              first_start_index = as.integer(
                min(occurrences$start_index[indices])
              ),
              last_start_index = as.integer(
                max(occurrences$start_index[indices])
              )
            )
          ),
          stringsAsFactors = FALSE,
          check.names = FALSE
        )
    }

    by_sequence <- .sequence_bind_frames(
      frames = by_sequence_rows,
      empty = .sequence_motif_empty_by_sequence(metadata_cols)
    )

    motif_groups <- split(
      seq_len(nrow(by_sequence)),
      by_sequence$motif_id
    )

    overall_rows <- list()

    for (indices in motif_groups) {
      first <- indices[1L]
      n_occurrences <- sum(by_sequence$n_occurrences[indices])
      n_sequences <- length(indices)

      overall_rows[[length(overall_rows) + 1L]] <-
        data.frame(
          motif_id = by_sequence$motif_id[first],
          motif_key = by_sequence$motif_key[first],
          motif = by_sequence$motif[first],
          motif_length = as.integer(by_sequence$motif_length[first]),
          n_occurrences = as.integer(n_occurrences),
          n_sequences = as.integer(n_sequences),
          sequence_prevalence = if (total_sequences > 0L) {
            n_sequences / total_sequences
          } else {
            NA_real_
          },
          occurrence_share = n_occurrences / total_occurrences,
          mean_occurrences_per_sequence = if (total_sequences > 0L) {
            n_occurrences / total_sequences
          } else {
            NA_real_
          },
          mean_occurrences_when_present = n_occurrences / n_sequences,
          stringsAsFactors = FALSE
        )
    }

    overall <- .sequence_bind_frames(
      frames = overall_rows,
      empty = .sequence_motif_empty_overall()
    )

    overall <- .sequence_motif_sort_overall(
      overall,
      primary = "sequence_prevalence"
    )

    motif_rank <- match(by_sequence$motif_id, overall$motif_id)
    sequence_rank <- match(
      by_sequence$sequence_id,
      sequences$sequence_id
    )

    by_sequence <- by_sequence[
      order(
        motif_rank,
        sequence_rank,
        method = "radix"
      ),
      ,
      drop = FALSE
    ]
    row.names(by_sequence) <- NULL
  }

  list(
    by_sequence = by_sequence,
    overall = overall,
    sequences = sequences,
    state_dictionary = x$state_dictionary,
    audit = x$audit,
    status = x$status,
    mapping = x$mapping,
    extraction_settings = x$settings,
    n_sequences = as.integer(total_sequences),
    n_occurrences = as.integer(total_occurrences),
    n_motifs = as.integer(nrow(overall))
  )
}

#' Filter Sequence Motif Summaries
#'
#' Applies transparent count, prevalence, length, and top-ranking filters to
#' sequence motif summaries.
#'
#' @param x A motif extraction, motif summary, or filtered-motif object.
#' @param min_occurrences Non-negative whole number giving the minimum total
#'   occurrence count.
#' @param min_sequences Non-negative whole number giving the minimum number of
#'   sequences containing the motif.
#' @param min_prevalence Minimum sequence prevalence between 0 and 1.
#' @param motif_lengths Optional vector of positive whole-number motif lengths
#'   to retain.
#' @param top_n Optional positive whole number giving the requested number of
#'   highest-ranked motifs.
#' @param rank_by Metric used for deterministic top-ranking: one of
#'   `"sequence_prevalence"`, `"n_occurrences"`, or `"n_sequences"`.
#' @param ties Character value controlling the top-`n` boundary. `"include"`
#'   retains every motif tied on `rank_by` with the final selected motif;
#'   `"first"` retains exactly `top_n` motifs after deterministic secondary
#'   sorting.
#'
#' @return A named list containing the filtered `motifs` table, the matching
#' sequence-level rows in `by_sequence`, sequence and state dictionaries,
#' validation metadata, filter settings, and counts before and after filtering.
#'
#' @details
#' Filtering is descriptive and deterministic. When `ties = "first"`, ties are
#' resolved by sequence prevalence, occurrence count, sequence count, shorter
#' motif length, and finally the collision-resistant motif key.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c(rep("s1", 5L), rep("s2", 4L)),
#'   position = c(1:5, 1:4),
#'   state = c("A", "B", "A", "B", "A", "A", "B", "A", "C")
#' )
#'
#' extracted <- extract_sequence_ngrams(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state"
#' )
#'
#' filtered <- filter_sequence_motifs(
#'   extracted,
#'   min_sequences = 2,
#'   top_n = 5,
#'   ties = "include"
#' )
#'
#' filtered$motifs
#'
#' @export
filter_sequence_motifs <- function(
  x,
  min_occurrences = 1L,
  min_sequences = 1L,
  min_prevalence = 0,
  motif_lengths = NULL,
  top_n = NULL,
  rank_by = c(
    "sequence_prevalence",
    "n_occurrences",
    "n_sequences"
  ),
  ties = c("include", "first")
) {
  .sequence_motif_assert_whole_number(
    min_occurrences,
    "min_occurrences",
    minimum = 0L
  )
  .sequence_motif_assert_whole_number(
    min_sequences,
    "min_sequences",
    minimum = 0L
  )
  .sequence_motif_assert_proportion(
    min_prevalence,
    "min_prevalence"
  )
  .sequence_motif_assert_motif_lengths(motif_lengths)
  .sequence_motif_assert_whole_number(
    top_n,
    "top_n",
    minimum = 1L,
    allow_null = TRUE
  )

  rank_by <- .sequence_motif_match_arg(
    rank_by,
    c(
      "sequence_prevalence",
      "n_occurrences",
      "n_sequences"
    ),
    "rank_by"
  )

  ties <- .sequence_motif_match_arg(
    ties,
    c("include", "first"),
    "ties"
  )

  summary <- .sequence_motif_as_summary(x)
  available <- summary$overall
  selected <- available

  keep <- selected$n_occurrences >= min_occurrences &
    selected$n_sequences >= min_sequences &
    selected$sequence_prevalence >= min_prevalence

  if (!is.null(motif_lengths)) {
    keep <- keep & selected$motif_length %in% unique(
      as.integer(motif_lengths)
    )
  }

  selected <- selected[keep, , drop = FALSE]
  selected <- .sequence_motif_sort_overall(selected, primary = rank_by)

  if (!is.null(top_n) && nrow(selected) > top_n) {
    if (ties == "include") {
      threshold <- selected[[rank_by]][top_n]
      selected <- selected[
        selected[[rank_by]] >= threshold,
        ,
        drop = FALSE
      ]
    } else {
      selected <- selected[seq_len(top_n), , drop = FALSE]
    }
  }

  row.names(selected) <- NULL

  selected_ids <- selected$motif_id
  by_sequence <- summary$by_sequence[
    summary$by_sequence$motif_id %in% selected_ids,
    ,
    drop = FALSE
  ]

  if (nrow(by_sequence) > 0L) {
    motif_rank <- match(by_sequence$motif_id, selected_ids)
    sequence_rank <- match(
      by_sequence$sequence_id,
      summary$sequences$sequence_id
    )

    by_sequence <- by_sequence[
      order(
        motif_rank,
        sequence_rank,
        method = "radix"
      ),
      ,
      drop = FALSE
    ]
    row.names(by_sequence) <- NULL
  }

  list(
    motifs = selected,
    by_sequence = by_sequence,
    sequences = summary$sequences,
    state_dictionary = summary$state_dictionary,
    audit = summary$audit,
    status = summary$status,
    mapping = summary$mapping,
    extraction_settings = summary$extraction_settings,
    settings = list(
      min_occurrences = as.integer(min_occurrences),
      min_sequences = as.integer(min_sequences),
      min_prevalence = as.numeric(min_prevalence),
      motif_lengths = if (is.null(motif_lengths)) {
        NULL
      } else {
        sort(unique(as.integer(motif_lengths)))
      },
      top_n = if (is.null(top_n)) NULL else as.integer(top_n),
      rank_by = rank_by,
      ties = ties
    ),
    n_available = as.integer(nrow(available)),
    n_retained = as.integer(nrow(selected))
  )
}

#' Format Sequence Motif Summaries
#'
#' Produces a stable, report-ready table from motif extraction, summary, or
#' filtered-motif output.
#'
#' @param x A motif extraction, motif summary, or filtered-motif object.
#' @param digits Whole number from 0 to 15 controlling numeric rounding.
#' @param prevalence Character value specifying whether prevalence and
#'   occurrence share are shown as `"proportion"`s or `"percent"`ages.
#' @param include_rank Logical value indicating whether to add a rank column.
#' @param rank_by Metric used to order and rank motifs: one of
#'   `"sequence_prevalence"`, `"n_occurrences"`, or `"n_sequences"`.
#' @param ties Character value specifying `"min"` shared ranks or
#'   deterministic `"first"` ranks.
#' @param include_ids Logical value indicating whether `motif_id` and
#'   `motif_key` should be included in the formatted table.
#'
#' @return A named list containing `table`, validation metadata, and formatting
#' settings. The table contains only structural motif measurements.
#'
#' @details
#' Formatting changes display precision and units only. It does not change the
#' underlying motif counts or introduce substantive interpretation.
#'
#' @examples
#' sequences <- data.frame(
#'   id = c(rep("s1", 5L), rep("s2", 4L)),
#'   position = c(1:5, 1:4),
#'   state = c("A", "B", "A", "B", "A", "A", "B", "A", "C")
#' )
#'
#' extracted <- extract_sequence_ngrams(
#'   sequences,
#'   sequence_id_col = "id",
#'   order_col = "position",
#'   state_col = "state"
#' )
#'
#' formatted <- format_sequence_motifs(
#'   extracted,
#'   prevalence = "percent",
#'   digits = 1
#' )
#'
#' formatted$table
#'
#' @export
format_sequence_motifs <- function(
  x,
  digits = 3L,
  prevalence = c("proportion", "percent"),
  include_rank = TRUE,
  rank_by = c(
    "sequence_prevalence",
    "n_occurrences",
    "n_sequences"
  ),
  ties = c("min", "first"),
  include_ids = TRUE
) {
  .sequence_motif_assert_whole_number(
    digits,
    "digits",
    minimum = 0L
  )

  if (digits > 15L) {
    stop("`digits` must not exceed 15.", call. = FALSE)
  }

  .sequence_assert_flag(include_rank, "include_rank")
  .sequence_assert_flag(include_ids, "include_ids")

  prevalence <- .sequence_motif_match_arg(
    prevalence,
    c("proportion", "percent"),
    "prevalence"
  )

  rank_by <- .sequence_motif_match_arg(
    rank_by,
    c(
      "sequence_prevalence",
      "n_occurrences",
      "n_sequences"
    ),
    "rank_by"
  )

  ties <- .sequence_motif_match_arg(
    ties,
    c("min", "first"),
    "ties"
  )

  summary <- .sequence_motif_as_summary(x)
  table <- summary$overall
  table <- .sequence_motif_sort_overall(table, primary = rank_by)

  if (include_rank) {
    rank_values <- if (nrow(table) == 0L) {
      integer()
    } else if (ties == "first") {
      seq_len(nrow(table))
    } else {
      rank(-table[[rank_by]], ties.method = "min")
    }

    table$rank <- as.integer(rank_values)
  }

  if (nrow(table) > 0L) {
    if (prevalence == "percent") {
      table$sequence_prevalence <- 100 * table$sequence_prevalence
      table$occurrence_share <- 100 * table$occurrence_share
    }

    numeric_columns <- c(
      "sequence_prevalence",
      "occurrence_share",
      "mean_occurrences_per_sequence",
      "mean_occurrences_when_present"
    )

    for (column in numeric_columns) {
      table[[column]] <- round(table[[column]], digits = digits)
    }
  }

  if (prevalence == "percent") {
    names(table)[names(table) == "sequence_prevalence"] <-
      "sequence_prevalence_percent"
    names(table)[names(table) == "occurrence_share"] <-
      "occurrence_share_percent"
  }

  if (!include_ids) {
    table$motif_id <- NULL
    table$motif_key <- NULL
  }

  front <- c(
    if (include_rank) "rank",
    if (include_ids) c("motif_id", "motif_key"),
    "motif",
    "motif_length",
    "n_occurrences",
    "n_sequences"
  )

  table <- table[
    c(front, setdiff(names(table), front))
  ]
  row.names(table) <- NULL

  list(
    table = table,
    audit = summary$audit,
    status = summary$status,
    mapping = summary$mapping,
    settings = list(
      digits = as.integer(digits),
      prevalence = prevalence,
      include_rank = include_rank,
      rank_by = rank_by,
      ties = ties,
      include_ids = include_ids
    )
  )
}
