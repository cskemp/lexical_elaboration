library(here)
library(dplyr)
library(tidyverse)
library(testthat)
library(lingtypology)

manual_path <- here("preprocessing", "hathi_trust", "02_with_gcodes_manual.csv")

manual <- read_csv(manual_path) %>%
  # filter out to-be-deleted dictionaries
  filter(is.na(delete))

glogln <- glottolog %>%
  select(glottocode, language) %>%
  rename(gcode=glottocode, glottolog_langname=language)

# the dictionary language name shouldn't be the same as the new language name
dictln_eq_newln <- manual %>%
  select(dictlangname, newlangname) %>%
  unique() %>%
  filter(dictlangname == newlangname) %>%
  left_join(manual, by=c('dictlangname', 'newlangname'))
expect_equal(nrow(dictln_eq_newln), 0)

# the new language name should be the same as the glottolog language name
newln_glogln <- manual %>%
  select(gcode, dictlangname, newlangname) %>%
  unique() %>%
  left_join(glogln, by='gcode') %>%
  filter(newlangname!=glottolog_langname)
expect_equal(nrow(newln_glogln), 0)

# the same language name shouldn't be assigned with more than one glottocode.
ln_gcode <- manual %>%
  mutate(langname = if_else(!is.na(newlangname), newlangname, dictlangname)) %>%
  select(langname, gcode) %>%
  unique() %>%
  group_by(langname) %>%
  mutate(gcode_count = n()) %>%
  filter(gcode_count > 1)
expect_equal(nrow(ln_gcode), 0)

# we'd expect 25 cases where the glottolog name is different from dictionary language name.
# these observations are default assignments of glottocodes.
# must be recorded in https://github.com/cskemp/lexical_elaboration/edit/main/preprocessing/hathi_trust/README.md
glogln <- glottolog %>%
  select(glottocode, language) %>%
  rename(gcode=glottocode) %>%
  mutate(glottolog_langname= str_replace(language, " \\(.*\\)", ""))  %>%
  select(-language)

dictln_glogln <- manual %>%
  select(gcode, dictlangname, newlangname) %>%
  left_join(glogln, by='gcode') %>%
  unique() %>%
  filter(dictlangname!=glottolog_langname & is.na(newlangname))
expect_equal(nrow(dictln_glogln), 25)

# we'd expect 10 cases where the same dictionary language name was assigned to different new language name.
# these observations are due to pointers in glottolog reference
# must be recorded in https://github.com/cskemp/lexical_elaboration/edit/main/preprocessing/hathi_trust/README.md
dictln_newln <- manual %>%
  select(dictlangname, newlangname) %>%
  unique() %>%
  group_by(dictlangname) %>%
  mutate(newln_count = n()) %>%
  filter(newln_count > 1, !is.na(newlangname))
expect_equal(nrow(dictln_newln), 10)

# different languages shouldn't be flagged as duplicates or volumes
dupid_to_gcode <- manual %>%
  select(id, gcode) %>%
  rename(duplicate = id, dup_gcode = gcode)

volid_to_gcode <- dupid_to_gcode %>%
  rename(volume = duplicate, vol_gcode = dup_gcode)

dup_vol_gcode <- manual %>%
  left_join(dupid_to_gcode, by = "duplicate") %>%
  left_join(volid_to_gcode, by = "volume") %>%
  filter( (!is.na(dup_gcode) & dup_gcode != gcode) | (!is.na(vol_gcode) & vol_gcode != gcode) )
expect_equal(nrow(dup_vol_gcode), 0)

# the id of the earliest edition must be entered in the duplicate column
# exceptions are those that appear to have volumes and those that map X to English
vol_list <- list(unique(manual$volume))

dup_year <- manual %>%
  filter(!is.na(duplicate)) %>%
  group_by(duplicate) %>%
  summarise(
    yearmax = case_when(
      # we take maximum value of the year among the ones that map X to English
      any(subclass == "x-english (and english-x)") ~ max(year[subclass == "x-english (and english-x)"]),
      TRUE ~ max(year)
    )
  ) %>%
  ungroup()  %>%
  left_join(manual %>% select(id, year, title, duplicate, subclass, enumeration), by="duplicate") %>%
  unique() %>%
  # volumes missing information on year were given a fixed value of 9999 in hathitrust. we filter these out.
  filter(duplicate==id & yearmax!=year & yearmax!=9999)  %>%
  # take into account volumes
  filter(!(duplicate %in% unlist(vol_list)))
expect_equal(nrow(dup_year), 0)

# check if manually obtained dictionary language name is in the title
# we'd expect 303 cases where the dictionary language name is contained in the title but still picked up due to a limitation of the search strategy.
dictln_not_in_title <- manual %>%
  mutate(title_split = strsplit(as.character(title), " |,|;|:|-|/") %>%
           lapply(function(x) gsub("[ ,;:\\-\\/]", "", x))) %>%
  filter(!dictlangname %in% unlist(title_split)) %>%
  select(id, title, dictlangname)
expect_equal(nrow(dictln_not_in_title), 303)

# we use this check to identify potential missing values in volume column
# we recommend to go through vol_enum to see if the same dictionary appears more than once
# we'd expect 75 cases where enumeration column contains below patterns, nevertheless no dictionary appears more than once
patterns <- c("1", "2", "v", "V", "no", "p", "pt", "vol")

vol_enum <- manual %>%
  filter(str_detect(enumeration, regex(paste(patterns, collapse = "|", sep = ""), ignore_case = TRUE))) %>%
  select(id, year, title, enumeration, duplicate, volume) %>%
  filter(is.na(duplicate), is.na(volume)) %>%
  mutate(title_strip = sub("^[\\[\\(]", "", title)) %>%
  mutate(title_strip = str_to_lower(gsub("[^a-zA-Z]", "", title_strip))) %>%
  arrange(title_strip) %>%
  select(-title_strip)
expect_equal(nrow(vol_enum), 75)

# below are simple checks of missing values:
dictlangname <- manual %>%
  # there should be no missing values in dictlangname
  filter(is.na(dictlangname))
expect_equal(nrow(dictlangname), 0)

gcode <- manual %>%
  # there should be no missing values in gcode
  filter(is.na(gcode))
expect_equal(nrow(gcode), 0)

newln_newlnlink <- manual %>%
  # if new name is entered in newlangname column, link must be provided
  filter(!is.na(newlangname) & is.na(newlangnamelink))
expect_equal(nrow(newln_newlnlink), 0)

delete <- read_csv(manual_path) %>%
  # delete column should contain either 1 or NA
  filter(delete!="1" & !is.na(delete))
expect_equal(nrow(delete), 0)

delete_review <- read_csv(manual_path) %>%
  # if delete column is indicated as 1, review_note should contain its reason for deletion
  filter(delete=="1" & is.na(review_note))
expect_equal(nrow(delete_review), 0)

subclass <- manual %>%
  # there should be no missing values in subclass
  filter(is.na(subclass))
expect_equal(nrow(subclass), 0)
