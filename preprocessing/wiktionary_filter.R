library(here)
library(dplyr)
library(tidyverse)
library(testthat)
library(lingtypology)

dict_path <- here("data", "biladataset", "bila_dictionaries_full.csv")
long_path <- here("data", "biladataset", "bila_long_nounverbadj_unfiltered_full.csv")
noun_path <- here("data", "biladataset", "bila_long_noun_unfiltered_full.csv")
wik_path <- here("data", "forpreprocessing", "wiktionary_forms.tsv")
lang_path <- here("rawdata", "downloaded", "wiktionary_langs.tsv")

dicts <- read_csv(dict_path, show_col_types = FALSE) %>%
  select(id, glottocode) %>%
  unique() %>%
  left_join(glottolog %>% select(glottocode, language), by="glottocode") %>%
  rename(glottolog_langname=language)

wik_langs <- read_tsv(lang_path, show_col_types = FALSE)

# wiktionary scrape resulted in information of the same forms in 814 languages
# first we assign glottocode to these languages using iso code
iso_gcode <- read_tsv(wik_path, show_col_types = FALSE) %>%
  filter(language_name != "English") %>%
  select(language_name) %>%
  unique() %>%
  left_join(wik_langs %>% select('iso', 'language_name'), by='language_name') %>%
  left_join(glottolog %>% select('glottocode', 'iso'), by='iso')
expect_equal(length(unique(iso_gcode$language_name)), 814)

# 65 wiktionary languages still don't have glottocodes
expect_equal(n_distinct(subset(iso_gcode, is.na(glottocode))$language_name), 65)

# so we'll use language name
lname_gcode <- iso_gcode %>%
  filter(is.na(glottocode)) %>%
  rename(language=language_name) %>%
  select(-glottocode) %>%
  left_join(glottolog %>% select('glottocode', 'language'), by="language")

# 40 wiktionary languages still don't have glottocodes
expect_equal(n_distinct(subset(lname_gcode, is.na(glottocode))$language), 40)

# so we'll add them manually only if they appear in BILA
# we suggest going through wiklangs_nogcode to see if the wiktionary language appears in BILA
dict_langs <- dicts %>%
  select(glottolog_langname, glottocode) %>%
  rename(language = glottolog_langname) %>%
  unique() %>%
  mutate(location = "bila")

wiklangs_nogcode <- lname_gcode %>%
  filter(is.na(glottocode)) %>%
  select(language, glottocode) %>%
  arrange(language)

# 11 wiktionary languages were assigned glottocodes manually
manual_gcode <- lname_gcode %>%
  filter(is.na(glottocode)) %>%
  mutate(glottocode = case_when(
    language == "Azerbaijani" ~ "nort2697",
    language == "Chinese" ~ "mand1415",
    language == "Dutch Low Saxon" ~ "dutc1256",
    language == "Hokkien" ~ "minn1241",
    language == "Kanuri" ~ "cent2050",
    language == "Malagasy" ~ "plat1254",
    language == "Malay" ~ "stan1306",
    language == "Middle Norwegian" ~ "norw1258",
    language == "Ojibwe" ~ "nort2961",
    language == "Oromo" ~ "west2721",
    language == "Quechua" ~ "chim1302",
    TRUE ~ glottocode
  ))

# combine wiktionary languages with glottocodes
# out of 814 languages, 785 were assigned glottocodes
wiklangs_gcode <- bind_rows(iso_gcode %>% filter(!is.na(glottocode)),
                            lname_gcode %>% filter(!is.na(glottocode)) %>% rename(language_name=language),
                            manual_gcode %>% filter(!is.na(glottocode)) %>% rename(language_name=language))
expect_equal(length(unique(wiklangs_gcode$language_name)), 785)

# add glottocodes to forms file and select unique combinations of glottocode and word to be used as filter criteria
wik_forms  <- read_tsv(wik_path, show_col_types = FALSE) %>%
  filter(language_name != "English") %>%
  left_join(wiklangs_gcode %>% select(language_name, glottocode), by="language_name") %>%
  # omit rows where languages have no glottocodes
  filter(!is.na(glottocode)) %>%
  # select combinations where the form doesn't have the same meaning as English form
  filter(same_meaning == "FALSE") %>%
  select(glottocode, word) %>%
  unique()

# we'll filter long form first
counts_long <- read_csv(long_path, show_col_types = FALSE) %>%
  left_join(., dicts %>% select('id', 'glottocode'), by='id')

