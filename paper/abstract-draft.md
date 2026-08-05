# Abstract draft

`gp3sequences` is an R package for transparent, reproducible, and auditable
analysis of ordered categorical sequences. Existing R software provides
powerful specialist methods for state-sequence analysis, pattern mining,
clustering, transition modelling, and hidden Markov models, but applied
workflows often span incompatible data representations, preprocessing
assumptions, result objects, and optional dependencies. `gp3sequences`
addresses this integration problem through a neutral long-format data
contract, explicit preprocessing policies, deterministic computation,
machine-readable diagnostics, ordinary data-frame outputs, and guarded
interoperability with specialist packages. The package supports structural
summaries, motifs and bounded subsequences, consensus and group comparisons,
sequence distances and clustering, transition networks, higher-order models,
categorical and mixture hidden Markov models, longitudinal and time-varying
workflows, design-aware inference, and extended visualisation. A common
analysis-contract and provenance layer records capabilities, audits supported
results, and compares settings and outputs across analyses. We demonstrate
the package through an integrated reproducible workflow and evaluate
computational scaling across representative sequence designs.
