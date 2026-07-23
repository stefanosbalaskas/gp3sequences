# Cluster sequences from a distance object

Cluster sequences from a distance object

## Usage

``` r
cluster_sequences(
  distance,
  k,
  method = c("hierarchical", "pam", "clara"),
  linkage = "average",
  seed = 1L,
  ...
)
```

## Arguments

- distance:

  A `dist` object or square matrix.

- k:

  Number of clusters.

- method:

  `"hierarchical"`, `"pam"`, or `"clara"`.

- linkage:

  Hierarchical linkage method.

- seed:

  Reproducibility seed for optional stochastic methods.

- ...:

  Additional arguments passed to the selected clustering function.

## Value

A list of class `gp3_sequence_clustering` containing assignments, model
object, medoid identifiers where available, and settings.

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
cluster_sequences(distance, k = 2L)
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
```
