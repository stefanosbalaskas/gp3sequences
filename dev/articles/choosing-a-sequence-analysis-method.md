# Choosing a Sequence-Analysis Method

## Start with the research question

No single sequence method is universally preferable. Method choice
should be driven by the declared structural question, the sequence
representation, the intended comparison, and the assumptions that can be
defended. Every workflow should begin with
[`audit_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/audit_sequence_data.md),
[`validate_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/validate_sequence_data.md),
and, when needed,
[`prepare_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/prepare_sequence_data.md).

``` r

method_guide <- data.frame(
  question = c(
    "Which exact contiguous patterns recur?",
    "What state is most supported at each aligned position?",
    "How do observed state, transition, or length summaries differ by group?",
    "How dissimilar are complete sequences?",
    "Can a declared distance reveal reproducible descriptive partitions?",
    "Which transitions and contexts organise the observed paths?",
    "Does recent state history improve next-state description?",
    "Can a compact latent categorical model summarise serial dependence?",
    "Is interoperability with a specialist package required?"
  ),
  method = c(
    "Contiguous motifs",
    "Aligned-position consensus",
    "Descriptive group comparison",
    "Sequence distance",
    "Clustering and stability",
    "Transition network",
    "Higher-order transition model",
    "Categorical HMM or mixture HMM",
    "Optional adapter"
  ),
  primary_functions = c(
    "extract_sequence_ngrams(); summarise_sequence_motifs()",
    "create_consensus_sequence(); summarise_consensus_agreement()",
    "compare_sequence_groups()",
    "compute_sequence_distance(); summarise_sequence_distance()",
    "cluster_sequences(); validate_sequence_clusters(); bootstrap_sequence_clusters()",
    "create_transition_network(); summarise_transition_centrality()",
    "fit_higher_order_transition_model(); predict_next_state()",
    "fit_sequence_hmm(); fit_sequence_hmm_mixture(); decode_sequence_states()",
    "as_traminer_sequences(); as_arules_sequences(); as_igraph_transition_network()"
  ),
  stringsAsFactors = FALSE
)

method_guide
#>                                                                  question
#> 1                                  Which exact contiguous patterns recur?
#> 2                  What state is most supported at each aligned position?
#> 3 How do observed state, transition, or length summaries differ by group?
#> 4                                  How dissimilar are complete sequences?
#> 5     Can a declared distance reveal reproducible descriptive partitions?
#> 6             Which transitions and contexts organise the observed paths?
#> 7               Does recent state history improve next-state description?
#> 8     Can a compact latent categorical model summarise serial dependence?
#> 9                 Is interoperability with a specialist package required?
#>                           method
#> 1              Contiguous motifs
#> 2     Aligned-position consensus
#> 3   Descriptive group comparison
#> 4              Sequence distance
#> 5       Clustering and stability
#> 6             Transition network
#> 7  Higher-order transition model
#> 8 Categorical HMM or mixture HMM
#> 9               Optional adapter
#>                                                                  primary_functions
#> 1                           extract_sequence_ngrams(); summarise_sequence_motifs()
#> 2                     create_consensus_sequence(); summarise_consensus_agreement()
#> 3                                                        compare_sequence_groups()
#> 4                       compute_sequence_distance(); summarise_sequence_distance()
#> 5 cluster_sequences(); validate_sequence_clusters(); bootstrap_sequence_clusters()
#> 6                   create_transition_network(); summarise_transition_centrality()
#> 7                        fit_higher_order_transition_model(); predict_next_state()
#> 8         fit_sequence_hmm(); fit_sequence_hmm_mixture(); decode_sequence_states()
#> 9   as_traminer_sequences(); as_arules_sequences(); as_igraph_transition_network()
```

## Contiguous motifs

Use motifs when the unit of interest is an exact adjacent state window.
Declare minimum and maximum length, overlap handling, prevalence
denominators, filtering thresholds, and tie rules. Motifs do not capture
non-contiguous subsequences unless an external specialist method is
used.

## Consensus sequences

Use aligned-position consensus when positions are meaningfully
comparable across sequences. Declare the missing-position policy,
weighting, state order, and deterministic tie method. A consensus is a
modal structural summary, not a normative or ideal pathway.

## Descriptive group comparison

Use
[`compare_sequence_groups()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/compare_sequence_groups.md)
when the objective is to compare observed state shares, transition
shares, prevalence, or sequence lengths across declared groups. The
function is deliberately descriptive and does not automatically perform
significance tests or causal attribution.

## Distances

[`compute_sequence_distance()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/compute_sequence_distance.md)
supports four explicit families:

- Levenshtein distance for unit-cost edits;
- LCS distance for differences based on longest common subsequences;
- configurable optimal matching for declared insertion/deletion and
  substitution costs;
- transition-profile Euclidean distance for first-order transition
  distributions.

Normalisation and cost choices can materially change the geometry.
Report them and avoid selecting a distance solely because it produces
visually convenient clusters.

## Clustering, representatives, ensembles, and stability

Clustering is a downstream description of a chosen distance matrix.
Declare `k`, the clustering method, linkage, seed, and any
optional-package settings. Use validation and resampling summaries to
assess the supplied solution, not to claim that clusters are objectively
true. Representatives minimise declared within-cluster distance; they
are not automatically typical in a substantive sense.

## Transition networks

Use first-order networks when nodes and directed edges are the relevant
representation. Declare whether weights are counts, conditional
proportions, or global shares; whether self-transitions are included;
and whether grouping or smoothing is used. Centrality and communities
are graph-structural outputs, not psychological attributes.

## Higher-order transition models

Use higher-order models when recent context is part of the structural
question. Declare the order, smoothing, context separator, and backoff
policy. Inspect which context and order were actually used for every
prediction, especially for unseen contexts.

## Hidden and mixture sequence models

Use the native HMM helpers only for compact, time-homogeneous
categorical workflows. Report initial values, seed, pseudocount,
tolerance, convergence history, likelihood, AIC/BIC, and decoding
method. Hidden-state labels and mixture components are exchangeable
statistical constructs. Multiple seeded fits and specialist software are
appropriate when the model is consequential or more complex.

## Optional adapters

Adapters support TraMineR, arulesSequences, GrpString-style inputs,
seqHMM, igraph, and common gp3tools-style column names without making
those packages or formats mandatory. Use them when a specialist engine
adds functionality that should not be duplicated inside `gp3sequences`.

## Minimum decision checklist

Before analysis, record:

1.  the sequence unit and ordering variable;
2.  state definitions and any preprocessing policy;
3.  whether positions are aligned and comparable;
4.  the structural estimand or descriptive question;
5.  method parameters, costs, thresholds, seeds, and normalisation;
6.  how missing positions, ties, unseen contexts, and optional
    dependencies are handled;
7.  sensitivity checks and failure cases;
8.  the interpretation boundary separating structure from substantive
    claims.

## Focused articles

The package website provides dedicated articles for contiguous motifs,
consensus and group comparison, distances and clustering, transition
networks, higher-order models, latent models, and optional adapters. The
synthetic case study demonstrates how these layers can be combined
without treating every method as mandatory.
