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
