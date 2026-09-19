# Report gp3sequences capabilities and optional integrations

Returns a deterministic, machine-readable inventory of native analytical
capabilities, optional adapters, reference implementations, and
specialist handoffs relevant to the current gp3sequences development
series.

## Usage

``` r
sequence_capabilities(include_optional = TRUE, check_versions = TRUE)
```

## Arguments

- include_optional:

  Logical; include optional/reference capabilities.

- check_versions:

  Logical; report installed optional-package versions.

## Value

A data frame with capability family, capability, implementation role,
backend, availability, and version information. The function never
installs, attaches, or loads optional packages.

## Examples

``` r
capabilities <- sequence_capabilities()
capabilities[c("family", "capability", "role", "available")]
#>                    family                                capability
#> 1              Clustering           Native clustering and stability
#> 2           Data contract                Validation and preparation
#> 3               Distances                 Native sequence distances
#> 4               Distances             Reference distance validation
#> 5                Graphics                     Sequence-plot handoff
#> 6                Graphics                Seriation/ordering handoff
#> 7                    HMMs                  HMM reference validation
#> 8                    HMMs                   Native categorical HMMs
#> 9               Inference Permutation/distance reference validation
#> 10            Missingness               Sequence-imputation handoff
#> 11 Model-based clustering Specialist model-based clustering handoff
#> 12               Networks                    Graph interoperability
#> 13               Networks             Markov-chain interoperability
#> 14               Networks                Native transition networks
#> 15               Patterns     Frequent pattern reference validation
#> 16               Patterns       String/AOI pattern interoperability
#> 17            Performance                              Benchmarking
#> 18       Property testing                    Property-based testing
#>               role available
#> 1           native     FALSE
#> 2           native      TRUE
#> 3           native      TRUE
#> 4        reference     FALSE
#> 5          handoff      TRUE
#> 6          handoff     FALSE
#> 7        reference      TRUE
#> 8           native      TRUE
#> 9        reference     FALSE
#> 10         handoff     FALSE
#> 11         handoff     FALSE
#> 12         adapter      TRUE
#> 13 planned_adapter     FALSE
#> 14          native      TRUE
#> 15       reference      TRUE
#> 16         adapter      TRUE
#> 17     development     FALSE
#> 18     development     FALSE
```
