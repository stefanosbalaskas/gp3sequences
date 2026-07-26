# gp3sequences 0.3.0 — Master Hardening, Validation, Interoperability, and Release Blueprint

**Status:** implementation specification
**Baseline:** post-0.2.0 development series (`0.2.0.9000`)
**Repository:** `gp3sequences`
**Primary goal:** move from a broad feature-complete development package to a mature, independently validated, auditable 0.3.0 release.
**Rule:** do not add another analytical family merely because another package has one. New work must harden, validate, diagnose, compare, document, or make existing methods safer and more interpretable.

---

## 0. Non-negotiable design principles

1. **Standalone package.** Core functionality accepts ordinary data frames/matrices/lists and must not require `gp3tools`, Gazepoint hardware, proprietary files, or package-specific classes.
2. **Optional interoperability.** Specialist packages are reference implementations, adapters, or documented handoffs. Heavy packages remain optional unless a feature truly cannot function without one.
3. **No psychological inference.** Structural sequence results are not evidence of emotion, cognition, stress, comprehension, diagnosis, intent, personality, or causality.
4. **Auditability over convenience.** IDs, state alphabets, preprocessing decisions, method parameters, random seeds, backend/version information, and diagnostics must be recoverable from analysis outputs wherever technically sensible.
5. **Determinism.** Every stochastic method must accept/record a seed or clearly document why it cannot.
6. **No silent destructive preprocessing.** Missing states, duplicate positions, repeated states, state collapsing, gap handling, and filtering must follow explicit policies.
7. **Reference equivalence only when definitions match.** A native result is compared with an external implementation only after cost, normalization, ordering, missing-state, overlap, weighting, and timing semantics are aligned.
8. **Correctness before performance.** Benchmarks measure time/memory but never replace numerical/reference validation.
9. **Failure is data.** Degenerate and weakly identified cases must produce explicit errors, warnings, review flags, or documented diagnostics—not misleading polished output.
10. **API freeze after hardening foundation.** Once the common contract layer is merged, analytical breadth is frozen unless a benchmark reveals a correctness or usability hole that cannot be solved within the existing family.

---

## 1. Baseline to preserve

At the start of this program, the development branch exposes **78 public functions** across:

- sequence validation/preparation;
- encoding and structural summaries;
- motifs and motif positions;
- consensus and descriptive group comparison;
- distances, clustering, representatives, ensembles, and bootstrap stability;
- transition networks and higher-order models;
- ordinary and mixture HMMs;
- optional ecosystem adapters;
- longitudinal/panel workflows;
- bounded non-contiguous subsequences;
- time-varying models;
- multichannel and covariate HMMs;
- design-aware permutation/bootstrap inference;
- extended visualisations.

The current development version remains `0.2.0.9000` until the final release branch. Do not move or recreate historical release tags.

### Current public exports (78)

- `as_arules_sequences()`
- `as_grpstring_data()`
- `as_igraph_transition_network()`
- `as_seqhmm_sequences()`
- `as_traminer_sequences()`
- `audit_sequence_data()`
- `bootstrap_sequence_clusters()`
- `bootstrap_sequence_group_difference()`
- `bootstrap_transition_network()`
- `cluster_sequences()`
- `compare_sequence_groups()`
- `compare_sequence_hmms()`
- `compare_sequence_panel_changes()`
- `compare_sequence_subsequences()`
- `compute_sequence_distance()`
- `create_consensus_sequence()`
- `create_sequence_cluster_ensemble()`
- `create_transition_network()`
- `declare_sequence_comparison_design()`
- `decode_covariate_sequence_states()`
- `decode_multichannel_sequence_states()`
- `decode_sequence_states()`
- `detect_transition_communities()`
- `encode_sequence_data()`
- `extract_representative_sequences()`
- `extract_sequence_ngrams()`
- `extract_sequence_subsequences()`
- `filter_sequence_motifs()`
- `filter_sequence_subsequences()`
- `fit_covariate_sequence_hmm()`
- `fit_higher_order_transition_model()`
- `fit_multichannel_sequence_hmm()`
- `fit_sequence_hmm()`
- `fit_sequence_hmm_mixture()`
- `fit_time_varying_sequence_model()`
- `format_consensus_sequence()`
- `format_sequence_motif_positions()`
- `format_sequence_motifs()`
- `format_sequence_paths()`
- `plot_consensus_sequence()`
- `plot_multichannel_sequence_hmm()`
- `plot_sequence_cluster_silhouette()`
- `plot_sequence_distance_heatmap()`
- `plot_sequence_entropy()`
- `plot_sequence_group_comparison()`
- `plot_sequence_group_inference()`
- `plot_sequence_index()`
- `plot_sequence_motif_positions()`
- `plot_sequence_motifs()`
- `plot_sequence_panel_changes()`
- `plot_sequence_state_distribution()`
- `plot_sequence_subsequences()`
- `plot_time_varying_sequence_model()`
- `plot_transition_network()`
- `predict_covariate_transition_probabilities()`
- `predict_next_state()`
- `predict_time_varying_sequence_model()`
- `prepare_gp3tools_sequences()`
- `prepare_sequence_data()`
- `prepare_sequence_panel()`
- `summarise_consensus_agreement()`
- `summarise_covariate_sequence_hmm()`
- `summarise_multichannel_sequence_hmm()`
- `summarise_sequence_cluster_stability()`
- `summarise_sequence_distance()`
- `summarise_sequence_group_inference()`
- `summarise_sequence_hmm()`
- `summarise_sequence_motif_positions()`
- `summarise_sequence_motifs()`
- `summarise_sequence_panel()`
- `summarise_sequence_states()`
- `summarise_sequence_subsequences()`
- `summarise_sequence_transitions()`
- `summarise_time_varying_sequence_model()`
- `summarise_transition_centrality()`
- `test_sequence_group_difference()`
- `validate_sequence_clusters()`
- `validate_sequence_data()`

---

## 2. External reference ecosystem

Use external packages to answer four questions: **Does the native method agree where it should? When does it fail? How sensitive is it? When should users hand the problem to a specialist package?**