# drop rows where the filter criteria is met
filtered_counts_long <- counts_long %>%
  anti_join(wik_forms, by = c("glottocode", "word")) %>%
  select(-glottocode)

# change count to NA for rows dropped
revised_counts_long <- counts_long %>%
  inner_join(wik_forms, by = c("glottocode", "word")) %>%
  mutate(count = NA) %>%
  select(-glottocode)

# we'll add new variable "all_wiktionary_filtered_data" which is the sum of the counts for all forms dropped
new_variable <- counts_long %>%
  anti_join(filtered_counts_long, by = c("id", "word")) %>%
  group_by(id) %>%
  summarize(count=sum(count)) %>%
  mutate(word="all_wiktionary_filtered_data")

# write long form
final_counts_long <- bind_rows(filtered_counts_long, revised_counts_long, new_variable) %>%
  write_csv(here("data", "biladataset", "bila_long_nounverbadj_full.csv"))

# assign NAs to zero counts

na_counts_long <- wik_forms %>%
  filter(glottocode %in% dicts$glottocode) %>%
  left_join(dicts %>% select(id, glottocode), by="glottocode", relationship = "many-to-many") %>%
  select(-glottocode) %>%
  mutate(count=NA) %>%
  anti_join(revised_counts_long, by=c("id", "word"))

filtered_counts_wide <- bind_rows(final_counts_long, na_counts_long) %>%
  arrange(word) %>%
  pivot_wider(names_from = word, values_from = count, values_fill = 0)  %>%
  arrange(id) %>%
  write_csv(here("data", "biladataset", "bila_matrix_nounverbadj_full.csv"))

# filter noun set
counts_noun <- read_csv(noun_path, show_col_types = FALSE) %>%
  left_join(., dicts %>% select('id', 'glottocode'), by='id')

filtered_counts_noun <- counts_noun %>%
  anti_join(wik_forms, by = c("glottocode", "word")) %>%
  select(-glottocode)

revised_counts_noun <- counts_noun %>%
  inner_join(wik_forms, by = c("glottocode", "word")) %>%
  mutate(count = NA) %>%
  select(-glottocode)

new_variable_noun <- counts_noun %>%
  anti_join(filtered_counts_noun, by = c("id", "word")) %>%
  group_by(id) %>%
  summarize(count=sum(count)) %>%
  mutate(word="all_wiktionary_filtered_data")

final_counts_noun <- bind_rows(filtered_counts_noun, revised_counts_noun, new_variable_noun) %>%
  write_csv(here("data", "biladataset", "bila_long_noun_full.csv"))

nounset <- unique(counts_noun$word)

na_counts_noun <- wik_forms %>%
  filter(glottocode %in% dicts$glottocode) %>%
  filter(word %in% nounset) %>%
  left_join(dicts %>% select(id, glottocode), by="glottocode", relationship = "many-to-many") %>%
  select(-glottocode) %>%
  mutate(count=NA) %>%
  anti_join(revised_counts_noun, by=c("id", "word"))

filtered_counts_noun_wide <- bind_rows(final_counts_noun, na_counts_noun) %>%
  arrange(word) %>%
  pivot_wider(names_from = word, values_from = count, values_fill = 0)  %>%
  arrange(id) %>%
  write_csv(here("data","biladataset", "bila_matrix_noun_full.csv"))

# forms in 202 languages were filtered
langs_filtered <- counts_long %>%
  anti_join(filtered_counts_long, by = c("id", "word")) %>%
  group_by(glottocode) %>%
  summarize(words_filtered=n_distinct(word)) %>%
  arrange(desc(words_filtered)) %>%
  left_join(dicts %>% select(glottolog_langname, glottocode), by="glottocode") %>%
  unique()
expect_equal(nrow(langs_filtered), 202)

# 14033 unique combinations of language and form were filtered
# 6085 unique forms were filtered
words_filtered <- counts_long %>%
  anti_join(filtered_counts_long, by = c("id", "word")) %>%
  group_by(glottocode, word) %>%
  summarize(sum_count=sum(count)) %>%
  arrange(desc(sum_count)) %>%
  left_join(dicts %>% select(glottolog_langname, glottocode), by="glottocode", relationship = "many-to-many") %>%
  unique() %>%
  write_csv(here("data", "foranalyses", "wiktionary_filtered_combinations.csv"))
expect_equal(nrow(words_filtered), 14033)
expect_equal(length(unique(words_filtered$glottocode)), 202)
expect_equal(length(unique(words_filtered$word)), 6085)
