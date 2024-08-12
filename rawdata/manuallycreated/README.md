## List of non-HathiTrust dictionaries

We searched for sources that provide machine-readable bilingual dictionaries at once and chose the ones with good quality. As a result, we collected our non-HathiTrust dictionaries from four main sources: Dictionaria (https://dictionaria.clld.org/), University of Hawaii Press (https://scholarspace.manoa.hawaii.edu/browse/title?scope=a44b52fb-02fc-4b5e-96a2-6cd1b329b220&startsWith=dictionary), Open Research Library at ANU (https://openresearch-repository.anu.edu.au/advanced-search?query=dictionary), and Webonary (https://www.webonary.org/about-webonary/published-dictionaries/). We assigned unique ID to each of these dictionaries and collected authorship, publication, and copyright information. We followed the same guideline outlined in `\preprocessing\hathi_trust\README.md` to assign a glottocode. See the explanations of columns as follows: 

`id` : unique ID assigned to each non-HathiTrust dictionary.

`title` : title of the dictionary.

`author` : author or authors of the dictionary.

`imprint` : publishing organization.

`year` : year published.

`access` : format of the dictionary.

`gcode` : glottocode assigned.

`langname` : language name as in the title of the dictionary.

`collection` : four main collections - *dictionaria* , *hawaii*, *pacific linguistics* , and *webonary*. The rest are under collection *other*. 

`url` : a link where the dictionary was downloaded.

`copyright` : specification of copyrights; if not found, entered as NA. 

`duplicate_hathitrust` : entered the ID of HathiTrust dictionary if it happens to be a duplicate.

`doreco` : entered a 1 if the dictionary is one of the languages in DoReCo.

`type` : entered *wordlist* if it is not a dictionary; otherwise, entered *dictionary*.

`subclass` : indicates whether the dictionary maps *X to English* or is *multilingual*. 

`glottologlink` : directs to a reference in Glottolog where the dictionary title is found.

`ocr` : entered a 1 if [ABBYY FineReader](https://www.abbyy.com/) is used for implementing OCR.

## Examples of lexical elaboration

We gathered examples of lexical elaboration as we reviewed related literature. Some of these claims were mere mentions, such as "...among the 50 words that the Arab has for the lion, among the 200 that he has for the snake, among the 80 that he has for honey, and among the more than 1,000 that he has for the sword..." ([Herder, 2002](https://www.marxists.org/archive/herder/1772/origins-language.htm)). Some instances were obtained from non-scholarly works, such as this statement: "You can say that Lebanese has hundreds of lexemes for family relations. Family to the lebanese is as snow to the Inuit." ([Rabih, 2008](https://www.amazon.com/Hakawati-Rabih-Alameddine/dp/0307386279#:~:text=In%20this%20grand%20saga%20of,center%20of%20this%20matrix%20is)). Others were detailed, expert analyses of lexical elaboration. In our collection, we not only focused on examples of lexical elaboration but also gathered negative cases where a language lacks a particular term or is known to have few terms. In addition to nouns, we collected verbs, adjectives, proper nouns, and function words. 

The `examples_of_lexical_elaboration.csv` file contains the full collection. See the explanations of columns as follows:

`langname` : name of the single language or group of languages as mentioned in the reference.

`level` : indicates whether a single language or a group of languages.

`gcode` : glottocode assigned for single languages following the guideline below.

`gcode_rule` : specifies rules used to create a list of glottocodes for language groups

`ref_name` : language, family, area, or country name used in creation of glottocode lists

`concept` : concept given as an example of lexical elaboration (or lack of lexical elaboration) as mentioned in the reference

`domain` : specifies whether a concept is a noun, verb, adjective, proper noun, or function word.

`basic` : specifies whether a concept is basic (1) or not (0).

`combo_name` : an artificial name used in our analysis to combine counts for words in `word_list`.

`word_list` : a list of words assigned following the guideline below.

`source` : source where the lists of words were drawn from.

`sign` : indicates whether an example is positive (lexical elaboration) or negative (lack of lexical elaboration).

`reference` : reference from which an example was drawn.

`url` : URL of the reference, if any.

`scholarly` : indicates whether a reference is scholarly (1) or not (0).

`page` : specifies the page if the reference is a book.

`comments` : comments, if any.

#### Assignment of glottocodes

We employed the following guidelines to assign a glottocode for a single language:

* Search for the language name in Glottolog. If the Glottolog search returns a single language, use it. Otherwise, explore the reference section of Glottolog. Some references with language names in their titles may guide you to a specific glottocode. If this doesn't resolve the uncertainty, search for the reference title, where the particular claim is collected, in the Glottolog reference section.
* If there are no hits on Glottolog, try a WALS search ( https://wals.info/languoid ) for the language name. 
* If there are no hits on Glottolog or WALS, try a Wikipedia search for the language name. 
* If Wikipedia doesn't include a relevant page, try a generic Google search. 
* If a single language is found, enter *single* in the `level` column and the corresponding glottocode in the `gcode` column. If it is not a single language, enter NA in the `gcode` column. 

We established the following rules to compile a list of glottocodes for a group of languages, as outlined in the `gcode_rule` column. It's important to note that this list is derived from the languages in our dataset, and the corresponding codes can be found in `analyze_claims.Rmd`.

* `langname_contains`: If the Glottolog search returns multiple languages, we marked them as *group* in the `level` column. We then created a list of glottocodes if the Glottolog language name contains the name in the reference. In cases where the name in the reference did not match the Glottolog name, we recorded the Glottolog name in the `ref_name` column.
* `langfamily_equals_to`: For Mayan, Tupian, and Eskimo-Aleut languages, we compiled a list of glottocodes belonging to *Mayan*, *Tupian*, and *Eskimo-Aleut* language families.
* `affiliation_contains`: Given that Polynesian, Oceanic, Batanic, and Gbaya languages belong to sub-branches of the respective family, we relied on affiliation information.  
* `area_equals_to`: For Australian languages, we created a list of glottocodes corresponding to the area *Australia*. 

For the remaining language groups, we used country codes to generate a list of glottocodes, as specified in `analyze_claims.Rmd`. The coding criteria were as follows:
* `region_equals_to` : For Asian and European language groups, we relied on the regions *Asia* and *Europe*.
* `subregion_equals_to` : For East and Southeast Asian languages, we relied on the subregions *Eastern Asia* and *South-eastern Asia*. 
* `country_equals_to` : In the case of Papua New Guinea languages and languages of Indians of Brazil, we relied on the countries *Papua New Guinea* and *Brazil*.

#### Creation of word lists

The reason for creating a list of words related to a concept is to take into account synonyms (while some dictionaries use *smell* others might use *odour* in their glosses). More importantly, it is to create a list of subordinate terms for higher-level concepts like *body parts*. We didn't add plural forms because our analysis was based on lemmatized version of the data set, except for irregular plurals such as *calves* and *oxen*.

Before creating a list of related words, we marked the concept as a noun, verb, adjective, function word, compound, proper noun, or various in the `domain` column. We excluded the following concepts from subsequent analysis: 
* Function words *for* and *my*, as well as the proper noun *Christ*.
* Compound words, such as *sweet potato*, were excluded due to our token frequency being based on unigrams. 
* The terms *nature*, *animal*, *plant* were excluded for being too broad. Note that we excluded terms at the level of folk kingdom but kept terms at the level of folk lifeform (*tree*, *bird*, *insect*). 
* The concepts *kinship* and *sibling* were excluded because core kin terms were filtered out as part of stop words.
* Adjectives and verbs were also excluded.
For these cases, we did not create word lists. 

For basic words such as *taro* and *sword*, we followed the guidelines below:
* Add synonym words found in WordNet (http://wordnetweb.princeton.edu/perl/webwn). Use your judgement on whether to include or exclude a particular synonym word. Avoid including words that have multiple meanings, and their main senses are remotely related to the word in question (e.g., *blade*, *brand*, and *steel* for *sword*).
* If there are no synonyms, proceed with the word or words. 

For superordinate words, we followed the guidelines below:
* Search the word (if not found, one of its synonyms) in Historical Thesaurus of English (https://ht.ac.uk/). If a corresponding node is found in the hierarchy, use your judgment on whether to include or exclude a particular subordinate term while navigating through the lower nodes. No need to go into details of those nodes by clicking, just look through the names of those subordinate nodes. Avoid including words that have multiple meanings, and their main senses are remotely related to the word in question.
* If no corresponding node is found, conduct a generic Google search. Three cases—*mechanical artifacts*, *non-portable artifacts*, and *land invertebrates*—were based on a Google search. Although the *land invertebrates* node was present in HTE, subordinate terms mostly comprised scientific names, which are absent from our dataset.
* Consult previous literature, if known. Three cases—*body parts*, *livestock*, *emotion*—were based on literature (references are included in the `source` column).
* If none of the above steps provides a reasonable list, proceed with the word or words. Follow the guideline for basic words to add synonyms. In this context, there were 7 cases: *mammal*, *bird*, *fish*, *insect*, *tree*, *vegetable*, *disease*.


## Population size

We collected population size information using the following steps:

1. Search in the supplemental material (rspb20141574supp2.xls) of Amano, Tatsuya, Brody Sandel, Heidi Eager, Edouard Bulteau, Jens-Christian Svenning, Bo Dalsgaard, Carsten Rahbek, Richard G. Davies, and William J. Sutherland. "Global distribution and drivers of language extinction risk." Proceedings of the Royal Society B: Biological Sciences 281, no. 1793 (2014): 20141574, which was based on Lewis MP (ed.) 2009 Ethnologue: languages of the world, 16th edn. Dallas, TX: SIL International. If found, enter *ethnologue* in the `source` column. 

2. If there are no hits in the supplemental material, search for ISO or language name in Ethnologue: http://www.ethnologue.com/. If population information is available, prefer using ethnicity population (if available) or population of L1 users (to maintain consistency with Amano et al. 2014) in all countries. If found, enter *ethnologue* in the `source` column. 

3. If there are no hits or it is indicated as "no L1 users" in Ethnologue, search for the language name in Wikipedia. If no population size information is available on the language page of Wikipedia, check the speaker community page. Use L1 speaker numbers if specified. If it is a range, take the average.  If found, enter *wikipedia* in the `source` column. 

4. If there are no hits in Wikipedia, attempt to find population information or estimate the speaker range with generic Google searches. If found, enter *other* in the `source` column. Otherwise, enter NONE and proceed to the next language.

After compiling population size information in `popn_size.csv`, we added them to the list of BILA dictionaries file by running `../preprocessing/create_bila_dictionaries.R`. Languages with less than 100 population were revised to 100, being the minimum boundary.

Here are the explanations of columns:

 `glottocode`: glottocode of the language.

 `language`: language name as per Glottolog.

 `iso`: ISO code of the language.

 `population`: population size.

 `year`: year for which the population size information is reported.

 `source`: source from which the population size information is obtained.

 `reference`: reference or URL of the source.

 `comment`: additional comments, if any.


## Classification of dictionary entries

To see if token counts are approximate enough for number of related lexemes, we took a sample of concepts including *rain*, *smell*, and *taste* and manually classified dictionary entries that contain any of the terms related to these concepts. 

1) First, we chose a subset of 64 non-HathiTrust dictionaries that were available in pdf format and include collections from all sources but Webonary. Due to copyright issues, we did not upload them into this repository. If needed, they must be downloaded using the links specified in `url` column of `nonhathi_dictionaries.csv` and put in the folder `../rawdata/downloaded/nonhathi_class` to perform the next steps.

2) We then ran `../preprocessing/search_pdf/search_pdf.R` to extract dictionary entries that contain any of the group of terms corresponding the concept (e.g., *rain*, *raindrop*, *rainwater*, and *rainfall* for the concept rain). We started with the group of terms used in analysis of case studies, and added inflected forms and UK variant forms. Output files are stored in the folder `../data/foranalyses/pdf_search`.

3) We went through each output file and manually created `lexeme_classification.csv`, with following columns:

`id`: dictionary ID

`concept`: the concept of interest

`line`: line in pdf where any of the group of terms corresponding to the concept is found

`classification`: *related* if the entry is a lexeme closely related to the concept, *unrelated* if the entry is a lexeme remotely related to the concept, *example* if any of the group of terms is used in example sentence, *other* if none of the former. 

`review_flag`: inserted 1 if review is needed

`review_note`: notes by the reviewer (1 for IN and 0 for OUT)

#### Guideline for classifying dictionary entries

We used the following guideline to make a decision on classification. We treated
and classified dictionary subentry the same as main entry. For a given concept C:

1. If definition has multiple related senses and one of them is C, e.g., ‘smell, odour, taste,
flavour’, classify it as related lexeme.

2. If definition points to a general term for C, e.g., ‘odor’ or ‘to smell’, classify it as related
lexeme.

3. If definition points to a kind of C, e.g., ‘a cool southerly wind’, classify it as related
lexeme.

4. If definition points to a part of C, e.g., ‘a hole in the ice (for obtaining water)’, classify it
as related lexeme.

5. If definition points to something that is made of C, e.g., ‘ice-house’, classify it as related
lexeme.

6. If definition points to actions involving C, e.g., ‘to track by smell’, ‘put scent on the hair’,
classify it as related lexeme.

7. If definition mentions terms that are functionally related to C, e.g., ‘snow knife’ or ‘plant
used for perfume making’, classify it as related lexeme.

8. If definition mentions terms that highlight C-related knowledge, e.g., ‘traditional knowledge of how to control the rain’, classify it as related lexeme.

9. If definition mentions terms related to specific cultural practice that involves C, e.g., ‘men
gather to sing and dance rainmaking song’, classify it as related lexeme.

10. If definition mentions metaphorical expressions that contains C, e.g., ‘be without rain; be
difficult’, classify it as related lexeme.

11. If definition mentions any form where C is actually part of the form, e.g., ‘peacock, literally means “fond of rain”’, classify it as related lexeme.

12. If definition hints that C is important in the culture, e.g., ‘the god of fragrant odors’,
classify it as related lexeme.

13. If definition mentions that C is used to explain remotely related concepts, e.g., ‘a kind of
tree with a fragrant smell of its fruit’, classify it as unrelated lexeme.

14. If C is used in example sentence, e.g., ‘faalipeiu. n. armpit. Ye bo nngaw faalipeiumw.
Your armpits smell bad’, classify it as example.

15. If C is included among many disparate examples: e.g., ‘heavy (of rain), high (of prices,
rank), grave (of problems, offences)’, classify it as example.

16. If the entry seems none of the above, classify it as other.

17. If unsure, flag it for review.