| Domain | Primary reference packages | 0.3.0 use |
|---|---|---|
| General state-sequence analysis | TraMineR, TraMineRextras | distance/reference validation, representatives, dissimilarity association, method handoff |
| Generic edit distance | stringdist | independent Levenshtein parity and performance |
| Clustering/typology | cluster, WeightedCluster, clusterCrit, clue; fpc locally | partition comparison, quality, stability, null-structure diagnostics |
| Frequent patterns | arules, arulesSequences, GrpString | contiguous/non-contiguous support semantics and interoperability |
| Hidden Markov models | seqHMM | simulation, parameter recovery, multichannel/covariate comparison |
| Networks/Markov chains | igraph, markovchain, tna, Nestimate | transition matrices, centrality, entropy, bootstrap stability, structural handoff |
| Missing sequence data | seqimpute | documented specialist handoff; no silent native imputation |
| Model-based sequence clustering | MEDseq | comparison article/handoff, not native duplication |
| Sequence graphics/orderings | ggseqplot, seriation | visual ecosystem and heatmap ordering handoff |
| Additional specialist methods | seqhandbook | documented ecosystem scope |
| Permutation/distance inference | vegan, energy, coin | independent inferential cross-checks where semantics match |
| Property testing | quickcheck, hedgehog | generated invariant tests and shrinking |
| QA/performance | bench, microbenchmark, covr, waldo, lintr, cyclocomp | development-only quality layer |

**Version note:** package versions are a snapshot and must be rechecked before implementation/release. The blueprint depends on capabilities, not pinned version numbers.

---

# PART A — COMPLETE PUBLIC API HARDENING

## 3. Analysis contracts, provenance, and capability audit

### 3.1 `sequence_capabilities()`

**Purpose:** machine-readable inventory of native features and optional integrations available in the current R library.

**Proposed signature**

```r
sequence_capabilities(
  include_optional = TRUE,
  check_versions = TRUE
)
```

**Return:** data frame with at least:

- `family`
- `capability`
- `native`
- `backend`
- `backend_required`
- `available`
- `installed_version`
- `minimum_tested_version` (only when the project explicitly records one)
- `reference_only`
- `notes`

**Requirements:**

- never installs packages;
- never loads optional packages with `library()`;
- uses `requireNamespace(..., quietly = TRUE)`;
- deterministic row order;
- works with no optional packages installed;
- distinguishes *native*, *adapter*, *reference-only*, and *documentation handoff* capabilities.

### 3.2 `audit_sequence_analysis()`

```r
audit_sequence_analysis(
  x,
  strict = FALSE
)
```

Extract/validate:

- object class;
- package and contract version;
- analysis family and method;
- parameters;
- sequence/participant/trial/session/stimulus identifiers when retained;
- sequence count and state alphabet;
- preprocessing decisions;
- seed/randomness status;
- backend and backend version;
- diagnostics and review flags;
- interpretation level: descriptive / associational / model-based / inferential;
- missing provenance fields;
- whether the object satisfies the declared contract.

**Return:** classed list containing `summary`, `issues`, `provenance`, `contract`, `status`.

### 3.3 `compare_sequence_analysis_results()`

```r
compare_sequence_analysis_results(
  x,
  y,
  tolerance = sqrt(.Machine$double.eps),
  compare_metadata = TRUE,
  compare_numeric = TRUE
)
```

Purpose: regression and cross-version comparison of two gp3sequences results. Report structural mismatches, numeric discrepancies, label permutations, missing provenance, and differences expected purely from ordering/labeling.

**Do not** silently coerce fundamentally incompatible result families.

---

## 4. Internal contract layer (not exported)

Implement a small shared internal layer rather than bespoke logic in every function:

```r
.sequence_contract()
.sequence_object_contract()
.sequence_contract_version()
.validate_sequence_result()
.validate_distance_matrix()
.validate_probability_matrix()
.validate_transition_matrix()
.validate_clustering_object()
.validate_hmm_object()
.record_sequence_provenance()
.restore_sequence_metadata()
.align_state_levels()
.align_sequence_ids()
.align_partition_labels()
.check_sequence_seed()
.check_probability_simplex()
.check_optional_backend()
.sequence_test_case()
```

### Mandatory contract checks

- stable IDs and dimnames;
- explicit alphabet/state ordering;
- no duplicated sequence identifiers where uniqueness is required;
- probability rows sum to one within tolerance;
- distance matrices are square, finite where promised, symmetric where promised, and zero-diagonal where promised;
- transition matrices preserve state labels and normalization semantics;
- clustering vectors align exactly to sequence IDs;
- result metadata never changes the numerical result;
- seed/provenance metadata is attached without changing object usability.

---

# PART B — DISTANCE VALIDATION AND SENSITIVITY

## 5. `compare_sequence_distance_methods()`

```r
compare_sequence_distance_methods(
  x,
  y,
  labels = c("x", "y"),
  top_k = 1L,
  tolerance = 1e-8,
  scale = c("raw", "unit_mean", "unit_max")
)
```

Accept two compatible distance matrices/`dist` objects. Align IDs before comparison.

Return:

- Pearson/Spearman agreement of upper triangles;
- MAE, RMSE, maximum absolute discrepancy;
- zero-distance agreement;
- nearest-neighbour agreement;
- top-k neighbour overlap;
- pairwise rank inversions;
- scale ratio;
- number of compared pairs;
- incompatible/missing IDs;
- method metadata.

**Reference checks:**

- native Levenshtein ↔ `stringdist`;
- native LCS ↔ TraMineR under equivalent semantics;
- native OM ↔ TraMineR with identical substitution/indel costs and normalization.

## 6. `summarise_sequence_distance_sensitivity()`

```r
summarise_sequence_distance_sensitivity(
  data,
  configurations,
  reference = 1L,
  neighbour_k = 1L,
  cluster_k = NULL,
  cluster_method = NULL
)
```

`configurations` explicitly stores metric + parameter combinations. Quantify changes in:

