# Transition Networks and Higher-Order Models

## Synthetic navigation sequences

``` r

paths <- list(
  s1 = c("home", "search", "product", "checkout"),
  s2 = c("home", "search", "product", "home"),
  s3 = c("home", "category", "product", "checkout"),
  s4 = c("home", "category", "home", "search")
)
sequence_data <- do.call(rbind, lapply(seq_along(paths), function(i) {
  data.frame(sequence_id = names(paths)[i],
             sequence_order = seq_along(paths[[i]]),
             state = paths[[i]], stringsAsFactors = FALSE)
}))
```

## First-order transition network

``` r

network <- create_transition_network(
  sequence_data,
  normalise = "from",
  include_self = TRUE
)
network
#>   group_key  context from_state to_state count sequence_count
#> 1   __all__ category   category     home     1              1
#> 2   __all__ category   category  product     1              1
#> 3   __all__     home       home category     2              2
#> 4   __all__     home       home   search     3              3
#> 5   __all__  product    product checkout     2              2
#> 6   __all__  product    product     home     1              1
#> 7   __all__   search     search  product     2              2
#>   sequence_prevalence    weight
#> 1                0.25 0.5000000
#> 2                0.25 0.5000000
#> 3                0.50 0.4000000
#> 4                0.75 0.6000000
#> 5                0.50 0.6666667
#> 6                0.25 0.3333333
#> 7                0.50 1.0000000
summarise_transition_centrality(network)
#>      state out_degree in_degree total_degree out_strength in_strength
#> 1 category          2         1            3            1   0.4000000
#> 2 checkout          0         1            1            0   0.6666667
#> 3     home          2         2            4            1   0.8333333
#> 4  product          2         2            4            1   1.5000000
#> 5   search          1         1            2            1   0.6000000
#>   total_strength closeness betweenness  pagerank
#> 1      1.4000000 0.3582090           1 0.1362227
#> 2      0.6666667 0.0000000           0 0.2207604
#> 3      1.8333333 0.3636364           4 0.2020395
#> 4      2.5000000 0.2727273           5 0.2704079
#> 5      1.6000000 0.2857143           1 0.1705694
detect_transition_communities(network)
#>      state community
#> 1 category         1
#> 2 checkout         1
#> 3     home         1
#> 4  product         1
#> 5   search         1
```

Centrality values are graph-structural descriptors. They do not
independently measure attention, importance, intent, or influence.

## Higher-order transition model

``` r

model <- fit_higher_order_transition_model(
  sequence_data,
  order = 2L,
  smoothing = 0.5,
  backoff = TRUE
)
predict_next_state(model, c("home", "search"))
#>   order       context next_state count probability used_order  used_context
#> 1     2 home > search    product     2   0.5555556          2 home > search
#> 2     2 home > search   category     0   0.1111111          2 home > search
#> 3     2 home > search   checkout     0   0.1111111          2 home > search
#> 4     2 home > search       home     0   0.1111111          2 home > search
#> 5     2 home > search     search     0   0.1111111          2 home > search
predict_next_state(model, c("unseen"))
#>   order  context next_state count probability used_order used_context
#> 1     0 <unseen>   category     0         0.2          0     <unseen>
#> 2     0 <unseen>   checkout     0         0.2          0     <unseen>
#> 3     0 <unseen>       home     0         0.2          0     <unseen>
#> 4     0 <unseen>    product     0         0.2          0     <unseen>
#> 5     0 <unseen>     search     0         0.2          0     <unseen>
```

## Whole-sequence bootstrap

``` r

boot <- bootstrap_transition_network(
  sequence_data,
  n_boot = 20L,
  level = 0.95,
  seed = 8L
)
head(boot)
#>   group_key  context from_state to_state count sequence_count
#> 1   __all__ category   category     home     1              1
#> 2   __all__ category   category  product     1              1
#> 3   __all__     home       home category     2              2
#> 4   __all__     home       home   search     3              3
#> 5   __all__  product    product checkout     2              2
#> 6   __all__  product    product     home     1              1
#>   sequence_prevalence    weight bootstrap_mean bootstrap_sd  conf_low conf_high
#> 1                0.25 0.5000000      0.5166667    0.3932917 0.0000000 1.0000000
#> 2                0.25 0.5000000      0.4833333    0.3932917 0.0000000 1.0000000
#> 3                0.50 0.4000000      0.4064286    0.1762160 0.2000000 0.6787500
#> 4                0.75 0.6000000      0.5935714    0.1762160 0.3212500 0.8000000
#> 5                0.50 0.6666667      0.6083333    0.2164641 0.3333333 1.0000000
#> 6                0.25 0.3333333      0.3916667    0.2164641 0.0000000 0.6666667
#>   n_boot confidence_level
#> 1     20             0.95
#> 2     20             0.95
#> 3     20             0.95
#> 4     20             0.95
#> 5     20             0.95
#> 6     20             0.95
```

Bootstrap samples are drawn at the sequence level, preserving
within-sequence transition dependence.
