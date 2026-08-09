# Software availability and manuscript version boundary

`gp3sequences` is publicly available through CRAN. At manuscript
preparation, the public CRAN release is version 0.1.0, while the article's
evaluated computational snapshot is development version 0.2.0.9000 at
repository commit `d863b95a9a05cc2ef8bad00c47a6d2d553dd0772`.

The manuscript therefore distinguishes package availability from the exact
software state used to generate its computational evidence. Submission is
not conditioned on moving or recreating a historical release tag solely to
make the CRAN version string equal the evaluated development version.

## Required submission boundary

1. Keep the exact evaluated repository commit identifiable.
2. Report the public CRAN release separately from the evaluated snapshot.
3. Include the scripts, deterministic data, generated evidence, and
   environment information required to reproduce manuscript results.
4. Re-run the manuscript render and journal checks from current source.
5. Do not move or recreate historical release tags for manuscript purposes.
6. If a later CRAN release is published before acceptance, update the
   availability statement without silently changing the evaluated snapshot.