- distance correlation;
- nearest-neighbour identity;
- top-k neighbour overlap;
- cluster partition agreement when requested;
- representative sequence stability;
- rank stability.

No automatic “best parameter” selection.

## 7. Distance plots

### `plot_sequence_distance_agreement()`

Scatter of pairwise distances from two methods, identity line, optional residual panel, labelled largest disagreements.

### `plot_sequence_ordination()`

Classical MDS (`stats::cmdscale`) from a supplied distance object. Optional groups/clusters/labels. Must expose stress/eigenvalue warnings when low-dimensional representation is poor.

### `plot_sequence_distance_sensitivity()`

Heatmap or ordered path of method/configuration agreement, neighbour stability, or cluster agreement. No hidden parameter ranking.

---

# PART C — CLUSTER ROBUSTNESS

## 8. `compare_sequence_cluster_solutions()`

```r
compare_sequence_cluster_solutions(
  ...,
  labels = NULL,
  ids = NULL
)
```

Accept named cluster assignments or gp3sequences clustering objects. Align IDs and normalize cluster-label permutations.

Compute where defined:

- Rand index;
- adjusted Rand index;
- pairwise co-membership agreement;
- cluster-size consistency;
- medoid/representative overlap;
- discordant-sequence table.

## 9. `summarise_sequence_cluster_robustness()`

```r
summarise_sequence_cluster_robustness(
  solutions,
  stability = NULL,
  distance_metadata = NULL
)
```

Summarise across k, algorithms, distances, parameter grids, bootstrap solutions, or seeds:

- mean/min silhouette where present;
- within/between distance ratio;
- Dunn-like metric when valid;
- ARI distribution;
- bootstrap assignment frequency;
- representative/medoid stability;
- cluster-size variation;
- unstable sequence IDs;
- co-clustering uncertainty.

## 10. Cluster plots

### `plot_sequence_cluster_agreement()`
Agreement matrix across candidate solutions.

### `plot_sequence_cluster_stability_path()`
Stability metric against k/configuration with uncertainty when available.

### `plot_sequence_coclustering()`
Pairwise bootstrap co-membership heatmap. Preserve IDs; optionally order by a supplied solution, never silently reorder without recording the ordering.

---

# PART D — HMM SIMULATION, RECOVERY, AND IDENTIFIABILITY

## 11. `simulate_sequence_hmm()`

```r
simulate_sequence_hmm(
  n_sequences,
  sequence_length,
  initial_prob,
  transition_prob,
  emission_prob,
  covariates = NULL,
  transition_coefficients = NULL,
  seed = NULL,
  return_states = TRUE,
  sequence_prefix = "S"
)
```

Support:

- ordinary categorical HMM;
- multichannel categorical emissions;
- covariate-dependent transitions when coefficients are provided;
- scalar or per-sequence lengths;
- known latent states;
- deterministic seeded simulation.

Return `observed`, `hidden`, `truth`, `settings`, `seed`, state/channel metadata.

Validate all probability simplices before simulation.

## 12. `align_sequence_hmm_states()`

```r
align_sequence_hmm_states(
  estimated,
  reference,
  criterion = c("combined", "emission", "transition", "decoded"),
  weights = c(emission = 1, transition = 1, initial = 1)
)
```

Solve label switching. Optional `clue` assignment when available; deterministic exact/permutation fallback for small state spaces.

Return mapping, aligned parameters, cost matrix, total assignment cost, ambiguity flags.

## 13. `diagnose_sequence_hmm()`

```r
diagnose_sequence_hmm(
  model,
  boundary = 1e-6,
  rare_state_threshold = 0.01,
  separation_tolerance = 1e-4
)
```

Diagnostics:

- convergence status / iteration count;
- log-likelihood history and monotonicity;
- initial/transition/emission simplex validity;
- near-zero and near-one parameters;
- occupancy and rare/unused states;
- state separation and near-duplicate emissions/transitions;
- decoding length consistency;
- numerical underflow/nonfinite checks;
- model degeneracy status;
- optional initialization sensitivity summary.

## 14. `assess_sequence_hmm_recovery()`

```r
assess_sequence_hmm_recovery(
  fitted,
  truth,
  hidden_truth = NULL,
  align = TRUE
)
```

Metrics after alignment:

- initial probability MAE/RMSE/max error;
- transition MAE/RMSE/max error;
- emission MAE/RMSE/max error;
- hidden-state accuracy when truth is known;
- ARI/label-invariant decoded agreement where meaningful;
- occupancy recovery;
- convergence/failure indicators;
- log-likelihood metadata.

## 15. `compare_sequence_hmm_initializations()`

```r
compare_sequence_hmm_initializations(
  fits,
  align = TRUE,
  reference = c("best_loglik", "first")
)
```

Quantify local-optimum sensitivity across seeds/initializations: likelihood spread, parameter agreement, decoded-state agreement, occupancy agreement, failure rate.

## 16. HMM plots

### `plot_sequence_hmm_diagnostics()`
Convergence/log-likelihood, occupancy, parameter-boundary and state-separation views.

### `plot_sequence_state_probabilities()`
Posterior/smoothed state probabilities across sequence position when available. If a fitted object only contains hard decoding, fail clearly rather than fabricate posterior probabilities.

### `plot_sequence_hmm_recovery()`
Truth-versus-estimate parameters across one or multiple simulation replications, after label alignment.

---

# PART E — NETWORK ROBUSTNESS, ENTROPY, AND MARKOV INTEROPERABILITY

## 17. `summarise_transition_entropy()`

```r
summarise_transition_entropy(
  x,
  base = 2,
  normalize = TRUE,
  stationary = TRUE
)
```

Calculate:

- state-specific outgoing entropy;
- normalized entropy where mathematically defined;
- effective branching number;
- stationary distribution (when identifiable/ergodic or with explicit documented handling);
- stationary-weighted entropy;
- global entropy rate;
- zero-outdegree/absorbing-state diagnostics.

## 18. `compare_transition_networks()`

```r
compare_transition_networks(
  x,
  y,
  align_states = TRUE,
  tolerance = 1e-8
)
```

Return edge-level and node-level changes:

