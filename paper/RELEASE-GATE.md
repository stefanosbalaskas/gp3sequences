# CRAN 0.2.0 release gate

The manuscript should describe a stable version that readers can install
from CRAN. The repository currently develops version 0.2.0.9000 while the
public CRAN release is 0.1.0.

## Required sequence

1. Freeze public API and manuscript scope.
2. Review reverse dependencies and current CRAN checks.
3. Set DESCRIPTION and current-facing metadata to 0.2.0.
4. Run tests, pkgdown, R CMD check, and external platform checks.
5. Build and submit the source tarball through the CRAN web form.
6. After acceptance, tag and permanently archive the exact release.
7. Make the paper replication bundle verify that exact version.
