# Bootstrap sequence-cluster stability

Uses repeated subsampling without replacement and records pairwise
co-clustering agreement relative to the full-data solution.

## Usage

``` r
bootstrap_sequence_clusters(
  distance,
  k,
  method = c("hierarchical", "pam", "clara"),
  n_boot = 100L,
  sample_fraction = 0.8,
  seed = 1L,
  linkage = "average",
  ...
)
```

## Arguments

- distance:

  Sequence distance object.

- k:

  Number of clusters.

- method:

  Clustering method.

- n_boot:

  Number of subsamples.

- sample_fraction:

  Fraction of sequences sampled in each iteration.

- seed:

  Reproducibility seed.

- linkage:

  Hierarchical linkage.

- ...:

  Additional clustering arguments.

## Value

An object of class `gp3_sequence_cluster_bootstrap`.

## Examples

``` r
sequences <- data.frame(
  sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
  sequence_order = rep(1:4, times = 4L),
  state = c("A", "B", "C", "D", "A", "B", "C", "C",
            "D", "C", "B", "A", "D", "C", "A", "A"),
  group = rep(c("g1", "g2"), each = 8L),
  stringsAsFactors = FALSE
)
distance <- compute_sequence_distance(sequences)
bootstrap_sequence_clusters(distance, k = 2L, n_boot = 5L, seed = 1L)
#> $original
#> $assignments
#> s1 s2 s3 s4 
#>  1  1  2  2 
#> 
#> $model
#> 
#> Call:
#> (function (d, method = "complete", members = NULL) {    METHODS <- c("ward.D", "single", "complete", "average", "mcquitty",         "median", "centroid", "ward.D2")    if (method == "ward") {        message("The \"ward\" method has been renamed to \"ward.D\"; note new \"ward.D2\"")        method <- "ward.D"    }    i.meth <- pmatch(method, METHODS)    if (is.na(i.meth))         stop("invalid clustering method", paste("", method))    if (i.meth == -1)         stop("ambiguous clustering method", paste("", method))    n <- as.integer(attr(d, "Size"))    if (is.null(n))         stop("invalid dissimilarities")    if (is.na(n) || n > 65536L)         stop("size cannot be NA nor exceed 65536")    if (n < 2)         stop("must have n >= 2 objects to cluster")    len <- as.integer(n * (n - 1)/2)    if (length(d) != len)         (if (length(d) < len)             stop        else warning)("dissimilarities of improper length")    if (is.null(members))         members <- rep(1, n)    else if (length(members) != n)         stop("invalid length of members")    storage.mode(d) <- "double"    hcl <- .Fortran(C_hclust, n = n, len = len, method = as.integer(i.meth),         ia = integer(n), ib = integer(n), crit = double(n), members = as.double(members),         nn = integer(n), disnn = double(n), diss = d)    hcass <- .Fortran(C_hcass2, n = n, ia = hcl$ia, ib = hcl$ib,         order = integer(n), iia = integer(n), iib = integer(n))    structure(list(merge = cbind(hcass$iia[1L:(n - 1)], hcass$iib[1L:(n -         1)]), height = hcl$crit[1L:(n - 1)], order = hcass$order,         labels = attr(d, "Labels"), method = METHODS[i.meth],         call = match.call(), dist.method = attr(d, "method")),         class = "hclust")})(d = structure(c(1, 4, 4, 4, 4, 1), Labels = c("s1", "s2", "s3", "s4"), Size = 4L, call = as.dist.default(m = matrix_distance), class = "dist", Diag = FALSE, Upper = FALSE),     method = "average")
#> 
#> Cluster method   : average 
#> Number of objects: 4 
#> 
#> 
#> $medoids
#> [1] "s1" "s3"
#> 
#> $k
#> [1] 2
#> 
#> $method
#> [1] "hierarchical"
#> 
#> $linkage
#> [1] "average"
#> 
#> $distance
#>    s1 s2 s3
#> s2  1      
#> s3  4  4   
#> s4  4  4  1
#> 
#> $seed
#> [1] 1
#> 
#> attr(,"class")
#> [1] "gp3_sequence_clustering" "list"                   
#> 
#> $pairwise_stability
#>    s1 s2 s3 s4
#> s1  1  1  1  1
#> s2  1  1  1  1
#> s3  1  1  1  1
#> s4  1  1  1  1
#> 
#> $evaluated_counts
#>    s1 s2 s3 s4
#> s1  4  2  3  3
#> s2  2  3  2  2
#> s3  3  2  4  3
#> s4  3  2  3  4
#> 
#> $iterations
#>   iteration n_sampled average_silhouette
#> 1         1         3                0.5
#> 2         2         3                0.5
#> 3         3         3                0.5
#> 4         4         3                0.5
#> 5         5         3                0.5
#> 
#> $overall
#>   n_boot sample_fraction mean_pairwise_stability min_pairwise_stability
#> 1      5             0.8                       1                      1
#> 
#> $settings
#> $settings$k
#> [1] 2
#> 
#> $settings$method
#> [1] "hierarchical"
#> 
#> $settings$linkage
#> [1] "average"
#> 
#> $settings$n_boot
#> [1] 5
#> 
#> $settings$sample_fraction
#> [1] 0.8
#> 
#> $settings$seed
#> [1] 1
#> 
#> 
#> attr(,"class")
#> [1] "gp3_sequence_cluster_bootstrap" "list"                          
```
