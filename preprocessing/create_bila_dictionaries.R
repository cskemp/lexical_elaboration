library(here)
library(dplyr)
library(tidyverse)
library(stringr)
library(lingtypology)
library(testthat)

full_file <- here("preprocessing", "hathi_trust", "01_initial_volumes.csv")
coded_file <- here("preprocessing", "hathi_trust", "02_with_gcodes.csv")
coded_file_nonht  <- here("rawdata", "manuallycreated", "nonhathi_dictionaries.csv")

# we only keep hathi ids for which we have counts
counts_path <- here("data", "biladataset", "bila_long_nounverbadj_unfiltered_full.csv")
popn_size_path <- here("rawdata",  "manuallycreated", "popn_size.csv")
subsistence_path <- here("data",  "forpreprocessing", "subsistence.csv")

count_ids <- read_csv(counts_path)  %>%
  select(id) %>%
  unique()

full <- read_csv(full_file) %>%
  select(id, oclc, lcc, access, rights) %>%
  rename(access_ht = access)

coded <-  read_csv(coded_file)  %>%
  bind_rows(read_csv(coded_file_nonht)) %>%
  select(id, year, title, author, imprint, dictlangname, newlangname, langname, collection, url, copyright, doreco, type, access, gcode, subclass)  %>%
  mutate(langnameht = if_else(!is.na(newlangname), newlangname, dictlangname)) %>%
  mutate(langname = if_else(!is.na(langname), langname, langnameht)) %>%
  rename(glottocode = gcode) %>%
  select(-dictlangname, newlangname)

bila_dicts <-  count_ids %>%
  left_join(coded, by = "id") %>%
  left_join(full, by = "id") %>%
  mutate(access = if_else(!is.na(access), access, access_ht)) %>%
  select(-access_ht)

gl <- glottolog %>%
  select(language, glottocode, area, affiliation, longitude, latitude) %>%
  # remove initial parentheses
  mutate(glottolog_langname= str_replace(language, " \\(.*\\)", "")) %>%
  mutate(langfamily=affiliation) %>%
  #separate_wider_delim(langfamily, delim = ",", names = c("langfamily", NA), too_few = "debug", too_many = "debug") %>%
  mutate(langfamily_split= str_split(affiliation, ", ")) %>%
  mutate(langfamily = map_chr(langfamily_split, 1)) %>%
  select(-language, -langfamily_split)

# specify a floor of 100 for population size
popn_size <- read_csv(popn_size_path) %>%
  mutate(population = if_else(population<100, 100, population))
# load mode of subsistence information
subsistence <- read_csv(subsistence_path)

bila_dicts <- bila_dicts %>%
  left_join(gl, by="glottocode") %>%
  left_join(popn_size %>% select(population, glottocode), by="glottocode") %>%
  left_join(subsistence %>% select(subsistence, glottocode), by="glottocode") %>%
  # assign "other" to languages missing subsistence information
  mutate(subsistence = ifelse(is.na(subsistence), "other", subsistence)) %>%
  select(id, year, title, imprint, author, langname, glottolog_langname, subclass, glottocode, area, langfamily, affiliation, longitude, latitude, population, subsistence, doreco, oclc, lcc, access, url, rights, copyright)

# there should be no missing glottocodes
expect_equal(sum(is.na(bila_dicts$glottocode)), 0)
# there should be no missing population information
expect_equal(sum(is.na(bila_dicts$population)), 0)
# there should be no missing subsistence information
expect_equal(sum(is.na(bila_dicts$subsistence)), 0)

langcounts <- bila_dicts %>%
  group_by(area, langfamily, glottocode, glottolog_langname, latitude, population, subsistence) %>%
  summarize(count=n()) %>%
  ungroup()

## area is missing for Hindustani (hind1270) and Mayan (maya1287). We'll use Eurasian and North America.
expect_equal( langcounts %>% filter(area == "") %>% nrow(), 2)
## family is missing for  Fuyug (fuyu1242), Savosavo (savo1255), Mayan (maya1287),  Tiwi (tiwi1244),  Sumerian (sume1241),  Basque (basq1248), Zuni (zuni1245), Yana (yana1271), Tunica (tuni1252), Tonkawa (tonk1249), Klamath-Modoc (klam1254), Atakapa (atak1252), Yámana (yama1264), Warao (wara1303), Cayubaba (cayu1262). We'll treat as isolates.
expect_equal( langcounts %>% filter(langfamily== "") %>% nrow(), 15)
## latitude and longitude are missing for Pidgin Chinook Jargon (pidg1254). We'll use values that match those of chin1272  (see  https://en.wikipedia.org/wiki/Chinook_Jargon )
expect_equal( langcounts %>% filter(is.na(latitude)) %>% nrow(), 1)

chin1272 <- gl %>% filter(glottocode == "chin1272")

bila_dicts <- bila_dicts %>%
  mutate(langfamily = if_else(glottocode == "maya1287", "Mayan", langfamily)) %>%
  mutate(langfamily = if_else(langfamily == "", paste0("isolate_", glottocode), langfamily)) %>%
  mutate(langfamily = if_else(langfamily == "Mixed Language", paste0("mixedlanguage_", glottocode), langfamily)) %>%
  mutate(area = if_else(glottocode == "hind1270", "Eurasian", area)) %>%
  mutate(area = if_else(glottocode == "maya1287", "North America", area)) %>%
  mutate(latitude = if_else(glottocode == "pidg1254", chin1272$latitude, latitude)) %>%
  mutate(longitude= if_else(glottocode == "pidg1254", chin1272$longitude, longitude)) %>%
  mutate(year = if_else(year == 9999, -9999, year)) %>%
  arrange(glottolog_langname, title, desc(year))

# no longer expect any missing or empty entries
any_missing_empty <- bila_dicts %>%
  summarise_all(~ any(is.na(.) | . == "")) %>%
  select(id, year, title, langname, glottolog_langname, glottocode, area, langfamily, longitude, latitude)

all_elements_false <- any_missing_empty %>%
  rowwise() %>%
  summarise(all_false = all(c_across(everything()) == FALSE)) %>%
  pull()

expect_true(all_elements_false)

write_csv(bila_dicts, here("data", "biladataset", "bila_dictionaries_full.csv"))
