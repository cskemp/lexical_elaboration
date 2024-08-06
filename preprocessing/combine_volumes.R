library(tidyverse)
library(here)
library(testthat)

# Run this from the command line with the pos as the single argument : e.g  > Rscript combine_volumes.R noun

args = commandArgs(trailingOnly=TRUE)
expect_equal(length(args), 1)
pos <- args[1]

#pos <- "nounverbadj"

expect_true(pos == "noun" | pos == "nounverbadj")

counts_path <- here("data/forpreprocessing", paste0("dictionary_counts_", pos, ".csv"))

out_path <- here("data", "biladataset", paste0("bila_long_", pos, "_unfiltered_full.csv"))
out_path_wide <- here("data", "biladataset", paste0("bila_matrix_", pos, "_unfiltered_full.csv"))

volid_ht_path <- here("preprocessing", "hathi_trust", "02_with_gcodes.csv")
volid_nonht_path <- here("rawdata", "manuallycreated", "nonhathi_dictionaries.csv")

id_file <-  here("preprocessing", "hathi_trust", "02_hathi_ids.txt")
path_file <-  here("preprocessing", "hathi_trust",  "02_hathi_ids_sanitized.txt")

ids_orig <- read_tsv(id_file, col_names = FALSE) %>%
  setNames(c("id"))
ids_san <- read_tsv(path_file, col_names = FALSE) %>%
  setNames(c("path")) %>%
  mutate(id_sanitized= str_remove(basename(path), ".json.bz2"))

# Check that ids_orig and ids_san have the same lengths
expect_equal(nrow(ids_orig), nrow(ids_san))
ids <- bind_cols(ids_orig, ids_san) %>%
  select(-path)

# add non-hathi
nonht_ids <- read_csv(volid_nonht_path) %>%
  select(id) %>%
  mutate(id_sanitized = id)

ids <- bind_rows(ids, nonht_ids)

vols <- ids %>%
  rename(volume = id, volume_sanitized = id_sanitized)

# read in information about volumes to be combined
volid <- read_csv(volid_nonht_path) %>%
  bind_rows(read_csv(volid_ht_path)) %>%
  select(id, volume) %>%
  mutate(volume = if_else(!is.na(volume), volume, id)) %>%
  left_join(ids, by = "id") %>%
  left_join(vols, by = "volume") %>%
  select(id_sanitized, volume_sanitized)

# when a non_ht dictionary duplicates a ht dictionary, drop the ht dictionary
drop_list <- read_csv(volid_nonht_path) %>%
  select(duplicate_hathitrust) %>%
  filter(!is.na(duplicate_hathitrust)) %>%
  unique() %>%
  pull()

counts <- read_csv(counts_path, col_types = cols(id_sanitized = col_character(), word = col_character(), count = col_integer())) %>%
  left_join(volid, by = "id_sanitized") %>%
  group_by(volume_sanitized, word) %>%
  summarize(count = sum(count)) %>%
  ungroup() %>%
  rename(id_sanitized = volume_sanitized) %>%
  left_join(ids, by = "id_sanitized") %>%
  select(id, word, count) %>%
  filter(!(id %in% drop_list)) %>%
  write_csv(out_path)

# may have NA here if non-hathi directory is not consistent with data/nonhathi_dictionaries.csv
expect_equal(sum(is.na(counts$id)), 0)

counts_wide <- counts  %>%
  arrange(word) %>%
  pivot_wider(names_from = word, values_from = count, values_fill = 0)  %>%
  arrange(id) %>%
  write_csv(out_path_wide)

