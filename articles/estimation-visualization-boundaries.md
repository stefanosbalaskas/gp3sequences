# Effect-size visualizations for sequence analysis: design boundaries

[DABEST estimation plots](https://acclab.github.io/DABEST-python/) make
sense for *scalar* outcomes extracted from ordered sequences, such as
participant-level transition probability, dwell fraction or entropy
under explicitly declared exposure denominators. They do not justify
treating transitions from the same participant as independent
observations.

Use the maintained R [dabestr
package](https://acclab.github.io/dabestr/) directly to show a
Gardner–Altman or Cumming plot if a scalar participant-level mean
difference is the scientific target. For a paired design use the same
person in both groups and a paired resampling contract.

For time-varying transitions, HMM state probabilities, scanpath
distances and repeated trials, retain the current
`plot_sequence_group_inference`, `plot_time_varying_sequence_model`, and
other estimator-specific uncertainty visualizations. Generic raw mean
differences cannot reproduce their temporal, compositional or
hierarchical estimands.

This article adds no speculative sequence estimator and does not modify
the published package public namespace.
