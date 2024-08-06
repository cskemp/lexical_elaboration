## Counts for each dictionary

See `hathitrust/README.md` for the process we followed to assemble the set of dictionaries.

For each dictionary, we then assembled counts for the set of tokens including nouns, verb, adjectives (`nounverbadj`), and the set of tokens including nouns only (`noun`). In what follows, we illustrate the steps using `nounverbadj` as an example. 

1. Phase 1: go through all dictionaries and keep the most frequent 1500 English forms in each dictionary that have noun, verb or adj as their most common POS tag according to COCA:

`find ../rawdata/downloaded/hathi_raw/*.json.bz2| parallel --eta --jobs 90% -n 50 python read_ht_file.py --phase 1 --pos nounverbadj`

POS tags and COCA frequencies are stored in `../data/forpreprocessing/wordpos.p` and `../data/forpreprocessing/wordposcounts.p`, and were created using `readcoca.py`.

2. Run `make_whitelist.R` and `python add_pos_to_whitelist.py` to make a whitelist `../data/forpreprocessing/whitelist_pos.csv` of words to keep even if they fall below the threshold `mincounts` used in `read_ht_file.py` (step 1). All words on the whitelist are relevant to the analysis of existing claims and case studies. 

3. Assemble the complete set of forms recorded during Phase 1, and add UK variant spellings for all forms and forms from the whitelist. Tokens that have missing POS tags are added to both `nounverbadj` and `noun` versions.

`python make_vocab.py --pos nounverbadj ../data/forpreprocessing/nounverbadj_counts_phase1/*.csv`

4. Phase 2: go through the dictionaries again, and keep counts for all forms belonging to the Phase 1 vocabulary. 

`find ../rawdata/downloaded/hathi_raw/*.json.bz2| parallel --eta --jobs 90% -n 50 python read_ht_file.py --phase 2 --pos nounverbadj`

5. Process non Hathi dictionaries (pdfs, Dictionaria files, and docx files produced by OCR), keeping counts for all forms belonging to the Hathi-derived Phase 1 vocabulary.

` find ../rawdata/downloaded/nonhathi_raw/*.pdf | parallel --eta --jobs 90% -n 50 python read_nonht_file.py --pos nounverbadj`
` find ../rawdata/downloaded/nonhathi_raw/*.csv | parallel --eta --jobs 90% -n 50 python read_nonht_file.py --pos nounverbadj`
` find ../rawdata/downloaded/nonhathi_raw/*.docx | parallel --eta --jobs 90% -n 50 python read_nonht_file.py --pos nounverbadj`


##  Collating counts for all dictionaries

We ran `collate_dics.py` to combine counts for all dictionaries into a single data frame: `python collate_dics.py --pos nounverbadj` 

We then ran `Rscript combine_volumes.R nounverbadj` to combine counts across multiple volumes of the same dictionary (information about multiple volumes is included in `hathi_trust/02_with_gcodes.csv`) and allow for non-Hathi dictionaries that are duplicated in the Hathi set. The resulting data frame is provided in long form (`bila_long_nounverbadj_unfiltered_full.csv`) and in wide form as a matrix of dictionaries by counts (`bila_matrix_nounverbadj_unfiltered_full.csv`) in the folder `../data/biladataset`.


## Wiktionary-based filtering

We ran `wiktionary_extract.ipynb` to identify cases where a form of word or morphological unit in a language coincides with a particular English word (e.g., Afrikaans *die*) and assess whether they share the same meaning or not (e.g. Afrikaans *die* and English *die* have different meanings). Using the resulting data frame `../data/forpreprocessing/wiktionary_forms.tsv`, we then ran `wiktionary_filter.R` to filter the same forms with different meanings. This filtering step is desirable to eliminate spurious noises, such as Afrikaans *die* (which refers to *the* article and hence have many counts). The filtered data frames are under the names `bila_long_nounverbadj_full.csv` and `bila_matrix_nounverbadj_full.csv` in the folder `../data/biladataset`.

We relied on two steps to identify whether the forms share the same meaning or not. First, Wiktionary represents information on English translation of say, Afrikaans *die* as *the* article and Portuguese *perfume* as *perfume*. The former must be treated as different and the latter the same meaning. If the form of English translation is the same as the associated form in another language, we consider them having the same meaning. However, this step cannot identify cases such as Galician *dance* is an inflected form of *danzar* which has the same meaning as English *dance*. To deal with such cases, we used a large cognate dataset ([here](https://github.com/kbatsuren/CogNet)) and considered the two forms sharing the same meaning if they are cognates (e.g., Galician *danzar* and English *dance* are cognates). 

## Full and Standard versions of BILA

We ran `create_bila_dictionaries.R` to create a master file (`../data/biladataset/bila_dictionaries_full.csv`) with information including population size, mode of subsistence, and geographic coordinates for all dictionaries in the data set. This master file is part of the full version of the data set, which includes the following files:

  * `bila_dictionaries_full.csv`: list of dictionaries
  * `bila_matrix_noun_full.csv`: matrix of dictionaries by counts (noun)
  * `bila_matrix_nounverbadj_full.csv`: matrix of dictionaries by counts (noun/verb/adj)
  * `bila_long_noun_full.csv`:  dictionaries by counts in long form (noun)
  * `bila_long_nounverbadj_full.csv`:  dictionaries by counts in long form (noun/verb/adj)
  
We also created a standard version of the dataset by running `standardize_bila.R`, which drops dictionaries with fewer than 5000 tokens and dictionaries where the proportion of English tokens is smaller than 30%, then applies an automated procedure to remove duplicates.  The de-duplication procedure considers relative frequencies of words drawn from a Swadesh list, and considers two dictionaries to be duplicates if the distance between their vectors of Swadesh frequencies is sufficiently close.  Removing duplicates is desirable so we suggest using the standard version by default. Picture dictionaries were also dropped for having narrow contents. The full version may be useful for researchers who want to apply a standardization procedure different from the one used by `standardize_bila.R`. 

The files in the standard version are

  * `bila_dictionaries.csv`: list of dictionaries
  * `bila_matrix_nounverbadj.csv`: matrix of dictionaries by counts (noun/verb/adj)
  * `bila_long_nounverbadj.csv`:  dictionaries by counts in long form (noun/verb/adj)
  * `bila_matrix_noun.csv`: matrix of dictionaries by counts (noun)
  * `bila_long_noun.csv`:  dictionaries by counts in long form (noun)

## Lemmatized version
 
We ran `../preprocessing/wordnet/wordnet_extract.ipynb` to lemmatize words in full version, then for each lemma, we extracted following features from WordNet: number of senses and number of synonyms a lemma has, and number of compounds a lemma is part of. We also added a feature of concreteness rating from Brysbaert et al. (2014). Using the output file `../data/forpreprocessing/lemma_features.tsv`, we ran `standardize_bila.R` to produce a lemmatized version for noun counts in long form: `bila_long_noun_lemmatized.csv` in the folder `../data/biladataset`.
 
 
