# Manuscript outline

## Working title

gp3sequences: Transparent, Reproducible, and Auditable Analysis of Ordered Categorical Sequences in R

## 1. Introduction

Define ordered categorical sequences for a broad R audience; explain the
fragmentation of data representations and specialist workflows; identify the
gap filled by explicit contracts, diagnostics, interpretation boundaries, and
provenance; and state complementary rather than replacement positioning.

## 2. Related R software

Compare TraMineR, seqHMM, arulesSequences, WeightedCluster, ClickClust, PST,
and march using verified primary sources and a method-neutral feature matrix.

## 3. Design principles

Neutral long-format inputs; explicit mappings and preprocessing policies;
deterministic ordering and seeds; ordinary data-frame outputs; machine-readable
diagnostics; structural interpretation boundaries; optional dependencies; and
guarded interoperability.

## 4. Integrated workflow

Audit and preparation; summaries; motifs and subsequences; consensus and group
comparisons; distances and clustering; transition networks and higher-order
models; HMM workflows; longitudinal, time-varying, and design-aware workflows.

## 5. Analysis contracts and provenance

Present `sequence_capabilities()`, `audit_sequence_analysis()`, and
`compare_sequence_analysis_results()` as the unifying software contribution.

## 6. Integrated reproducible case study

Use synthetic or open data and one coherent path from input audit through
analysis and provenance comparison. Keep complete reproduction under ten minutes.

## 7. Performance and scalability

Report elapsed time, memory where measurable, failures, and practical limits
across sequence count, length, state cardinality, and method-specific bounds.

## 8. Limitations

State structural interpretation limits, optional-backend constraints,
combinatorial boundaries, and the absence of automatic method selection.

## 9. Discussion and reproducibility statement

Record the exact release, permanent archive, replication script, benchmark
outputs, session information, open data, and generated figures.
