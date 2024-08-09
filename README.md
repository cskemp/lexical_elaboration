## Lexical elaboration project

Code and data for project on lexical elaboration across cultures.
This repository contains code, data and experimental materials for:

Khishigsuren, Regier, Vylomova and Kemp, A computational analysis of lexical elaboration across languages


## Folder structure

#### analysis
This folder contains all of our analysis code.

#### data
This folder contains processed dictionary data along with other interim outputs needed for preprocessing and analyses.

#### rawdata
This folder contains downloaded data needed for preprocessing and analyses, and manually created data needed for our analyses.

#### output
Figures, tables and results files generated by the analysis scripts.

#### preprocessing
Code for preparing the data.


## Downloading pdf files for non-HathiTrust dictionaries

We do not provide pdf versions of non-HathiTrust dictionaries in this repository due to copyright issues. They need to be downloaded from the sources mentioned in `rawdata/manuallycreated/nonhathi_dictionaries.csv` and put in the folder `rawdata/downloaded/nonhathi_raw` to reproduce BILA data set.

## Downloading other large files

Large files not uploaded to this repository need to be downloaded from [here](https://unimelbcloud-my.sharepoint.com/:f:/g/personal/tkhishigsure_student_unimelb_edu_au/EooxtyG2XshMldf_wkKcNcoB0xQ3ms1261YAhpC6n68Zjw?e=KukzG2). This contains following files.

  * `data_biladataset` : includes BILA data set files, which are generated by preprocessing steps described in `/preprocessing/README.md`.

  * `output_results` : includes `hierarchical_lr_lang.csv`, results from running hierarchical model on the entire data set, which are generated by running `compute_zetas_par.R` in `analysis` folder.

  * `preprocessing_hathi_trust` : includes `hathi_full_20231101.txt`, a metadata on all volumes downloaded from HathiTrust in late 2023. If needed, recent versions of this file are available [here]( https://www.hathitrust.org/member-libraries/resources-for-librarians/data-resources/hathifiles/ ). The folder also contains `ef_filelisting.txt`, which includes volume ids and can be downloaded using

    `rsync -azv data.analytics.hathitrust.org::features-2020.03/listing/file_listing.txt .`

  * `rawdata_downloaded` : includes a cognate data set `CogNet-v2.0.tsv` and a Wiktionary dump file `enwiktionary-20240320-pages-articles-multistream`, which are used for Wiktionary-based filtering. If needed, the cognate data set is available [here]( https://github.com/kbatsuren/CogNet ) and the Wiktionary dump file [here]( https://dumps.wikimedia.org/enwiktionary/20240320/ ). It also includes the folder `cru_4.07` which contains climate data downloaded from [here](https://crudata.uea.ac.uk/cru/data/hrg/cru_ts_4.07/).

Files must be put in the correct folder in order to reproduce BILA data set and results from analyses. BILA data set files should be put in `data/biladataset`, results from hierarchical model in `output/results`, HathiTrust file in `preprocessing/hathi_trust`, and the cognate, Wiktionary, and the climate data files in `rawdata/downloaded` folder.


## Installing R Libraries 

From within R, run

`> renv::restore()`

to install packages used by the code in this repository

## Python version

This code was developed using Python 3.11. See `environment.yml` for a full specification of the environment used.

## Reproducing BILA data set


A. Assemble the set of dictionaries from HathiTrust (see `../preprocessing/hathi_trust/README.md`).

1) Run first `python read_glottolog_language_names.py > ../../data/forpreprocessing/glottolog_variant_names.tsv` and then `make_language_re.R` to collect language names and alternative names from Glottolog.

2) Run `python read_hathi_list.py > ../../preprocessing/hathi_trust/01_initial_volumes.csv` to extract all candidate volumes with "ictionar" in the title that also met some other conditions described in `../preprocessing/hathi_trust/README.md`.

3) Run `filtered_to_gcode.R` to produce guesses about the correct glottocode and language name to all candidate volumes.

4) Make a manual pass through all candidate volumes to mark volumes to be deleted, following the guideline described in `../preprocessing/hathi_trust/README.md`. Otherwise, use our manually-edited version of the file `02_with_gcodes_manual.csv`.

5) Run `gcode_to_final_hathilist.R` to drop volumes marked for deletion and to produce the final list of volumes. 

6) Convert the IDs of all volumes in the final list using `htid2rsync --from-file 02_hathi_ids.txt > 02_hathi_ids_sanitized.txt`, where `htid2rsync` is a command line utility installed as part of the htrc-feature-reader package.

