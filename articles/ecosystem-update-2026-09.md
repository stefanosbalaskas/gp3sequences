# Ecosystem update — September 2026

## Related crossed repeated-measures method

The related Python package **gpbiometricspy** now includes a fully
exact-main-certified crossed participant–item Gaussian hierarchical
location–scale model with **one location random slope for each crossed
factor**.

This is an ecosystem-level addition, not a new `gp3sequences` sequence
model. `gp3sequences` remains focused on ordered categorical sequences,
scanpaths, motifs, transition structure, distances, clustering,
randomization, and latent-state workflows. The gpbiometricspy method
instead models continuous outcomes with crossed participant/item
heterogeneity in conditional location and residual scale.

Certified gpbiometricspy PR \#129 is pinned to merge SHA
`d078e0366ace49c3ebeb2f6800bad6394d70631e`: 14/14 exact-main push
workflow families, 12/12 OS/Python matrix lanes, 782/782 tests,
14,015/14,015 statements, and 6,757/6,776 raw branches (99.7196%). The
frozen `gpbiometrics 2.0.0` parity surface remains 406/406 and is
unchanged.

- [Crossed participant–item random-slope
  guide](https://stefanosbalaskas.github.io/gpbiometricspy/methods/crossed-random-slopes-location-scale/)
- [gpbiometricspy PR
  \#129](https://github.com/stefanosbalaskas/gpbiometricspy/pull/129)

A study can therefore use sequence methods for ordered process structure
and, where scientifically justified, a separate gpbiometricspy
location–scale model for continuous repeated outcomes without conflating
the two inferential targets.
