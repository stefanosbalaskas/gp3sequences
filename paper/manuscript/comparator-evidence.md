# Verified comparator evidence

Primary-source review date: **2026-08-06**.

## Interpretation rules

The comparison is based on documented software purpose rather than function
counts. `not_documented` means only that the reviewed primary sources did not
document the capability; it is not evidence that every package version lacks
the capability. `outside_scope` records a mismatch between a comparison
dimension and the package's declared specialist purpose.

## Defensible positioning

`gp3sequences` should be described as an integration and audit layer, not as a
replacement for specialist packages.

- **TraMineR** is the principal specialist comparator for state-sequence
  definition, description, visualization, and dissimilarities.
- **seqHMM** is the principal comparator for categorical, mixture, multichannel, and covariate-dependent/non-homogeneous hidden Markov models.
  multichannel hidden Markov models.
- **arulesSequences** is the specialist comparator for cSPADE frequent
  sequential-pattern mining with temporal constraints.
- **WeightedCluster** is the specialist comparator for weighted clustering,
  cluster-quality assessment, large-data clustering, and typology validation.
- **ClickClust** is a specialist finite-mixture Markov clustering package.
- **PST** is an archived specialist probabilistic-suffix-tree and variable-memory Markov package; the comparison uses its JSS paper and archived version 0.94.1.
  Markov modeling package.
- **march** is a specialist implementation of several Markovian model families.

The defensible contribution of `gp3sequences` is the common workflow across
ordinary long-format inputs, explicit preparation decisions, structural and
inferential methods, machine-readable diagnostics, optional adapters, analysis
contracts, and provenance comparison.

## Availability at verification

All comparator packages except PST were available from CRAN at the
verification date. PST had been archived from CRAN on 27 November 2025;
the comparison therefore uses its peer-reviewed software paper and latest
archived source version, 0.94.1.

## Prohibited claims

Do not claim that gp3sequences:

- replaces any comparator package;
- implements every specialist method available in those packages;
- is universally faster or statistically superior;
- infers psychological constructs or causal mechanisms from structural outputs;
- proves a comparator lacks a feature because it was not documented.

## Evidence files

- `paper/comparator-source-registry.csv`
- `paper/comparison-inventory.csv`
- `paper/comparator-classification-definitions.csv`
- `paper/feature-comparison-matrix.csv`
- `paper/results/manuscript-comparison-table.csv`
