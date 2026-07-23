.sequence_adv_wide <- function(data, sequence_id_col, order_col, state_col,
                               fill = NA_character_) {
  x <- .sequence_adv_data(data, sequence_id_col, order_col, state_col,
                          missing_state_policy = "error")
  positions <- sort(unique(unlist(x$orders, use.names = FALSE)))
  wide <- matrix(fill, nrow = length(x$sequence_ids), ncol = length(positions),
                 dimnames = list(x$sequence_ids, paste0("position_", positions)))
  for (id in x$sequence_ids) {
    wide[id, match(x$orders[[id]], positions)] <- x$sequences[[id]]
  }
  list(wide = as.data.frame(wide, stringsAsFactors = FALSE),
       positions = positions, state_levels = x$state_levels,
       sequence_ids = x$sequence_ids)
}

#' Convert sequence data to a TraMineR state-sequence object
#'
#' @param data Long-format sequence data.
#' @param sequence_id_col,order_col,state_col Sequence columns.
#' @param missing Missing-state code passed to `TraMineR::seqdef()`.
#' @param right Right-missing policy passed to `TraMineR::seqdef()`.
#' @param ... Additional arguments passed to `TraMineR::seqdef()`.
#'
#' @return A TraMineR `stslist` object with original sequence identifiers as
#' row names.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' if (requireNamespace("TraMineR", quietly = TRUE)) {
#'   as_traminer_sequences(sequences)
#' }
#'
#' @export
as_traminer_sequences <- function(data,
                                  sequence_id_col = "sequence_id",
                                  order_col = "sequence_order",
                                  state_col = "state",
                                  missing = NA,
                                  right = "DEL", ...) {
  .sequence_adv_require("TraMineR", "create a TraMineR state-sequence object")
  wide <- .sequence_adv_wide(data, sequence_id_col, order_col, state_col, fill = missing)
  result <- TraMineR::seqdef(wide$wide, states = wide$state_levels,
                             missing = missing, right = right, ...)
  rownames(result) <- wide$sequence_ids
  result
}

#' Convert sequence data to cSPADE transaction input
#'
#' @param data Long-format sequence data.
#' @param sequence_id_col,order_col,state_col Sequence columns.
#'
#' @return An `arules` transactions object whose transaction information
#' contains positive integer `sequenceID` and `eventID` fields required by
#' `arulesSequences::cspade()`.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' if (requireNamespace("arules", quietly = TRUE) &&
#'     requireNamespace("arulesSequences", quietly = TRUE)) {
#'   as_arules_sequences(sequences)
#' }
#'
#' @export
as_arules_sequences <- function(data,
                                sequence_id_col = "sequence_id",
                                order_col = "sequence_order",
                                state_col = "state") {
  .sequence_adv_require("arules", "create arules transaction input")
  .sequence_adv_require("arulesSequences", "prepare cSPADE sequence metadata")
  x <- .sequence_adv_data(data, sequence_id_col, order_col, state_col,
                          missing_state_policy = "error")
  itemsets <- lapply(as.character(x$data[[state_col]]), function(value) value)
  transactions <- methods::as(itemsets, "transactions")
  sequence_id <- match(as.character(x$data[[sequence_id_col]]), x$sequence_ids)
  event_id <- stats::ave(seq_len(nrow(x$data)), as.character(x$data[[sequence_id_col]]),
                  FUN = seq_along)
  information <- arules::transactionInfo(transactions)
  information$sequenceID <- as.integer(sequence_id)
  information$eventID <- as.integer(event_id)
  transactions <- arules::`transactionInfo<-`(
    transactions,
    value = information
  )
  transactions
}

#' Create GrpString-compatible event and string inputs
#'
#' @param data Long-format sequence data.
#' @param sequence_id_col,order_col,state_col Sequence columns.
#' @param alphabet Optional single-character symbols. When omitted, printable
#' ASCII characters are assigned deterministically.
#'
#' @return A list of class `gp3_grpstring_input` containing a wide event data
#' frame, event-name vector, character vector, conversion key, and string vector.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' as_grpstring_data(sequences)
#'
#' @export
as_grpstring_data <- function(data,
                              sequence_id_col = "sequence_id",
                              order_col = "sequence_order",
                              state_col = "state",
                              alphabet = NULL) {
  wide <- .sequence_adv_wide(data, sequence_id_col, order_col, state_col)
  states <- wide$state_levels
  if (is.null(alphabet)) {
    alphabet <- c(LETTERS, letters, as.character(0:9), strsplit("!#$%&*+-./:;<=>?@^_~", "")[[1L]])
  }
  if (!is.character(alphabet) || anyNA(alphabet) || any(nchar(alphabet) != 1L) ||
      anyDuplicated(alphabet) || length(alphabet) < length(states)) {
    stop("`alphabet` must provide at least one unique character per observed state.",
         call. = FALSE)
  }
  characters <- alphabet[seq_along(states)]
  key <- data.frame(event_name = states, character = characters, stringsAsFactors = FALSE)
  strings <- apply(wide$wide, 1L, function(row) {
    row <- as.character(row)
    row <- row[!is.na(row) & nzchar(row)]
    paste(characters[match(row, states)], collapse = "")
  })
  result <- list(
    events = wide$wide,
    event_names = states,
    characters = characters,
    key = key,
    strings = stats::setNames(as.character(strings), wide$sequence_ids),
    sequence_ids = wide$sequence_ids
  )
  class(result) <- c("gp3_grpstring_input", "list")
  result
}

