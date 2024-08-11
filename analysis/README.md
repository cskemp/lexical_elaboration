## The list of analysis files

  * `read_cru2.R` and `read_cru_ts4.07.R` in `../analysis/environment`: codes to extract temperature and precipitation information.
  * `preliminary_steps.Rmd` : codes to prepare interim results used in subsequent analyses.
  * `analyze_claims.Rmd` : codes to analyze previous claims.
  * `analyze_cases.Rmd` : codes to analyze case studies.
  * `bottomup_analysis.Rmd` : codes to run bottom-up analyses.
  * `make_maps.R` : codes to make maps of BILA languages.
  * `plot_related_lexemes.Rmd` : codes to plot related lexeme counts as a function of unigram counts.
  * `compute_zetas_par.R` and `relatedtermsforapp.Rmd` : codes to obtain results used for the app.
  * `bind_weights_par.R`: functions to compute L^lang and L^fam scores.
  *  `stats_functions.R`: functions for statistical analyses.
  
To reproduce tables and figures, please follow the steps described in the top level `README.md`.
  
## Guideline to create a word list for concepts in case studies

Search Historical Thesaurus of English (HTE) the main terms *snow*, *ice*, *rain*, *wind*, *smell*, *taste*, and *dance*, and select the most relevant node. If you click the node, the list of related terms should appear and follow the below guideline to decide whether to add the term to the list.

- Skip if the term is not used today (e.g., *tidren* for rain)
- Skip if it is compound (e.g., *yellow rain* for rain)
- Skip if it appears region-specific (e.g., *kona* for wind)
- Search the term in WordNet and if it is absent, skip (e.g., *palaeowind* for wind)
- If the definition in WordNet refers to unrelated concept, skip (e.g., *rug* for rain)
- If the definition in WordNet refers to a concept not specifically related to the concept, skip (e.g., *avalanche* 'a slide of large masses of snow and ice and mud down a mountain' for snow)
- If WordNet lists many polysemous entries or the main sense appears to be unrelated concept, skip (e.g., *sheet* for rain)
- If WordNet lists only verbs, skip (e.g., *snowing* for snow)
- Otherwise, add to the list
- Because our analysis is based on lemmatized version which combines UK variant spellings to the US variant spellings (counts for *flavour* is added to the counts of *flavor*), add US variant spellings (HTE lists *flavour* but you have to add *flavor* to the list).
- Some nodes have no subordinate nodes, e.g., *snow*, *rain*, *wind*. However, for those have subordinate nodes, go through the names of those nodes (e.g., *dancer generally*) and collect relevant terms (e.g., *dancer* for dance). No need to go into details of those nodes by clicking, just look through the names of those subordinate nodes. Remember to double check if the terms exist in WordNet. Word lists created following this guideline are included in `analyze_cases.Rmd`. 

