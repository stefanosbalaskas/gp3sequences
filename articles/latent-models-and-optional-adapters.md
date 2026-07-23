# Latent Sequence Models and Optional Adapters

## Interpretation boundary

Hidden states and mixture components are statistical constructs. They
must not be labelled as emotions, cognitive states, diagnoses,
intentions, or causal mechanisms without independent theory, design, and
validation.

## Synthetic categorical sequences

``` r

paths <- list(
  s1 = c("A", "A", "B", "B", "C"),
  s2 = c("A", "B", "B", "C", "C"),
  s3 = c("A", "A", "B", "C", "C"),
  s4 = c("C", "C", "B", "B", "A"),
  s5 = c("C", "B", "B", "A", "A"),
  s6 = c("C", "C", "B", "A", "A")
)
sequence_data <- do.call(rbind, lapply(seq_along(paths), function(i) {
  data.frame(sequence_id = names(paths)[i],
             sequence_order = seq_along(paths[[i]]),
             state = paths[[i]], stringsAsFactors = FALSE)
}))
```

## Categorical HMM

``` r

hmm <- fit_sequence_hmm(
  sequence_data,
  n_states = 2L,
  max_iter = 60L,
  seed = 10L
)
summarise_sequence_hmm(hmm)$fit
#>   log_likelihood      aic      bic n_parameters n_observations iterations
#> 1      -30.16079 74.32157 84.12995            7             30         28
#>   converged
#> 1      TRUE
head(decode_sequence_states(hmm, method = "viterbi"))
#>   sequence_id sequence_order observed_state component latent_state
#> 1          s1              1              A         1     latent_2
#> 2          s1              2              A         1     latent_2
#> 3          s1              3              B         1     latent_1
#> 4          s1              4              B         1     latent_1
#> 5          s1              5              C         1     latent_2
#> 6          s2              1              A         1     latent_2
#>   posterior_probability decoding_method
#> 1             0.9999999         viterbi
#> 2             0.5680346         viterbi
#> 3             0.9999997         viterbi
#> 4             0.9999997         viterbi
#> 5             0.5579014         viterbi
#> 6             0.9999999         viterbi

one_state <- fit_sequence_hmm(
  sequence_data,
  n_states = 1L,
  max_iter = 30L,
  seed = 10L
)
compare_sequence_hmms(one_state = one_state, two_state = hmm)
#>       model            class log_likelihood      aic      bic n_parameters
#> 1 one_state gp3_sequence_hmm      -32.95837 69.91674 72.71913            2
#> 2 two_state gp3_sequence_hmm      -30.16079 74.32157 84.12995            7
#>   n_observations converged delta_aic delta_bic
#> 1             30      TRUE  0.000000   0.00000
#> 2             30      TRUE  4.404834  11.41082
```

## Mixture HMM

``` r

mixture <- fit_sequence_hmm_mixture(
  sequence_data,
  n_components = 2L,
  n_states = 2L,
  max_iter = 40L,
  inner_initial_iter = 5L,
  seed = 12L
)
summarise_sequence_hmm(mixture)$mixture
#>   component weight n_states
#> 1         1    0.5        2
#> 2         2    0.5        2
mixture$responsibilities
#>   sequence_id  component_1  component_2 assigned_component
#> 1          s1 1.018440e-12 1.000000e+00                  2
#> 2          s2 1.092078e-13 1.000000e+00                  2
#> 3          s3 1.365095e-13 1.000000e+00                  2
#> 4          s4 1.000000e+00 9.438120e-13                  1
#> 5          s5 1.000000e+00 1.092080e-13                  1
#> 6          s6 1.000000e+00 1.365095e-13                  1
```

## Estimation limitations

The native estimators are compact, dependency-light, time-homogeneous
categorical HMM workflows. EM estimation can converge to local optima,
latent state labels are exchangeable, and AIC or BIC differences do not
validate a substantive interpretation. Analysts should inspect
convergence histories, fit multiple seeded specifications when the
result matters, and use a specialist package such as `seqHMM` for
multichannel, covariate-dependent, or more complex models.

## Optional ecosystem adapters

The adapters are guarded by
[`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) and do not
make specialist packages mandatory dependencies.

``` r

grp_input <- as_grpstring_data(sequence_data)
grp_input$key
#>   event_name character
#> 1          A         A
#> 2          B         B
#> 3          C         C
grp_input$strings
#>      s1      s2      s3      s4      s5      s6 
#> "AABBC" "ABBCC" "AABCC" "CCBBA" "CBBAA" "CCBAA"

if (requireNamespace("TraMineR", quietly = TRUE)) {
  traminer_sequences <- as_traminer_sequences(sequence_data)
  class(traminer_sequences)
}
#>  [>] state coding:
#>        [alphabet]  [label]  [long label]
#>      1  A           A        A
#>      2  B           B        B
#>      3  C           C        C
#>  [>] 6 sequences in the data set
#>  [>] min/max sequence length: 5/5
#> [1] "stslist"    "data.frame"

if (requireNamespace("TraMineR", quietly = TRUE) &&
    requireNamespace("seqHMM", quietly = TRUE)) {
  seqhmm_sequences <- as_seqhmm_sequences(sequence_data)
  class(seqhmm_sequences)
}
#>  [>] state coding:
#>        [alphabet]  [label]  [long label]
#>      1  A           A        A
#>      2  B           B        B
#>      3  C           C        C
#>  [>] 6 sequences in the data set
#>  [>] min/max sequence length: 5/5
#> [1] "stslist"    "data.frame"

if (requireNamespace("arules", quietly = TRUE) &&
    requireNamespace("arulesSequences", quietly = TRUE)) {
  cspade_input <- as_arules_sequences(sequence_data)
  arules::transactionInfo(cspade_input)
}
#>    sequenceID eventID
#> 1           1       1
#> 2           1       2
#> 3           1       3
#> 4           1       4
#> 5           1       5
#> 6           2       1
#> 7           2       2
#> 8           2       3
#> 9           2       4
#> 10          2       5
#> 11          3       1
#> 12          3       2
#> 13          3       3
#> 14          3       4
#> 15          3       5
#> 16          4       1
#> 17          4       2
#> 18          4       3
#> 19          4       4
#> 20          4       5
#> 21          5       1
#> 22          5       2
#> 23          5       3
#> 24          5       4
#> 25          5       5
#> 26          6       1
#> 27          6       2
#> 28          6       3
#> 29          6       4
#> 30          6       5

network <- create_transition_network(sequence_data)
if (requireNamespace("igraph", quietly = TRUE)) {
  graph <- as_igraph_transition_network(network)
  class(graph)
}
#> [1] "igraph"

renamed <- sequence_data
names(renamed)[names(renamed) == "sequence_order"] <- "position"
names(renamed)[names(renamed) == "state"] <- "aoi_label"
prepared <- prepare_gp3tools_sequences(renamed)
prepared$status
#> [1] "review"
```
