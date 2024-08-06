# Procedure for compiling Hathi Trust counts

1. We started with `hathi_full_20231101.txt`, the complete list of  18,175,880 volumes downloaded from the Hathi Trust in late 2023. This file is large (5.2G) and therefore not included in this repository. If needed, recent versions of this file are available [here]( https://www.hathitrust.org/member-libraries/resources-for-librarians/data-resources/hathifiles/ ). We then ran `python read_hathi_list.py > ../../preprocessing/hathi_trust/01_initial_volumes.csv` to extract all volumes with "ictionar" in the title that also met at least one of the following conditions:
    * title matches one of the language names from `data/forpreprocessing/language_names.csv`, which was created by collecting language names and alternative names from Glottolog and removing stopwords (see `preprocessing/hathi_trust/make_language_re.R` )
    * title matches  `"nglis|uinea|ustrali|frica|acific|ceani|inguist|anguage|exico|ocabular|ialect"` 
    * imprint (ie publisher) matches `"uinea|ustrali|frica|acific|ceani|inguist|anguage|exico|ocabular|ialect|Mouton|Gruyter|of Hawa|Lincom|Köppe|Madras|California|ission"`
    
    All 19,621 of these volumes appear in `01_initial_volumes.csv`.  Some dictionaries relevant to us are not picked up by the search strategy -- a future effort might supplement our data set by considering *all* 41,371 dictionaries with "ictionar" in the title, and perhaps expand to volumes with "vocabulary"  or "lexicon" but not "ictionar" in the title.
  
2. We made a manual pass through `01_initial_volumes.csv` and classified each volume as in (1) or out (0). Following types of dictionaries are excluded.
    * dictionaries of one language alone (e.g. monolingual English dictionaries)
    * dictionaries including 3 or more languages
    * dictionaries with specialized content (e.g. engineering dictionaries, dictionaries of musical terms, dictionaries of idioms, dictionaries of place names, dictionaries of neologisms, dictionaries of classical words, etymological dictionaries, abbreviation dictionaries)
    * dictionaries of sign languages
    * grammar dictionaries and volumes with the majority of content dedicated to grammar

3. We used the script `filtered_to_gcode.R` to prepare a starter file (`02_with_gcodes_starter.csv`, 5099 volumes) that could be used to match each dictionary with a glottocode. The file included guesses about the correct glottocode and language name (`autogcode`, `autolangname`) based on string matches between the dictionary title and language names available from Glottolog. We went through the file adding glottocodes according to the guidelines below, and all items that were flagged as needing review were checked by a second coder.  The final, manually-edited version of the file is `02_with_gcodes_manual.csv`. 

    The script `filtered_to_gcode.R` loads `ef_filelisting.txt`, which includes all ids for which frequency data are available. This file is not included in the repository because of its size (592M) but can be downloaded using

    `rsync -azv data.analytics.hathitrust.org::features-2020.03/listing/file_listing.txt .`
    
     `filtered_to_gcode.R` keeps only one representative of each set of dictionaries with identical titles. An additional 250  
     or so volumes are dropped because frequency data for these volumes are not available.
    
4. We used the script `gcode_to_final_hathilist.R` to drop volumes marked for deletion in `02_with_gcodes_manual.csv` and to produce the final list of volumes `02_with_gcodes.csv`. Just the HathiTrust ids for these files are written to `02_hathi_ids.txt'. These ids are converted to paths using

  `htid2rsync --from-file 02_hathi_ids.txt > 02_hathi_ids_sanitized.txt`  
  
where `htid2rsync` is a command line utility installed as part of the htrc-feature-reader package.

5. Counts for all volumes in `02_with_gcodes.csv` were downloaded using

    `rsync -av --no-relative --files-from 02_hathi_ids_sanitized.txt data.analytics.hathitrust.org::features-2020.03/ ../../rawdata/downloaded/hathi_raw/`

# Phase 2 coding process

Explanation of key columns of `02_with_gcodes_manual.csv`:

`dictlangname`: language name manually extracted from the dictionary title

`gcode`: The glottocode assigned (or ? if you went through the flowchart below and no glottocode was assigned)

`duplicate`: for each group of duplicates, take the id of any one member of the group and paste it in the duplicate column for the *entire* group.  Different volumes of the same dictionary should not be treated as duplicates. The latest edition of the same dictionary must be kept in cases where the dictionary has several editions published in different years. Choose the dictionary id with multiple volumes rather than the latest edition if the dictionary appears to have multiple volumes. Leave empty if a dictionary is not a duplicate. If you are uncertain, err on the side of including duplicates rather than dropping them, because a later stage in the pipeline attempts to automatically screen out duplicates. 

`volume`: for a group of dictionaries that have the same title and the enumeration column indicates volume or part, take the id of any one member of the group and paste it in the volume column for the *entire* group. Different volumes of the same dictionary will be combined at later stage. It is clear in the enumeration column that some dictionaries have one volume that maps X to English, and a second that maps English to X. In this case the first must be kept and the second must be deleted. Accordingly, take the id of X-English dictionary and paste in the duplicate column for both volumes. In cases where the enumeration column indicates supplementary or appendix, these must be also deleted. Take the id of the dictionary and paste in the duplicate column for the entire group.

We used the following rules to delete duplicates and combine volumes:

```R
if (duplicate == "NA" & volume == "NA") {
    keep
} else if (duplicate != "NA" & volume == "NA" & id == duplicate) {
    keep
} else if (duplicate != "NA" & volume == "NA" & id != duplicate) {
    delete
} else if (duplicate == "NA" & volume != "NA") {
    keep and combine token frequencies of dictionaries with the same id in the volume column
} else { # duplicate != "NA" & volume != "NA":
    keep and combine token frequencies of dictionaries with the same id in the volume column
}
```

`newlangname`: use this if you ended up using a different but equivalent language name based on a Google search (otherwise leave empty)

`newlangnamelink`: url of the page that the newlangname was based on

`delete`: mark a 1 in this column if you think the dictionary should be dropped. At this stage we should mark dictionaries of artificial languages for deletion. Also mark specialized dictionaries, sign language dictionaries, dictionaries with more than two languages, and purely English dictionaries for deletion (these should have been removed during the first phase of filtering, but some slipped through). Note that we didn't delete picture dictionaries until this stage but they were deleted when a standard version of the dataset was created (see `preprocessing/README.md`). 

`review_flag`: mark as 1 if you're uncertain about what you did and would like a second opinion (otherwise leave empty)

## Guidelines for assigning gcodes

We'll use this record as our example:

mdp.39015045613505,1997,"Eskimo-English, English-Eskimo dictionary = Inuktitut-English, English-Inuktitut dictionary / Arthur Thibert."

#### 1) Glottolog

Search for dictionary title (e.g Eskimo-English, English-Eskimo dictionary) in the reference section of glottolog. If it is in the list of references, it will direct you to which language it is written on. If it is not found, proceed to the next step.  

Search for language name (e.g Inuktitut) in glottolog. Where possible, try to identify a language (e.g. Eastern Canadian Inuktitut) rather than a dialect 
(Baffin Inuktitut) or a language family (Inuit). But in some cases a dialect (e.g. Cantonese) or a language family (Ojibwa) might be the best choice.

In general,

* go with a dialect if it seems clear that a dictionary does indeed focus on that dialect
* go with a language family if you can't link a specific language to the dictionary and it seems as if there is no dominant language in the family

For simplicity the rest of this flowchart will talk about languages rather than dialects or families  -- but the same basc process applies regardless of whether you end up listing a language, dialect or family.

If the Glottolog search returns one language, use it (unless something seems off).  

If multiple languages are returned (e.g. Eastern Canadian Inuktitut and Western Canadian Inuktitut), try a Glottolog reference search for the author of the dictionary (ie Thibert). 

If that doesn't resolve the uncertainty, try a WALS search (https://wals.info) for the language name (ie Inuktitut). For our running example WALS suggests that "Eastern Canadian Inuktitut) should be the default choice for Inuktitut.

If WALS doesn't resolve the uncertainty, try Google searches for the author and the different possible languages: e.g search for

\> "Eastern Canadian Inuktitut" Thibert

\> "Western Canadian Inuktitut" Thibert

(quotation marks are important)

If a quick glance at the results doesn't resolve the uncertainty, and if all candidate languages are from the same part of the world (e.g. Alaska) choose the language that has the greatest number of references on Glottolog (Western Canadian Inuktitut has 23, Eastern Canadian Inuktitut has 61, so choose Eastern Canadian Inuktitut). 

If the candidate languages are not from the same part of the world (e.g. there is a language called Kare in PNG and another in Africa) mark the gcode as ? and move on to the next dictionary.

####  2) WALS

If there are no hits on Glottolog, try a WALS search ( https://wals.info/languoid ) for the language name (e.g Inuktitut). 

####   3) Wikipedia

If there are no hits on Glottolog or WALS, try a Wikipedia search for the language name. If a language page is returned, the bar on the right side of the page may include a glottocode (e.g. the Inuktitut wikipedia page lists east2534). If the language page doesn't include a glottocode, it might suggest an alternative language name. Paste this into the "newlangname" column (no "newlangnamelink" required) and repeat the process for this alternative name.

####   4) Google

If Wikipedia doesn't include a relevant page (or if it does but this page doesn't help to identify a glottocode or alternative language name) try two generic google searches in this order

\> inuktitut thibert

\> inuktitut

(ie first has language name and author, second has language name only. Use quotation marks if either the language name or author name has two or more parts.

Glance at the top page of results. If you find something that seems to specify an alternative name that *is* in Glottolog or WALS, 

* paste the url of the link in the spreadsheet
* paste the alternative name in the spreadsheet
* repeat the whole process for the alternative name.

####   5) Other

If the steps above don't allow you to identify a glottocode enter a NONE and move on to the next dictionary.


## Consistency check

We ran `consistency_check.R` to automatically verify the consistency of the phase 2 coding process. We checked:

* whether the dictionary language name matches the new language name. No such observation must be found. 
* whether the new language name is distinct from the glottolog language name. No such observation must be found. 
* whether the same language name (take the new language name, if absent, the dictionary language name) is assigned multiple glottocodes. No such observation must be found. 
* whether the dictionary language name is different from the glottolog language name. We observed 25 such cases because we assigned default glottocodes for these, unless the Glottolog reference section pointed to a specific glottocode (see below). 

| No      | Language name in dictionary      | Assigned language name           | Assigned glottocode   |
|---------|----------------------------------|----------------------------------|---------------------------|
| 1       | Albanian                         | Northern Tusk Albanian          | tosk1239                   |
| 2       | Arabic                           | Standard Arabic                 | stan1318                   |
| 3       | Armenian                         | Eastern Armenian                | nucl1235                   |
| 4       | Assyrian                         | Assyrian Neo-Aramaic            | assy1241                   |
| 5       | Balochi                          | Eastern Balochi                 | east2304                   |
| 6       | Chinese                          | Mandarin Chinese                | mand1415                   |
| 7       | Eskimo                           | Eastern Canadian Inuktitut      | east2534                   |
| 8       | Greek                            | Modern Greek                    | mode1248                   |
| 9       | Hebrew                           | Modern Hebrew                   | hebr1245                   |
| 10      | Indonesian                       | Standard Indonesian             | indo1316                   |
| 11      | Khmer                            | Central Khmer                   | cent1989                   |
| 12      | Malay                            | Standard Malay                  | stan1306                   |
| 13      | Mongolian                        | Halh Mongolian                  | halh1238                   |
| 14      | Ojibway                          | Northwestern Ojibwa             | nort2961                   |
| 15      | Older Scottish                   | Scottish Gaelic                 | scot1245                   |
| 16      | Oriya                            | Odia                            | oriy1255                   |
| 17      | Panjabi                          | Eastern Panjabi                 | panj1256                   |
| 18      | Punjabi                          | Eastern Panjabi                 | panj1256                   |
| 19      | Persian                          | Western Farsi                   | west2369                   |
| 20      | Pilipino                         | Tagalog                         | taga1270                   |
| 21      | Sioux                            | Dakota                          | lako1247                   |
| 22      | Syriac                           | Classical Syriac                | clas1252                   |
| 23      | Uzbek                            | Northern Uzbek                  | nort2690                   |
| 24      | Yemeni Arabic                    | Judeo-Yemeni Arabic             | jude1267                   |
| 25      | Yiddish                          | Eastern Yiddish                 | east2295                   |

* whether language names appear to be identical, nevertheless assigned different glottocodes. We observed 10 such cases due to a pointer in the Glottolog reference section (see below).

| No. | Dictionary | Assigned glottocode | Glottolog reference |
|-----|------------|----------------------|----------------------|
| 1   | A dictionary of the dialects of vernacular Syriac as spoken by the eastern Syrians of Kurdistan, north-west Persia, and the Plain of Mosul: with illustrations from the dialects of the Jews of Zakhu and Azerbaijan, and of the western Syrians of Tur 'Abdin and Ma'lula / by Arthur John Maclean. | west2763 | [Link](https://glottolog.org/resource/reference/id/310955) |
| 2   | A dictionary of the Malay tongue, as spoken in the Peninsula of Malacca, the islands of Sumatra, Java, Borneo, Pulo Pinang, &c., &c. In two parts, English and Malay, and Malay and English. To which is prefixed the grammar of that language ... By James Howison | mala1479 | [Link](https://glottolog.org/resource/reference/id/319214) |
| 3   | Arabic-English dictionary of the modern Arabic of Egypt, by S. Spiro bey | egyp1253 | [Link](https://glottolog.org/resource/reference/id/87659) |
| 4   | Assyrian-English-Assyrian dictionary / editor-in-chief, Simo Parpola ; managing editor and English editor, Robert Whiting ; associate editors, Zack Cherry, Mikko Luukko, Greta Van Buylaere ; editorial assistants, Paolo Gentili, Stephen Donovan, Saana Teppo | akka1240 | [Link](https://glottolog.org/resource/reference/id/102946) |
| 5   | Cook Islands Maori dictionary : with English-Cook Islands Maori finderlist / by Jasper Buse with Raututi Taringa ; edited by Bruce Biggs and Rangi Moekaʹa. | raro1241 | [Link](https://glottolog.org/resource/reference/id/71051) |
| 6   | Eskimo or Innuit dictionary. As spoken by all of these strange people on the Alaska Peninsula, the coast of Bering Sea and the Arctic Ocean, including settlements on all streams emptying into these waters. | cent2127 | [Link](https://glottolog.org/resource/reference/id/578436) |
| 7   | NTC's Yemeni Arabic-English dictionary / Hamdi A. Qafisheh in consultation with Tim Buckwalter and Alan S. Kaye. | sana1295 | [Link](https://glottolog.org/resource/reference/id/22043) |
| 8   | Old Javanese-English dictionary / P.J. Zoetmulder with the collaboration of S.O. Robson. | kawi1241 | [Link](https://glottolog.org/resource/reference/id/320643) |
| 9   | Manobo dictionary of Manobo as spoken in the Agusan river valley and the Diwata mountain range / Teofilo E. Gelacio, Jason Lee Kwok Loong, Ronald L. Schumacher ; drawings by Mendez Havana, Jr. | agus1235 | [Link](https://glottolog.org/resource/reference/id/469842) |
| 10  | Manobo-English dictionary, by Richard E. Elkins. | west2555 | [Link](https://glottolog.org/resource/reference/id/52064) |

* whether different languages were flagged as duplicates or volumes. No such observation must be found. 
* whether the ID of the latest edition was entered in the duplicate column. Exceptions were allowed for dictionaries with apparent multiple volumes and those mapping X to English. Otherwise, no such observation must be found.
* whether the language name was correctly extracted from the dictionary title. There were cases where the dictionary language name is contained in the title but still picked up due to a limitation of the search strategy.
* we searched for cases where the enumeration column contains clues of potential volumes but were not flagged as volumes (or duplicates). There were dictionaries indicated as, say, "Volume 1" but we were unable to find remaining volumes in the list. These cases were kept.
* we also conducted simple checks of missing or incorrect values in columns `dictlangname`, `gcode`, `newlanguagenamelink`, `delete`, `review_note`, and `subclass`. 
