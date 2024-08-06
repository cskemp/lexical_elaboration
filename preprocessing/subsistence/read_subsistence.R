library(here)
library(dplyr)
library(tidyverse)
library(testthat)
library(lingtypology)

# we first load subsistence data from Cysouw and Comrie (2013)
wals <- read_csv(here("rawdata", "downloaded", "wals_languages.csv"), show_col_types = FALSE) %>%
  rename(wals_code=ID, glottocode=Glottocode)
cysouw <- read_csv(here("rawdata", "downloaded", "cysouwc_huntergatherer.csv")) %>%
  left_join(wals %>% select(wals_code, glottocode), by="wals_code")  %>%
  select('glottocode') %>%
  mutate(subsistence="hunter-gatherer", source="cysouwc_2013")
# 4 languages don't have glottocode but we didn't try to assign glottocode because they are not present in BILA
no_gcode_cysouw <- cysouw %>%
  filter(is.na(glottocode))

# load subsistence data from Guldemann et al. (2020)
guldemann <- read_csv(here("rawdata", "downloaded", "guldemann_forager.csv")) %>%
  left_join(glottolog %>% select(glottocode, iso), by="iso") %>%
  select('glottocode') %>%
  mutate(subsistence="hunter-gatherer", source="guldemannmr_2020")
# 5 languages don't have matching iso code in glottolog
no_gcode_guldemann <- guldemann %>%
  filter(is.na(glottocode))

# load subsistence data from Autotyp (downloaded from the github on 18 March 2024)
autotyp <- read_csv(here("rawdata", "downloaded", "autotyp_languages.csv")) %>%
  rename(glottocode=Glottocode, subsistence=Subsistence) %>%
  select(glottocode, subsistence) %>%
  filter(!is.na(subsistence)) %>%
  mutate(subsistence=case_when(
    subsistence=='hg' ~ 'hunter-gatherer',
    subsistence=='not hg' ~ 'other',
    TRUE ~ as.character(subsistence)
  ), source = "autotyp")

# load subsistence data from D-Place

csv_files <- list.files(here("rawdata", "downloaded", "dplace"), pattern = "^dplace_subsistence.*\\.csv$", full.names = TRUE)

df_list <- list()

for (file_path in csv_files) {
  category <- gsub("^dplace_(.*?)\\.csv$", "\\1", basename(file_path))

  df <- read_csv(file_path, show_col_types = FALSE) %>%
    select('language_glottocode', 'code_label', 'code') %>%
    rename(glottocode = 'language_glottocode') %>%
    mutate(!!paste0("label_", category) := code_label) %>%
    mutate(!!paste0("code_", category) := code)

  df_list[[category]] <- df
}

left_join_df <- function(df1, df2) {
  left_join(df1, df2, by = "glottocode", relationship = "many-to-many")
}

# write to one file
result_df <- reduce(df_list, left_join_df) %>%
  select(-starts_with("code_label"), -starts_with("code.")) %>%
  filter(!if_all(starts_with("label") | starts_with("code"), is.na)) %>%
  distinct()

assign("dplace_hunter", result_df, envir = .GlobalEnv)

dplace <- dplace_hunter %>%
  select(glottocode, starts_with("label_subsistence")) %>%
  distinct() %>%
  mutate(subsistence = ifelse(is.na(label_subsistenceeconomy_dominantactivity), label_subsistenceeconomy_mostimportantactivity, label_subsistenceeconomy_dominantactivity)) %>%
  mutate(subsistence = ifelse(label_subsistenceeconomy_dominantactivity == "Two or more sources", label_subsistenceeconomy_mostimportantactivity, label_subsistenceeconomy_dominantactivity)) %>%
  mutate(subsistence = case_when(
    subsistence == "Pastoralism" ~ "other",
    subsistence == "Extensive agriculture" ~ "other",
    subsistence == "Intensive agriculture" ~ "other",
    subsistence == "Agriculture, type unknown" ~ "other",
    subsistence == "Hunting" ~ "hunter-gatherer",
    subsistence == "Fishing" ~ "hunter-gatherer",
    subsistence == "Fishing (aquatic)" ~ "hunter-gatherer",
    subsistence == "Gathering" ~ "hunter-gatherer",
    TRUE ~ as.character(subsistence)
  )) %>%
  mutate(subsistence = case_when(
    glottocode == "chuu1238" ~ "other",
    glottocode == "tiko1237" ~ "other",
    TRUE ~ as.character(subsistence)
  )) %>%
  select(glottocode, subsistence) %>%
  filter(!is.na(subsistence)) %>%
  mutate(source = "dplace") %>%
  distinct()

# combine all
all_hunter <- bind_rows(cysouw, guldemann, autotyp, dplace) %>%
  unique()

# see if different subsistence strategy is assigned to the same language
duplicates <- all_hunter %>%
  group_by(glottocode) %>%
  filter(n_distinct(subsistence) > 1) %>%
  ungroup() %>%
  arrange(glottocode)
# there are 111 languages assigned different subsistence strategy
expect_equal(length(unique(duplicates$glottocode)), 111)

# preference was given to Guldemann et al. (2020), Cysouw and Comrie (2013), and D-Place to assign unique subsistence.
priority_order <- c("guldemannmr_2020", "cysouwc_2013", "dplace", "autotyp")

prefer_source <- function(df) {
  df <- df[order(match(df$source, priority_order)), ]
  return(df[1, ])
}

all_hunter_unique <- all_hunter %>%
  group_by(glottocode) %>%
  do(prefer_source(.)) %>%
  ungroup() %>%
  filter(!is.na(glottocode)) %>%
  write_csv(here("data", "forpreprocessing", "subsistence.csv"))