- signed/absolute/relative edge difference;
- edge presence/absence;
- edge-rank change;
- centrality change when provided/derivable;
- entropy change;
- bootstrap compatibility and interval overlap when present.

## 19. Extend `bootstrap_transition_network()`

Do not add a second bootstrap API. Extend the existing result contract with:

- edge bootstrap mean;
- edge SD;
- percentile CI;
- edge selection frequency;
- edge rank stability;
- centrality mean/SD/CI;
- centrality rank stability;
- seed and resampling metadata.

Maintain backwards-compatible existing fields wherever possible.

## 20. `as_markovchain_transition_model()`

```r
as_markovchain_transition_model(
  x,
  name = "gp3sequences_transition_model"
)
```

Optional adapter to `markovchain`. Validate square row-stochastic transition matrix, preserve state names, reject incompatible count-only objects unless normalization is explicitly requested elsewhere.

## 21. Network plots

### `plot_transition_stability()`
Edge/centrality stability with CI/selection frequency.

### `plot_transition_difference()`
Signed transition difference matrix/network between two conditions/groups.

### `plot_transition_entropy()`
State-specific entropy/effective branching and optional global entropy summary.

---

# PART F — PATTERN AND SUBSEQUENCE VALIDATION

## 22. `compare_sequence_pattern_methods()`

```r
compare_sequence_pattern_methods(
  x,
  y,
  pattern_col = "pattern",
  support_cols = NULL,
  tolerance = 1e-8
)
```

Compare motif/subsequence outputs by:

- normalized pattern identity;
- sequence prevalence;
- occurrence count;
- support;
- rank;
- matched sequences;
- matched positions;
- missing/extra patterns;
- support disagreement.

Mandatory metamorphic relation: bounded non-contiguous mining under the package's documented `max_gap = 0` semantics must be explicitly tested against contiguous motifs where definitions truly coincide.

## 23. Pattern plots

### `plot_sequence_subsequence_coverage()`
Rows = sequences; columns = positions; marks = positions participating in selected pattern(s). Support multiple pattern overlays only if legibility is preserved.

### `plot_sequence_pattern_agreement()`
Support/rank/reference agreement across engines; highlight unmatched patterns.

---

# PART G — DISTANCE-BASED GROUP INFERENCE

## 24. `test_sequence_distance_association()`

```r
test_sequence_distance_association(
  distance,
  group,
  strata = NULL,
  permutations = 9999L,
  seed = 1L
)
```

Return:

- within-group discrepancy;
- between-group discrepancy;
- pseudo-F-style statistic or clearly named equivalent;
- effect proportion / variance-like fraction only if definition is mathematically defensible;
- permutation distribution;
- permutation p-value;
- exact/exhaustive flag for tiny designs when implemented;
- strata/permutation design;
- seed;
- interpretation boundary.

No causal language. Reject invalid strata/group lengths and distance-ID mismatches.

## 25. `summarise_sequence_distance_association()`

Compact inferential summary plus design/limitations.

## 26. `plot_sequence_distance_association()`

Permutation/null distribution with observed statistic and optional group-distance diagnostic. Must not visually imply causal effects.

---

# PART H — MISSINGNESS DIAGNOSTICS

## 27. `summarise_sequence_missingness()`

```r
summarise_sequence_missingness(
  data,
  sequence_id_col,
  order_col,
  state_col,
  group_col = NULL
)
```

Summaries:

- missing count/proportion by sequence;
- missing count/proportion by position;
- number/length of missing runs;
- longest missing run;
- leading/internal/trailing missingness;
- affected sequences;
- optional group summaries.

This function **does not impute**.

## 28. `plot_sequence_missingness()`

Sequence × position missingness map plus optional run-length/group summary.

---

# PART I — 35 PLANNED EXPORTS

The complete planned public addition set is:

- `sequence_capabilities()`
- `audit_sequence_analysis()`
- `compare_sequence_analysis_results()`
- `compare_sequence_distance_methods()`
- `summarise_sequence_distance_sensitivity()`
- `plot_sequence_distance_agreement()`
- `plot_sequence_ordination()`
- `plot_sequence_distance_sensitivity()`
- `compare_sequence_cluster_solutions()`
- `summarise_sequence_cluster_robustness()`
- `plot_sequence_cluster_agreement()`
- `plot_sequence_cluster_stability_path()`
- `plot_sequence_coclustering()`
- `simulate_sequence_hmm()`
- `align_sequence_hmm_states()`
- `diagnose_sequence_hmm()`
- `assess_sequence_hmm_recovery()`
- `compare_sequence_hmm_initializations()`
- `plot_sequence_hmm_diagnostics()`
- `plot_sequence_state_probabilities()`
- `plot_sequence_hmm_recovery()`
- `summarise_transition_entropy()`
- `compare_transition_networks()`
- `plot_transition_stability()`
- `plot_transition_difference()`
- `plot_transition_entropy()`
- `as_markovchain_transition_model()`
- `compare_sequence_pattern_methods()`
- `plot_sequence_subsequence_coverage()`
- `plot_sequence_pattern_agreement()`
- `test_sequence_distance_association()`
- `summarise_sequence_distance_association()`
- `plot_sequence_distance_association()`
- `summarise_sequence_missingness()`
- `plot_sequence_missingness()`

**Target public API after completion:** approximately **113 exports** (78 existing + 35 planned), subject only to deliberate consolidation if implementation proves two proposed helpers should share one public entry point.

---

# PART J — ADVERSARIAL / PROPERTY / METAMORPHIC TESTING

## 29. Internal synthetic torture corpus

One internal generator only:

```r
.sequence_test_case(case, seed = 2026L, ...)
```

Required cases:

### Minimal and shape
`minimal`, `empty`, `single_row`, `single_sequence`, `single_state`, `equal_sequences`, `variable_length`

### State-label stress
`rare_states`, `large_alphabet`, `unicode_states`, `whitespace_states`, `very_long_state_labels`, `unused_factor_levels`

### Structural patterns
`high_repetition`, `alternating_states`, `absorbing_sequence`, `cyclic_sequence`

