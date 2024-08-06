## The BILA dataset

The BILA dataset contains following files. 

  * `bila_dictionaries_full.csv`: list of dictionaries in full version
  * `bila_dictionaries.csv`: list of dictionaries in standard version
  * `bila_long_noun_full.csv`:  dictionaries by counts in long form (noun) in full version
  * `bila_long_noun.csv`:  dictionaries by counts in long form (noun) in standard version
  * `bila_long_nounverbadj_full.csv`:  dictionaries by counts in long form (noun/verb/adj) in full version
  * `bila_long_nounverbadj.csv`:  dictionaries by counts in long form (noun/verb/adj) in standard version
  * `bila_matrix_noun_full.csv`: matrix of dictionaries by counts (noun) in full version
  * `bila_matrix_noun.csv`: matrix of dictionaries by counts (noun) in standard version
  * `bila_matrix_nounverbadj_full.csv`: matrix of dictionaries by counts (noun/verb/adj) in full version
  * `bila_matrix_nounverbadj.csv`: matrix of dictionaries by counts (noun/verb/adj) in standard version
  * `bila_long_noun_lemmatized.csv`: dictionaries by lemmas in long form (noun) in lemmatized version
  
## Explanations of columns
  
Columns of master files on list of dictionaries are:

  `id` : dictionary ID
  
  `year` : publication year
  
  `title` : title of the dictionary
  
  `imprint` : publishing organization
  
  `author` : author or authors of the dictionary
  
  `langname` : language name as written in the title
  
  `glottolog_langname` : corresponding language name to the assigned glottocode (extracted from Glottolog)
  
  `subclass` : specifies whether the dictionary is *x-english*, *x-english (and english-x)*, *english-x*, *ancient language* (e.g., Old English), *multilingual* (meaning trilingual dictionaries as part of non-HathiTrust set), or *dialect of English*
  
  `glottocode` : assigned glottocode
  
  `area` : area (extracted from Glottolog)
  
  `langfamily` : language family (extracted from Glottolog)
  
  `affiliation` : affiliation (extracted from Glottolog)
  
  `longitude` : longitude (extracted from Glottolog)
  
  `latitude` : latitude (extracted from Glottolog)
  
  `population` : population size
  
  `subsistence` : dominant mode of subsistence
  
  `doreco` : specifies whether language is present in DoReCo corpus
  
  `oclc` : OCLC number (extracted from HathiTrust)
  
  `lcc` : LCC number (extracted from HathiTrust)
  
  `access` : *pdf* or *clld* if a non-HathiTrust dictionary (*clld* denotes Dictionaria dictionary)
  
  `url` : url from where a non-HathiTrust dictionary was downloaded
  
  `rights` : copyright information automatically extracted from HathiTrust
  
  `copyright` : copyright information manually harvested on non-HathiTrust dictionaries
  
Columns of counts files in long form are:
  
  `id` : dictionary ID
  
  `word` : English token
  
  `count` : raw counts

Columns of counts files in matrix form are `id` and the selected English tokens.
