# Package index

## Sequence data contract

- [`audit_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/audit_sequence_data.md)
  : Audit Long-Format Sequence Data
- [`validate_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/validate_sequence_data.md)
  : Validate Long-Format Sequence Data
- [`prepare_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/prepare_sequence_data.md)
  : Prepare Long-Format Sequence Data

## Encoding and structural summaries

- [`encode_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/encode_sequence_data.md)
  : Encode Ordered Sequence States
- [`summarise_sequence_states()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_states.md)
  : Summarise Sequence States
- [`summarise_sequence_transitions()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_transitions.md)
  : Summarise Adjacent Sequence Transitions
- [`format_sequence_paths()`](https://stefanosbalaskas.github.io/gp3sequences/reference/format_sequence_paths.md)
  : Format Ordered Sequence Paths

## Contiguous motif analysis

- [`extract_sequence_ngrams()`](https://stefanosbalaskas.github.io/gp3sequences/reference/extract_sequence_ngrams.md)
  : Extract Contiguous Sequence N-Grams
- [`summarise_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_motifs.md)
  : Summarise Contiguous Sequence Motifs
- [`filter_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/reference/filter_sequence_motifs.md)
  : Filter Sequence Motif Summaries
- [`format_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/reference/format_sequence_motifs.md)
  : Format Sequence Motif Summaries
- [`summarise_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_motif_positions.md)
  : Summarise Sequence Motif Positions
- [`format_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/reference/format_sequence_motif_positions.md)
  : Format Sequence Motif Position Summaries
- [`plot_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_motifs.md)
  : Plot Sequence Motif Summaries
- [`plot_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_motif_positions.md)
  : Plot Sequence Motif Positions

## Consensus and group comparisons

- [`create_consensus_sequence()`](https://stefanosbalaskas.github.io/gp3sequences/reference/create_consensus_sequence.md)
  : Create an aligned-position consensus sequence
- [`summarise_consensus_agreement()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_consensus_agreement.md)
  : Summarise consensus agreement
- [`format_consensus_sequence()`](https://stefanosbalaskas.github.io/gp3sequences/reference/format_consensus_sequence.md)
  : Format consensus sequences as paths
- [`plot_consensus_sequence()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_consensus_sequence.md)
  : Plot a consensus sequence
- [`compare_sequence_groups()`](https://stefanosbalaskas.github.io/gp3sequences/reference/compare_sequence_groups.md)
  : Compare sequence groups descriptively
- [`plot_sequence_group_comparison()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_group_comparison.md)
  : Plot a descriptive sequence-group comparison

## Distances, clustering, and stability

- [`compute_sequence_distance()`](https://stefanosbalaskas.github.io/gp3sequences/reference/compute_sequence_distance.md)
  : Compute pairwise sequence distances
- [`summarise_sequence_distance()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_distance.md)
  : Summarise a sequence-distance object
- [`cluster_sequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/cluster_sequences.md)
  : Cluster sequences from a distance object
- [`validate_sequence_clusters()`](https://stefanosbalaskas.github.io/gp3sequences/reference/validate_sequence_clusters.md)
  : Validate sequence clusters descriptively
- [`extract_representative_sequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/extract_representative_sequences.md)
  : Extract representative sequences from clusters
- [`create_sequence_cluster_ensemble()`](https://stefanosbalaskas.github.io/gp3sequences/reference/create_sequence_cluster_ensemble.md)
  : Create a sequence-cluster ensemble
- [`bootstrap_sequence_clusters()`](https://stefanosbalaskas.github.io/gp3sequences/reference/bootstrap_sequence_clusters.md)
  : Bootstrap sequence-cluster stability
- [`summarise_sequence_cluster_stability()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_cluster_stability.md)
  : Summarise sequence-cluster stability

## Transition networks and higher-order models

- [`create_transition_network()`](https://stefanosbalaskas.github.io/gp3sequences/reference/create_transition_network.md)
  : Create a transition network from ordered sequences
- [`summarise_transition_centrality()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_transition_centrality.md)
  : Summarise transition-network centrality
- [`detect_transition_communities()`](https://stefanosbalaskas.github.io/gp3sequences/reference/detect_transition_communities.md)
  : Detect descriptive transition communities
- [`fit_higher_order_transition_model()`](https://stefanosbalaskas.github.io/gp3sequences/reference/fit_higher_order_transition_model.md)
  : Fit a higher-order transition model
- [`predict_next_state()`](https://stefanosbalaskas.github.io/gp3sequences/reference/predict_next_state.md)
  : Predict the next state from a transition model
- [`bootstrap_transition_network()`](https://stefanosbalaskas.github.io/gp3sequences/reference/bootstrap_transition_network.md)
  : Bootstrap transition-network edge weights

## Hidden and mixture sequence models

- [`fit_sequence_hmm()`](https://stefanosbalaskas.github.io/gp3sequences/reference/fit_sequence_hmm.md)
  : Fit a categorical hidden Markov model
- [`fit_sequence_hmm_mixture()`](https://stefanosbalaskas.github.io/gp3sequences/reference/fit_sequence_hmm_mixture.md)
  : Fit a mixture of categorical hidden Markov models
- [`decode_sequence_states()`](https://stefanosbalaskas.github.io/gp3sequences/reference/decode_sequence_states.md)
  : Decode hidden states from a fitted HMM
- [`summarise_sequence_hmm()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_hmm.md)
  : Summarise a fitted sequence HMM
- [`compare_sequence_hmms()`](https://stefanosbalaskas.github.io/gp3sequences/reference/compare_sequence_hmms.md)
  : Compare fitted sequence HMMs descriptively

## Optional ecosystem adapters

- [`as_traminer_sequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/as_traminer_sequences.md)
  : Convert sequence data to a TraMineR state-sequence object
- [`as_arules_sequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/as_arules_sequences.md)
  : Convert sequence data to cSPADE transaction input
- [`as_grpstring_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/as_grpstring_data.md)
  : Create GrpString-compatible event and string inputs
- [`as_seqhmm_sequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/as_seqhmm_sequences.md)
  : Convert sequence data to seqHMM observations
- [`as_igraph_transition_network()`](https://stefanosbalaskas.github.io/gp3sequences/reference/as_igraph_transition_network.md)
  : Convert a transition network to an igraph object
- [`prepare_gp3tools_sequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/prepare_gp3tools_sequences.md)
  : Prepare common gp3tools-style sequence outputs

## Longitudinal and time-varying extensions

- [`prepare_sequence_panel()`](https://stefanosbalaskas.github.io/gp3sequences/reference/prepare_sequence_panel.md)
  : Prepare longitudinal or panel sequence data
- [`summarise_sequence_panel()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_panel.md)
  : Summarise a sequence panel
- [`compare_sequence_panel_changes()`](https://stefanosbalaskas.github.io/gp3sequences/reference/compare_sequence_panel_changes.md)
  : Compare within-panel sequence changes
- [`plot_sequence_panel_changes()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_panel_changes.md)
  : Plot longitudinal sequence changes
- [`fit_time_varying_sequence_model()`](https://stefanosbalaskas.github.io/gp3sequences/reference/fit_time_varying_sequence_model.md)
  : Fit a time-varying sequence condition model
- [`predict_time_varying_sequence_model()`](https://stefanosbalaskas.github.io/gp3sequences/reference/predict_time_varying_sequence_model.md)
  : Predict a time-varying sequence model
- [`summarise_time_varying_sequence_model()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_time_varying_sequence_model.md)
  : Summarise a time-varying sequence model
- [`plot_time_varying_sequence_model()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_time_varying_sequence_model.md)
  : Plot predicted time-varying sequence probabilities

## Non-contiguous subsequences

- [`extract_sequence_subsequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/extract_sequence_subsequences.md)
  : Extract bounded non-contiguous sequence subsequences
- [`summarise_sequence_subsequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_subsequences.md)
  : Summarise non-contiguous subsequences
- [`filter_sequence_subsequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/filter_sequence_subsequences.md)
  : Filter non-contiguous subsequence summaries
- [`compare_sequence_subsequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/compare_sequence_subsequences.md)
  : Compare subsequence prevalence between groups
- [`plot_sequence_subsequences()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_subsequences.md)
  : Plot non-contiguous subsequence summaries

## Multichannel and covariate HMMs

- [`fit_multichannel_sequence_hmm()`](https://stefanosbalaskas.github.io/gp3sequences/reference/fit_multichannel_sequence_hmm.md)
  : Fit a multichannel categorical hidden Markov model
- [`decode_multichannel_sequence_states()`](https://stefanosbalaskas.github.io/gp3sequences/reference/decode_multichannel_sequence_states.md)
  : Decode latent states from a multichannel HMM
- [`summarise_multichannel_sequence_hmm()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_multichannel_sequence_hmm.md)
  : Summarise a multichannel sequence HMM
- [`plot_multichannel_sequence_hmm()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_multichannel_sequence_hmm.md)
  : Plot multichannel HMM emission profiles
- [`fit_covariate_sequence_hmm()`](https://stefanosbalaskas.github.io/gp3sequences/reference/fit_covariate_sequence_hmm.md)
  : Fit a covariate-dependent categorical hidden Markov model
- [`predict_covariate_transition_probabilities()`](https://stefanosbalaskas.github.io/gp3sequences/reference/predict_covariate_transition_probabilities.md)
  : Predict covariate-dependent transition probabilities
- [`decode_covariate_sequence_states()`](https://stefanosbalaskas.github.io/gp3sequences/reference/decode_covariate_sequence_states.md)
  : Decode states from a covariate-dependent HMM
- [`summarise_covariate_sequence_hmm()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_covariate_sequence_hmm.md)
  : Summarise a covariate-dependent HMM

## Design-aware inference

- [`declare_sequence_comparison_design()`](https://stefanosbalaskas.github.io/gp3sequences/reference/declare_sequence_comparison_design.md)
  : Declare a sequence group-comparison design
- [`test_sequence_group_difference()`](https://stefanosbalaskas.github.io/gp3sequences/reference/test_sequence_group_difference.md)
  : Test a sequence group difference
- [`bootstrap_sequence_group_difference()`](https://stefanosbalaskas.github.io/gp3sequences/reference/bootstrap_sequence_group_difference.md)
  : Bootstrap a sequence group difference
- [`summarise_sequence_group_inference()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_group_inference.md)
  : Summarise sequence group inference
- [`plot_sequence_group_inference()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_group_inference.md)
  : Plot sequence group inference

## Extended visualisations

- [`plot_sequence_index()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_index.md)
  : Plot a sequence index heatmap
- [`plot_sequence_state_distribution()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_state_distribution.md)
  : Plot state distributions over aligned positions
- [`plot_sequence_entropy()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_entropy.md)
  : Plot position-wise state entropy
- [`plot_sequence_distance_heatmap()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_distance_heatmap.md)
  : Plot a sequence-distance heatmap
- [`plot_transition_network()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_transition_network.md)
  : Plot a first-order transition network
- [`plot_sequence_cluster_silhouette()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_cluster_silhouette.md)
  : Plot sequence-cluster silhouette values