### Missingness
`missing_internal`, `missing_leading`, `missing_trailing`, `high_missingness`

### Ordering/duration/metadata corruption
`duplicate_positions`, `unordered_rows`, `order_gaps`, `noninteger_order`, `negative_duration`, `zero_duration`, `inconsistent_metadata`

### Cluster truth/null
`clustered_truth`, `weak_clusters`, `no_cluster_null`, `singleton_cluster`

### Network truth
`network_sparse`, `network_dense`, `network_disconnected`, `network_absorbing`, `network_cycle`

### HMM truth/degeneracy
`hmm_known_truth`, `hmm_weakly_identified`, `hmm_near_absorbing`, `hmm_duplicate_states`, `hmm_rare_state`, `multichannel_hmm_truth`, `covariate_hmm_truth`

### Group inference
`group_null`, `group_difference_truth`, `imbalanced_groups`

### Panel/time
`panel_null`, `panel_change_truth`, `panel_missing_wave`, `panel_irregular_time`

## 30. Property/metamorphic invariants

### Input/order invariants

- shuffling source rows does not alter order-defined results;
- renaming states permutes labels but preserves label-invariant numerics;
- irrelevant metadata renaming/addition does not alter analytical outputs;
- sequence reordering only permutes rows/columns/IDs;
- translating onset times does not change order-only methods;
- duplicating every sequence preserves proportions and pairwise distances between corresponding originals.

### Distance invariants

- nonnegative;
- zero diagonal;
- symmetry when promised;
- identical sequences have distance zero;
- stable dimnames;
- triangle inequality tested only for methods where mathematically guaranteed;
- reference parity under matched definitions.

### Motif/subsequence invariants

- prevalence in `[0,1]`;
- counts nonnegative integers;
- sequence prevalence never exceeds one;
- overlap-policy behavior is deterministic;
- impossible patterns return zero/empty results cleanly;
- documented `max_gap = 0` relationship tested.

### Clustering invariants

- each sequence assigned exactly once;
- medoids belong to their clusters where method uses medoids;
- silhouette within `[-1,1]` where defined;
- label permutation leaves partition metrics unchanged;
- singleton/all-identical behavior explicitly tested.

### Network invariants

- raw edge counts equal observed adjacent transitions;
- normalized outgoing rows sum to one where defined;
- terminal/isolated states follow contract;
- bootstrap reproducible with seed;
- entropy within mathematical bounds.

### HMM invariants

- all probability simplices valid;
- latent-state relabeling leaves likelihood invariant;
- decoding length equals observation length;
- seeded simulation exactly reproducible;
- state-alignment produces label-invariant recovery metrics;
- weak/degenerate cases produce diagnostics, not silent success.

### Panel/time invariants

- participant IDs preserved;
- missing waves never silently fabricated;
- irregular spacing handled/documented;
- duplicate visit/time keys detected.

### Inference invariants

- p-values in `[0,1]`;
- seed reproducibility;
- tiny exhaustive enumeration matches known exact result when supported;
- null simulations do not systematically reject;
- injected effects increase detectability with information without claiming universal power.

---

## 31. Required test files

```text
tests/testthat/test-contract-invariants.R
tests/testthat/test-metamorphic-invariants.R
tests/testthat/test-adversarial-inputs.R

tests/testthat/test-reference-distances.R
tests/testthat/test-reference-clustering.R
tests/testthat/test-reference-patterns.R
tests/testthat/test-reference-networks.R
tests/testthat/test-reference-hmm.R
tests/testthat/test-reference-inference.R

tests/testthat/test-hmm-recovery.R
tests/testthat/test-network-stability.R
tests/testthat/test-distance-sensitivity.R
tests/testthat/test-cluster-robustness.R
tests/testthat/test-missingness.R
tests/testthat/test-analysis-audit.R
tests/testthat/test-capabilities.R
```

Reference tests must use `skip_if_not_installed()` only for genuinely optional external packages. Native contract safeguards must never be skipped.

---

# PART K — REFERENCE BENCHMARK / QA SUITE

## 32. Development benchmark tree

```text
dev/
  benchmarks/
    benchmark-distances.R
    benchmark-clustering.R
    benchmark-patterns.R
    benchmark-networks.R
    benchmark-hmm.R
    benchmark-scaling.R
    benchmark-memory.R
  reference/
    reference-traminer.R
    reference-stringdist.R
    reference-weightedcluster.R
    reference-arulesSequences.R
    reference-grpstring.R
    reference-seqhmm.R
    reference-igraph.R
    reference-markovchain.R
    reference-tna.R
    reference-nestimate.R
    reference-inference.R
  qa/
    run-coverage.R
    run-lintr.R
    run-complexity.R
    run-reference-suite.R
    run-adversarial-suite.R
    run-benchmarks.R
    audit-public-api.R
    audit-documentation.R
```

### Benchmark dimensions

- number of sequences;
- sequence length;
- alphabet size;
- pair count;
- motif/subsequence search space;
- max pattern length/gap;
- HMM state count;
- channel count;
- network density;
- bootstrap/permutation iterations.

### Benchmark outputs

- median/elapsed time;
- memory allocation;
- result size;
- scaling ratio;
- numerical/reference discrepancy;
- failure/degeneracy rate where applicable.

**Never** add wall-clock thresholds to ordinary unit tests.

---

# PART L — REFERENCE VALIDATION MATRIX

| Native target | Reference | Required comparison |
|---|---|---|
| Levenshtein | stringdist | exact/numerical parity under same encoding |
| LCS | TraMineR | parity under matched representation/normalization |
| Optimal matching | TraMineR | parity under identical substitution/indel costs |
| Cluster partition | cluster / WeightedCluster | assignment/quality agreement where algorithms coincide |
| Cluster robustness | WeightedCluster / clusterCrit / clue | quality/stability/partition comparisons |
| Representatives | TraMineR `seqrep()` | semantic comparison; equality only when definitions truly coincide |
| Motifs/subsequences | TraMineR / arulesSequences / GrpString | support/prevalence/pattern identity under equivalent constraints |
| Ordinary HMM | seqHMM | simulation/likelihood/parameter recovery under matched specification |
| Multichannel HMM | seqHMM | simulated recovery and decoded-state comparison |
| Covariate HMM | seqHMM | transition probability/recovery comparison under matched model |
| Transition matrix | markovchain / tna / Nestimate | counts/probabilities/state ordering |
| Network centrality | igraph | numerical parity for identical graph definition |
| Transition entropy | Nestimate or hand calculation | numerical parity under same log base/normalization |
| Distance group association | TraMineR / TraMineRextras / vegan / energy / coin | null/effect behavior; exact equality only under same statistic/permutation design |