#' Convert sequence data to seqHMM observations
#'
#' @param data Long-format sequence data.
#' @param sequence_id_col,order_col,state_col Sequence columns.
#' @param ... Additional arguments passed to [as_traminer_sequences()].
#'
#' @return A TraMineR `stslist` suitable for `seqHMM::build_hmm()`.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' if (requireNamespace("TraMineR", quietly = TRUE) &&
#'     requireNamespace("seqHMM", quietly = TRUE)) {
#'   as_seqhmm_sequences(sequences)
#' }
#'
#' @export
as_seqhmm_sequences <- function(data,
                                sequence_id_col = "sequence_id",
                                order_col = "sequence_order",
                                state_col = "state", ...) {
  .sequence_adv_require("seqHMM", "prepare seqHMM observations")
  as_traminer_sequences(data, sequence_id_col, order_col, state_col, ...)
}

#' Convert a transition network to an igraph object
#'
#' @param network A first-order transition network.
#' @param directed Whether the resulting graph is directed.
#'
#' @return An `igraph` graph with edge attributes copied from the network.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' network <- create_transition_network(sequences)
#' if (requireNamespace("igraph", quietly = TRUE)) {
#'   as_igraph_transition_network(network)
#' }
#'
#' @export
as_igraph_transition_network <- function(network, directed = TRUE) {
  .sequence_adv_scalar_logical(directed, "directed")
  .sequence_adv_require("igraph", "create an igraph transition network")
  if (!inherits(network, "gp3_transition_network")) {
    stop("`network` must be created by `create_transition_network()`.", call. = FALSE)
  }
  settings <- attr(network, "settings")
  if (!identical(settings$order, 1L)) {
    stop("Only first-order networks can be converted directly to igraph.", call. = FALSE)
  }
  group_cols <- attr(network, "group_cols")
  if (length(group_cols) > 0L && nrow(unique(network[, group_cols, drop = FALSE])) > 1L) {
    stop("Select one network group before converting to igraph.", call. = FALSE)
  }
  edges <- network[, c("from_state", "to_state", "weight", "count",
                       "sequence_count", "sequence_prevalence"), drop = FALSE]
  igraph::graph_from_data_frame(edges, directed = directed)
}

#' Prepare common gp3tools-style sequence outputs
#'
#' This optional compatibility helper recognises ordinary data frames or lists
#' containing a data-frame component and maps common sequence-column names to
#' the neutral gp3sequences contract. It does not require a gp3tools class.
#'
#' @param data A data frame or list with a data-frame `data` component.
#' @param sequence_id_col,order_col,state_col Optional explicit mappings.
#' @param duration_col Optional duration mapping.
#' @param metadata_cols Optional constant-within-sequence metadata columns.
#' @param ... Additional arguments passed to [prepare_sequence_data()].
#'
#' @return A standard gp3sequences preparation result.
#' @examples
#' sequences <- data.frame(
#'   sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
#'   sequence_order = rep(1:4, times = 4L),
#'   state = c("A", "B", "C", "D", "A", "B", "C", "C",
#'             "D", "C", "B", "A", "D", "C", "A", "A"),
#'   group = rep(c("g1", "g2"), each = 8L),
#'   stringsAsFactors = FALSE
#' )
#' names(sequences)[names(sequences) == "sequence_order"] <- "position"
#' names(sequences)[names(sequences) == "state"] <- "aoi_label"
#' prepare_gp3tools_sequences(sequences)
#'
#' @export
prepare_gp3tools_sequences <- function(data,
                                       sequence_id_col = NULL,
                                       order_col = NULL,
                                       state_col = NULL,
                                       duration_col = NULL,
                                       metadata_cols = NULL, ...) {
  if (is.list(data) && !is.data.frame(data) && !is.null(data$data)) data <- data$data
  if (!is.data.frame(data)) stop("A data frame or list with a data-frame `data` component is required.",
                                 call. = FALSE)
  choose_first <- function(explicit, candidates, role) {
    if (!is.null(explicit)) return(explicit)
    found <- candidates[candidates %in% names(data)]
    if (length(found) == 0L) stop("Could not infer the ", role, " column. Supply it explicitly.",
                                  call. = FALSE)
    if (length(found) > 1L) {
      stop("Multiple candidate ", role, " columns were found: ",
           paste(found, collapse = ", "), ". Supply the mapping explicitly.",
           call. = FALSE)
    }
    found[1L]
  }
  sequence_id_col <- choose_first(sequence_id_col,
                                  c("sequence_id", "scanpath_id", "trial_id", "participant_trial_id"),
                                  "sequence identifier")
  order_col <- choose_first(order_col,
                            c("sequence_order", "position", "event_order", "fixation_index", "row_order"),
                            "sequence order")
  state_col <- choose_first(state_col,
                            c("state", "aoi", "aoi_label", "event", "event_name"),
                            "state")
  if (is.null(duration_col)) {
    found_duration <- c("duration", "fixation_duration", "event_duration")
    found_duration <- found_duration[found_duration %in% names(data)]
    if (length(found_duration) > 1L) {
      stop("Multiple candidate duration columns were found: ",
           paste(found_duration, collapse = ", "),
           ". Supply `duration_col` explicitly.", call. = FALSE)
    }
    if (length(found_duration) == 1L) duration_col <- found_duration[1L]
  }
  prepare_sequence_data(data,
                        sequence_id_col = sequence_id_col,
                        order_col = order_col,
                        state_col = state_col,
                        duration_col = duration_col,
                        metadata_cols = metadata_cols, ...)
}