7) Download counts for all volumes in the final list using `rsync -av --no-relative --files-from 02_hathi_ids_sanitized.txt data.analytics.hathitrust.org::features-2020.03/ ../../rawdata/downloaded/hathi_raw/`. Change the path as needed.


B. Assemble unigram frequencies (see `../preprocessing/README.md`). Steps 3 through 8 assemble counts for nouns, verbs and adjectives -- the same steps should be repeated using "--pos noun" to assemble counts for nouns alone.

1) First run `python readcoca.py` to create POS tags and COCA frequencies.

2) Run `make_whitelist.R` and `python add_pos_to_whitelist.py` to make a whitelist of words relevant to the analysis of existing claims and case studies.

3) Run `find ../rawdata/downloaded/hathi_raw/*.json.bz2| parallel --eta --jobs 90% -n 50 python read_ht_file.py --phase 1 --pos nounverbadj` to go through all dictionaries and keep the most frequent 1500 English forms ("Phase 1 vocabulary") in each dictionary that have noun, verb or adj as their most common POS tag according to COCA. Note that `parallel` is a UNIX command-line utility.

4) Run `python make_vocab.py --pos nounverbadj ../data/forpreprocessing/nounverbadj_counts_phase1/*.csv` to assemble the complete set of forms recorded during Phase 1, and add UK variant spellings for all forms and forms from the whitelist.

5) Run `find ../rawdata/downloaded/hathi_raw/*.json.bz2| parallel --eta --jobs 90% -n 50 python read_ht_file.py --phase 2 --pos nounverbadj` go through the dictionaries again, and keep counts for all forms belonging to the Phase 1 vocabulary.

6) To process non-HathiTrust dictionaries, keeping counts for all forms belonging to the Hathi-derived Phase 1 vocabulary, run the code below:

  * ` find ../rawdata/downloaded/nonhathi_raw/*.pdf | parallel --eta --jobs 90% -n 50 python read_nonht_file.py --pos nounverbadj`
  * ` find ../rawdata/downloaded/nonhathi_raw/*.csv | parallel --eta --jobs 90% -n 50 python read_nonht_file.py --pos nounverbadj`
  * ` find ../rawdata/downloaded/nonhathi_raw/*.docx | parallel --eta --jobs 90% -n 50 python read_nonht_file.py --pos nounverbadj`

7) Run `python collate_dics.py --pos nounverbadj` to combine counts for all dictionaries into a single data frame.

8) Run `Rscript combine_volumes.R nounverbadj` to combine counts across multiple volumes of the same dictionary.

9) Run `wiktionary_extract.ipynb` and then `wiktionary_filter.R` to perform Wiktionary-based filtering.

10) Run `wordnet_extract.ipynb` in `../preprocessing/wordnet` to extract information about number of senses from WordNet.

11) Run `read_subsistence.R` in `../preprocessing/subsistence` to extract subsistence information.

12) Run `create_bila_dictionaries.R` to create a master file.

13) Run `standardize_bila.R` to create a standard version and a lemmatized version of the dataset.


## Reproducing results

To reproduce tables and figures in main text and supplementary materials, follow the steps below. All code is in the folder `../analysis`. Certain code chunks are set up in a way that prevents from execution when you click "Run All" because it takes several hours to finish running those chunks.  

1) Run `read_cru2.R` and `read_cru_ts4.07.R` in `../analysis/environment` to extract temperature and precipitation information for the locations associated with BILA languages.

2) Run `preliminary_steps.Rmd` to produce interim outputs necessary for the next steps.

3) Run `analyze_claims.Rmd` to produce Figure 1, Table S1, and Figure S3.

4) Run `analyze_cases.Rmd` to produce Figure 2, Table S2, Table S3, and Figure S5. Note that it takes several hours to generate results for Bayesian analyses.

5) Run `bottomup_analysis.Rmd` to produce Figure 3, Figure S4, and Table S4. Note that it takes several hours to generate results for exhaustive analyses. 

6) Run `make_maps.R` to produce Figure S1.

7) Run `plot_related_lexemes.Rmd` to produce Figure S2.

8) Run `compute_zetas_par.R` and `relatedtermsforapp.Rmd` to produce results used for the [app]( https://www.charleskemp.com/code/lexicalelaboration.html). Note that this takes an hour or so. Codes for the app are available at a separate github [repository](https://github.com/cskemp/dictionaryapp).