All reference scripts must record package versions and the precise semantic assumptions used to declare two computations comparable.

---

# PART M — PLOTS (16 NEW DIAGNOSTIC VISUALS)

1. `plot_sequence_distance_agreement()` — pairwise native/reference agreement and discrepancies.
2. `plot_sequence_ordination()` — MDS map with explicit low-dimensional-fit diagnostics.
3. `plot_sequence_distance_sensitivity()` — method/parameter sensitivity.
4. `plot_sequence_cluster_agreement()` — partition agreement matrix.
5. `plot_sequence_cluster_stability_path()` — stability across k/configurations.
6. `plot_sequence_coclustering()` — bootstrap co-membership uncertainty.
7. `plot_sequence_hmm_diagnostics()` — convergence, occupancy, boundary/separation diagnostics.
8. `plot_sequence_state_probabilities()` — posterior/smoothed latent-state probability trajectories when available.
9. `plot_sequence_hmm_recovery()` — truth-vs-estimate recovery.
10. `plot_transition_stability()` — edge/centrality bootstrap stability.
11. `plot_transition_difference()` — signed edge differences between networks.
12. `plot_transition_entropy()` — state entropy/effective branching/global entropy.
13. `plot_sequence_subsequence_coverage()` — sequence-position coverage of selected patterns.
14. `plot_sequence_pattern_agreement()` — native/reference support/rank agreement.
15. `plot_sequence_distance_association()` — observed vs permutation null distribution.
16. `plot_sequence_missingness()` — missingness structure by sequence/position/group.

### Plot contract common rules

- base R is acceptable; no new mandatory plotting dependency;
- deterministic ordering;
- return plot-relevant data invisibly or expose an explicit data component where existing package style supports it;
- no substantive/psychological labels inferred from states;
- handle empty/singleton/degenerate cases with informative errors/warnings;
- all plots get automated smoke tests using temporary graphics devices;
- plotting tests must never leave `Rplots.pdf` in the repository.

---

# PART N — ARTICLES / WEBSITE

## 33. Ten new hardening articles

### 1. API Contracts, Provenance, and Reproducibility
`vignettes/api-contracts-and-provenance.Rmd`

Sections: canonical data/result contracts, IDs, alphabets, seeds, method metadata, `sequence_capabilities()`, `audit_sequence_analysis()`, comparison/regression workflow, interpretation boundary.

### 2. Validating Sequence Distances Against Reference Implementations
`vignettes/reference-validation-sequence-distances.Rmd`

TraMineR/stringdist comparisons; OM costs; LCS semantics; normalization; neighbour agreement; sensitivity; when numerical parity should and should not be expected.

### 3. Robust Sequence Clustering: Sensitivity, Stability, and Null Structure
`vignettes/robust-sequence-clustering.Rmd`

Distance × algorithm × k; silhouette/partition agreement; co-clustering; representative stability; WeightedCluster/clusterCrit/clue/fpc handoffs; null-structure caution.

### 4. Simulation, Recovery, and Identifiability for Categorical HMMs
`vignettes/hmm-simulation-recovery-identifiability.Rmd`

Known-truth simulation; label switching; state alignment; weak identification; near-absorbing states; initialization sensitivity; multichannel/covariate recovery; seqHMM reference.

### 5. Transition Network Stability and Entropy
`vignettes/transition-network-stability-and-entropy.Rmd`

Counts/probabilities; entropy; bootstrap edge/centrality stability; group differences; igraph/markovchain/tna/Nestimate cross-checks.

### 6. Cross-Ecosystem Subsequence Mining
`vignettes/subsequence-reference-comparisons.Rmd`

Contiguous vs bounded non-contiguous semantics; gap/window definitions; TraMineR/cSPADE/GrpString comparisons; rule-mining handoff.

### 7. Adversarial Sequence Analysis: Failure Atlas
`vignettes/adversarial-sequence-analysis.Rmd`

Broken orders, duplicates, missing states, degenerate clusters, weak HMMs, disconnected networks, tiny inference samples; expected error/review/diagnostic behavior.

### 8. Missing Sequence Data and Imputation Handoffs
`vignettes/missing-sequence-data-and-imputation.Rmd`

Missingness summaries/plots; structural missingness; explicit policies; why gp3sequences does not silently impute; seqimpute handoff.

### 9. Interoperability with the R Sequence Ecosystem
`vignettes/sequence-ecosystem-interoperability.Rmd`

TraMineR, TraMineRextras, WeightedCluster, MEDseq, seqHMM, arulesSequences, GrpString, ggseqplot, tna, Nestimate, markovchain, seriation, seqimpute, and gp3tools optional adapter.

### 10. Performance, Scaling, and Reproducible Benchmarking
`vignettes/performance-and-scaling.Rmd`

Scaling dimensions, time/memory methodology, correctness-first benchmarking, reference versions, thresholds for handing work to specialist implementations. Do not promise universal performance superiority.

## 34. Rewrite existing method-selection article

Substantially revise:

`vignettes/choosing-a-sequence-analysis-method.Rmd`

Turn it into the canonical decision tree answering:

- structural summary vs motif vs subsequence;
- distances and clustering;
- network/higher-order transition analysis;
- ordinary/multichannel/covariate latent models;
- longitudinal/time-varying analysis;
- descriptive vs inferential group comparison;
- native gp3sequences vs TraMineR/seqHMM/arulesSequences/WeightedCluster/MEDseq/seqimpute handoff.

