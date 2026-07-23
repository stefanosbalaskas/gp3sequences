# Create a sequence-cluster ensemble

Combines multiple named cluster assignments through a co-association
matrix and applies hierarchical clustering to `1 - co-association`.

## Usage

``` r
create_sequence_cluster_ensemble(..., k, linkage = "average")
```

## Arguments

- ...:

  Two or more `gp3_sequence_clustering` objects or named assignment
  vectors.

- k:

  Number of consensus clusters.

- linkage:

  Hierarchical linkage applied to the co-association distance.

## Value

An object of class `gp3_sequence_cluster_ensemble` containing the
consensus assignments, co-association matrix, model, and source
solutions.

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
d1 <- compute_sequence_distance(sequences, method = "lcs")
d2 <- compute_sequence_distance(sequences, method = "transition")
create_sequence_cluster_ensemble(cluster_sequences(d1, 2L),
                                 cluster_sequences(d2, 2L), k = 2L)
#> $assignments
#> s1 s2 s3 s4 
#>  1  1  2  2 
#> 
#> $coassociation
#>    s1 s2 s3 s4
#> s1  1  1  0  0
#> s2  1  1  0  0
#> s3  0  0  1  1
#> s4  0  0  1  1
#> 
#> $distance
#>    s1 s2 s3
#> s2  0      
#> s3  1  1   
#> s4  1  1  0
#> 
#> $model
#> 
#> Call:
#> stats::hclust(d = ensemble_distance, method = linkage)
#> 
#> Cluster method   : average 
#> Number of objects: 4 
#> 
#> 
#> $source_assignments
#> $source_assignments[[1]]
#> s1 s2 s3 s4 
#>  1  1  2  2 
#> 
#> $source_assignments[[2]]
#> s1 s2 s3 s4 
#>  1  1  2  2 
#> 
#> 
#> $k
#> [1] 2
#> 
#> $linkage
#> [1] "average"
#> 
#> attr(,"class")
#> [1] "gp3_sequence_cluster_ensemble" "list"                         
```
