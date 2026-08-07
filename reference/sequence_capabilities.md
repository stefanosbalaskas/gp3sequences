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
#> Error in sequence_capabilities(): could not find function "sequence_capabilities"
capabilities[c("family", "capability", "role", "available")]
#> Error in capabilities[c("family", "capability", "role", "available")]: object of type 'closure' is not subsettable
```