## 35. Site target

Current 15 articles + 10 new = **25 articles**, plus the article index. The exact HTML count is validated after build; do not hard-code generated-page counts in source text unless intentionally documenting a release snapshot.

---

# PART O — README, NEWS, PKGDOWN, DOCUMENTATION AUDIT

## 36. README additions

Add sections:

### Validation philosophy
Explain contract tests, adversarial tests, reference comparisons, recovery simulation, and the validation ledger.

### Reference implementations
Explain that external packages are scientific comparators/handoffs, not hidden dependencies.

### When to use another package

Use gp3sequences when auditability, ordinary data-frame inputs, transparent sequence workflows, and integrated diagnostics are priorities.

Document handoffs to:

- TraMineR for broader mature sequence methods/distance families;
- seqHMM for advanced latent-state workflows beyond the native contract;
- arulesSequences for cSPADE/sequential rules at specialist scale;
- WeightedCluster for weighted typology analysis and specialist validation;
- MEDseq for model-based sequence clustering;
- seqimpute for specialist missing-sequence imputation;
- ggseqplot/seriation for specialist visual ordering/graphics.

## 37. `_pkgdown.yml` new reference sections

Add coherent groups:

- Analysis contracts and provenance
- Distance diagnostics and sensitivity
- Cluster robustness
- HMM simulation and diagnostics
- Network robustness and entropy
- Pattern validation
- Distance-based inference
- Missingness diagnostics
- External interoperability

Do not dump all new functions under “Extended visualisations”.

## 38. NEWS organization

Keep heading `gp3sequences 0.2.0.9000` until the release branch. Organize bullets under:

- API hardening
- Reference validation
- Distance robustness
- Cluster robustness
- Latent-model diagnostics
- Network validation
- Pattern validation
- Inference
- Missingness
- Documentation
- Testing
- Benchmarking

## 39. Documentation audit

`dev/qa/audit-documentation.R` must verify:

- every export has a `.Rd` topic or deliberate shared topic;
- every export appears in `_pkgdown.yml` exactly where intended;
- every new analytical object has `@return` documentation;
- every stochastic helper documents seed behavior;
- optional dependencies are guarded and listed only if used;
- all examples are deterministic and warning-free;
- all article links/topics resolve;
- README article counts match the site if a count is stated;
- stale version/release language is absent.

---

# PART P — VALIDATION LEDGER

## 40. Machine-readable ledger

Create:

`inst/validation/gp3sequences-validation.csv`

Columns:

```text
function
family
api_status
contract_tested
adversarial_tested
reference_package
reference_function
reference_tested
property_tested
seed_tested
plot_tested
example_tested
article
limitations_documented
status
notes
```

Rules:

- one row per public export;
- existing exports start as `existing-needs-hardening` until audited;
- planned exports start as `planned`;
- `reference_tested` may be `not-applicable` when no independent equivalent exists;
- release requires no unexplained `unknown`/blank status for core validation dimensions;
- the ledger records evidence, not marketing claims.

A template CSV is generated alongside this blueprint.

---

# PART Q — OPTIONAL PACKAGE ENVIRONMENT (MANUAL INSTALLATION)

## 41. Reference packages

```r
reference_packages <- c(
  "TraMineR", "TraMineRextras", "WeightedCluster",
  "cluster", "clusterCrit", "clue", "stringdist",
  "arules", "arulesSequences", "GrpString", "seqHMM",
  "igraph", "markovchain", "tna", "Nestimate",
  "seqimpute", "MEDseq", "seqhandbook", "ggseqplot", "seriation",
  "vegan", "energy", "coin"
)
```

## 42. QA/development packages

```r
qa_packages <- c(
  "quickcheck", "hedgehog", "bench", "microbenchmark",
  "covr", "waldo", "lintr", "cyclocomp"
)
```

## 43. Local-comparison-only package

`fpc` may be installed locally for development comparisons but should not automatically enter the package dependency graph.

## 44. DESCRIPTION rule

Do **not** add every installed package to `Suggests`. Add a package only when package code, tests, examples, vignettes, or website builds actually reference it. Packages used only in `dev/` scripts do not need to be declared as runtime/test dependencies.

A manual-install helper script is generated alongside this blueprint; its `install.packages()` calls are commented out so installation remains under user control.

---

# PART R — BRANCH-BY-BRANCH IMPLEMENTATION ROADMAP

## Branch 1 — `feature/api-contract-hardening`

Implement:

- common internal contract/provenance layer;
- `sequence_capabilities()`;
- `audit_sequence_analysis()`;
- `compare_sequence_analysis_results()`;
- validation ledger infrastructure;
- contract/adversarial foundations;
- documentation cross-link audit.

No new analytical methodology.

**After merge: API breadth freeze.**

## Branch 2 — `feature/distance-reference-validation`

Implement:

- `compare_sequence_distance_methods()`;
- `summarise_sequence_distance_sensitivity()`;
- three distance plots;
- stringdist/TraMineR reference tests;
- benchmark script;
- distance validation article.

## Branch 3 — `feature/cluster-robustness`

Implement:

- `compare_sequence_cluster_solutions()`;
- `summarise_sequence_cluster_robustness()`;
- three cluster diagnostic plots;
- WeightedCluster/clusterCrit/clue comparisons;
- robustness article.

## Branch 4 — `feature/hmm-recovery-diagnostics`

Implement:

- simulator;
- state alignment;
- diagnostics;
- recovery;
- initialization comparison;
- three HMM plots;
- seqHMM reference/recovery tests;
- HMM article.

## Branch 5 — `feature/network-validation`

Implement:

- transition entropy;
- network comparison;
- extend existing bootstrap object;
- markovchain adapter;
- three network plots;
- igraph/markovchain/tna/Nestimate reference tests;
- network article.

## Branch 6 — `feature/pattern-reference-validation`

Implement:

- pattern-method comparison;
- coverage/agreement plots;
- TraMineR/arulesSequences/GrpString reference cases;
- subsequence comparison article.

## Branch 7 — `feature/distance-inference`

Implement:

- distance association test;
- summary;
- plot;
- exact tiny-design checks where feasible;
- TraMineR/TraMineRextras/vegan/energy/coin reference analysis;
- inferential documentation.

## Branch 8 — `feature/missingness-diagnostics`

Implement:

- missingness summary;
- missingness plot;
- adversarial missingness tests;
- seqimpute handoff article section/full article.

## Branch 9 — `feature/adversarial-testing`

Complete:

- torture corpus;
- property/metamorphic tests;
- all corruption/degenerate families;
- failure-atlas article;
- QA script for adversarial suite.

## Branch 10 — `feature/reference-benchmarks`

Complete:

- all `dev/reference` scripts;
- all `dev/benchmarks` scripts;
- machine-readable benchmark output format;
- performance/scaling article;
- no performance claims unsupported by reproducible measurements.

## Branch 11 — `feature/hardening-articles`

Complete:

- interoperability article;
- API/provenance article if not already merged;
- rewrite method-selection article;
- README validation philosophy/reference/handoff sections;
- full `_pkgdown.yml` reorganization;
- cross-link and terminology audit;
- article count consistency.

## Branch 12 — `feature/release-0.3.0`

Only after all previous branches are merged and website deployments verified:

- version bump to `0.3.0`;
- NEWS consolidation;
- release metadata/CITATION review;
- final validation ledger freeze;
- full tests/examples/articles/pkgdown/check;
- release commit and PR;
- tag `v0.3.0` only after merge to master;
- GitHub Release;
- Zenodo DOI/version metadata if applicable;
- immediate root pkgdown deployment and public verification;
- local/remote branch cleanup.

---

# PART S — EXACT VALIDATION GATES FOR EVERY BRANCH

Run from Windows CMD in the package root. Never use `git add .`.

```cmd
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::test()"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "pkgdown::build_site(preview = FALSE)"
Rscript --vanilla -e "devtools::check()"
```

Additional hardening gates where relevant:

```cmd
Rscript --vanilla -e "old <- options(warn = 2); on.exit(options(old), add = TRUE); devtools::run_examples()"
```

Run project QA/reference/adversarial scripts explicitly; they should not make ordinary package check impractically slow.

Before staging:

```cmd
git status --short --untracked-files=all
git --no-pager diff --stat
git --no-pager diff --check
```

Stage explicit intended files only, then:

```cmd
git --no-pager diff --cached --stat
git --no-pager diff --cached --check
git --no-pager diff --cached --name-only
```

Required ordinary package gate:

```text
0 errors | 0 warnings | 0 notes
```

Optional reference packages may skip legitimately when unavailable; native safeguards may not.

---

# PART T — RELEASE 0.3.0 ACCEPTANCE CRITERIA

0.3.0 is not ready until all of the following are true:

### API / contracts

- all current and new exports audited;
- every export assigned to a coherent pkgdown family;
- no accidental duplicate/near-duplicate public functions;
- provenance/seed/method metadata consistent where applicable;
- backward compatibility reviewed and any intentional incompatibility documented.

### Tests

- ordinary full suite 0 fail / 0 warn / 0 skip except legitimate optional-package skips;
- adversarial suite clean;
- property/metamorphic suite clean;
- reference suite clean where optional packages are available;
- HMM recovery cases meet predeclared simulation expectations without overclaiming universal performance;
- exact tiny permutation cases validated;
- no test leaves graphics/artifacts behind.

### Examples/articles

- all examples warning-free under `warn = 2` where technically feasible;
- all 25 articles render independently and in full site build;
- specialist handoffs guarded when optional packages absent;
- no private files or external local paths;
- synthetic data only.

### Documentation

- README and site counts consistent;
- NEWS complete;
- all reference topics indexed;
- method-selection article reflects complete API;
- limitations and interpretation boundaries explicit;
- external reference semantics documented.

### Benchmarking

- correctness comparisons saved/reproducible;
- performance scripts record package/R/platform versions;
- no unsupported superiority claims;
- scaling limits documented where observed.

### Validation ledger

- one row per public export;
- no unexplained blank validation state;
- reference validation marked `not-applicable` where no true comparator exists rather than fabricated;
- limitations documented for all analytical families.

### Package/site/release

- `devtools::check()` 0/0/0;
- `pkgdown::check_pkgdown()` clean;
- site builds with all reference/article pages;
- no `Rplots.pdf` or stray benchmark output in tracked source;
- clean Git status before commit/tag;
- release tag points permanently to merged release commit;
- public site verified after merge;
- historical release tags untouched.

---

# PART U — THINGS DELIBERATELY NOT NATIVE IN 0.3.0

Do not add merely for breadth:

- every TraMineR distance family (e.g. TWED/DHD/etc.);
- a second general sequence-imputation engine;
- a native cSPADE/sequential-rule implementation;
- full MEDseq model-based clustering;
- a duplicate ggseqplot ecosystem;
- every tna/Nestimate network type;
- deep learning / black-box sequence modelling;
- psychological-state interpretation;
- automatic “best method” selection;
- automatic cluster-number selection without diagnostics;
- automatic HMM-state-number selection presented as truth.

These belong in references, adapters, or documented handoffs unless a future independently justified roadmap says otherwise.

---

# PART V — DEFINITION OF DONE

The 0.3.0 program is complete when gp3sequences is not just **feature-rich**, but demonstrably **auditable, adversarially tested, externally cross-checked, simulation-validated where applicable, sensitivity-aware, interoperable, and explicit about its method boundaries**.

The release narrative should be conservative:

> gp3sequences 0.3.0 hardens its existing sequence-analysis families with common analysis contracts, provenance auditing, adversarial and property-based validation, independent reference comparisons, sensitivity and stability diagnostics, HMM simulation/recovery assessment, transition-network uncertainty and entropy diagnostics, pattern/reference comparisons, distance-based permutation inference, missingness diagnostics, and expanded reproducibility documentation.

Do not claim that every method is universally superior, statistically validated for every use case, or interchangeable with specialist implementations. The validation evidence must specify exactly what was tested and under what assumptions.
