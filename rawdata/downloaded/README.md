
## Data used in preprocessing

#### HathiTrust dictionary files

The folder `hathi_raw` should include raw data files for HathiTrust dictionaries, which are downloaded as a part of the preprocessing step. See `../preprocessing/hathi_trust/README.md`.

#### Non-HathiTrust dictionaries

The folder `nonhathi_raw` should include all non-HathiTrust dictionaries, which can be downloaded from the sources mentioned in `../rawdata/manuallycreated/nonhathi_dictionaries.csv`. We do not put them here due to copyright issues.

#### Glottolog
* `glottolog_language.n3` : Version 4.8, downloaded from https://glottolog.org/meta/downloads

#### Swadesh list
* `Swadesh-1955-215.tsv`: downloaded from Concepticon (https://github.com/concepticon/concepticon-data)

#### Single words occurring more than 3 times in COCA
* `w1cs_c.txt`: downloaded from http://www.ngrams.info on January 09, 2012. The citation is Davies, Mark. (2011) N-grams data from the Corpus of Contemporary American English (COCA). Due to copyright issue, we do not put the whole file here in the repository but the first 1000 lines are included for visualizing the format. Nevertheless, this file is not needed to reproduce the BILA data set because we included the count files `wordpos.p` and `wordposcounts.p` derived from that file in the folder `../data/forpreprocessing/`.

#### List of Wiktionary languages
* `wiktionary_langs.tsv`: manually extracted from Wiktionary (https://en.wiktionary.org/wiki/Wiktionary:List_of_languages)

#### Wiktionary dump
* `enwiktionary-20240320-pages-articles-multistream.xml` downloaded from https://dumps.wikimedia.org/enwiktionary/20240320/

#### Dataset on cognates
* `CogNet-v2.0.tsv` downloaded from https://github.com/kbatsuren/CogNet

#### UK spellings
* `uk_us_spelling.csv` manually extracted from https://web.archive.org/web/20230326222449/http://tysto.com/uk-us-spelling-list.html

#### Hunter-gatherer languages

* `cysouwc_huntergatherer.csv` : manually extracted from https://cysouw.de/home/articles_files/cysouwcomrieHUNTERproofs.pdf.

* `guldemann_forager.csv`: manually extracted from https://www.cambridge.org/core/books/language-of-huntergatherers/preliminary-worldwide-survey-of-forager-languages/EBBD5F3676BDC7129267618FBE7D855B. 

* `autotyp_languages.csv` downloaded from https://www.autotyp.uzh.ch/

* Subsistence economy information were downloaded from D-Place and stored in `../rawdata/downloaded/dplace`.


## Data used in analyses

#### Country codes of languages
* `un_countries.csv`: downloaded from https://unstats.un.org/unsd/methodology/m49/overview

#### WALS languages
* `wals_languages.csv`: downloaded from https://zenodo.org/records/7385533

#### IDS chapters and concepts 
* `ids_chapters.csv` and `ids_parameters.csv` downloaded from Version 4.3 of the CLDF version of the Intercontinental Dictionary Series ( https://zenodo.org/records/7701635 )

#### A subset of non-HathiTrust dictionaries
* The folder `nonhathi_class` should contain a subset of 64 non-HathiTrust dictionaries, used in classification of dictionary entries. We do not put them here due to copyright issues. If needed, they can be downloaded from the sources mentioned in `../rawdata/manuallycreated/nonhathi_dictionaries.csv`, and the IDs for these 64 dictionaries can be found in `../rawdata/manuallycreated/lexeme_classification.csv`.
