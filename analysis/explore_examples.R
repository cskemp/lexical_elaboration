library(tidyverse)
library(tidytext)
library(here)
library(glmmTMB)
library(broom.mixed)
library(furrr)
source("analysis/bind_weights_par.R")

dictionaria_path <- here("rawdata", "downloaded", "dictionaria")
matching_files <- list.files(path = dictionaria_path, pattern = "*_examples.csv", recursive = TRUE, full.names = TRUE)

read_dictionaria_file <- function(path) {

  prefix <- basename(path) %>%
    str_remove("_examples\\.csv" )

  d <- read_csv(path)

  df <- d %>%
    rename(ft=Translated_Text, lang=Language_ID) %>%
    #filter(ft != lag(ft, default = first(tx))) %>%
    filter(!str_detect(ft, "^<.*>$")) %>%
    mutate(ftorig = ft) %>%
    mutate(ft = str_replace(ft, " <.*>", "")) %>%
    select(lang, ft) %>%
    mutate(lang = prefix)

  df_tokens <- df %>%
    unnest_tokens(word, ft) %>%
    count(lang, word, sort = TRUE) %>%
    write_csv(here("data", "dictionaria_counts", paste0(prefix, "_counts.csv")))
}

output <- lapply(matching_files, read_dictionaria_file)

dipath <- here("data", "foranalyses", "dictionaria_counts")

file_list <- list.files(path = dipath, pattern = "*_counts.csv", full.names = TRUE)

example_words <- file_list %>%
  map_dfr(read_csv)

lemma <- read_tsv("data/forpreprocessing/lemma_features.tsv")

exw <- example_words %>%
  left_join(lemma %>% rename(word = original_word) %>%
              select(word, lemmatized_word) %>%
              unique(), by = "word") %>%
  group_by(lang, lemmatized_word) %>%
  summarise(count = sum(n)) %>%
  ungroup() %>%
  rename(word = lemmatized_word) %>%
  filter(!is.na(lang), !is.na(word), !is.na(count))

dicts <- read_csv(here("data/biladataset", "bila_dictionaries_full.csv")) %>%
  # read only Dictionaria dictionaries
  filter(access == "clld") %>%
  rename(lang=langname) %>%
  mutate(lang=tolower(lang))

d_wide <- read_csv(here("data", "foranalyses", "d_wide.csv"))

exw2 <- exw %>%
  left_join(dicts %>% select(lang, glottocode), by ="lang") %>%
  mutate(glottocode = ifelse(lang == "sanzhi", "sanz1248", glottocode)) %>%
  mutate(glottocode = ifelse(lang == "medialengua", "medi1245", glottocode)) %>%
  select(-lang) %>% rename(lang = glottocode, countex = count) %>%
  left_join(d_wide, by = c("lang", "word")) %>%
  mutate(countall = countex + count) %>%
  filter(!is.na(countall))

d_noex <- exw2 %>%
  select(-countex, -countall)

d_ex <- exw2 %>%
  select(-countex, -count) %>% rename(count = countall)

# First, we combine counts for seven case studies.

compute_combo <- function(data, terms, combo) {
  data %>%
    filter(word %in% terms) %>%
    group_by(dict, lang, langname, family, total) %>%
    summarise(!!combo := sum(count), .groups = 'drop') %>%
    pivot_longer(cols = !!combo, names_to = "word", values_to = "count")
}

compute_combined_results <- function(data, groups) {
  results <- lapply(names(groups), function(group_name) {
    compute_combo(data, groups[[group_name]], group_name)
  })
  bind_rows(results)
}

groups <- list(
  snow_group = c("snow", "snowball", "snowstorm", "snowfall", "snowflake", "blizzard", "snowdrift", "snowfield", "sleet"),
  ice_group = c("ice", "frost", "glacier", "iceberg"),
  rain_group = c("rain", "raindrop", "rainfall", "rainwater", "drizzle", "mizzle", "downpour", "pelter"),
  wind_group = c("wind", "breeze", "gale", "gust", "squall", "zephyr", "hurricane", "windstorm", "whirlwind", "tornado", "souther", "norther", "wester", "southerly", "northerly", "westerly", "easterly", "northeaster", "southeaster", "northwester", "southwester"),
  smell_group = c("smell", "odor", "scent", "effluvium", "smelling", "sniff", "snuff", "olfaction", "fragrance", "perfume", "stench"),
  taste_group = c("taste", "flavor", "savor", "savoring", "gustation", "taster", "tasting", "aftertaste", "insipidity", "savoriness", "unsavoriness", "sweetness", "sourness", "acidity"),
  dance_group = c("dance", "dancing", "dancer")
)

cases_noex <- compute_combined_results(d_noex, groups)
cases_ex <- compute_combined_results(d_ex, groups)

# Second, we combine counts for terms in claims.

read_claims <- function(path, filename) {
  read_csv(file.path(path, filename)) %>%
    mutate(word_list = strsplit(word_list, ", "))
}

d_claims_distinct <- read_claims("data/foranalyses", "d_claims_distinct.csv")

compute_combo <- function(df, terms, combo) {
  df %>%
    filter(word %in% terms) %>%
    group_by(dict, lang, langname, family, total) %>%
    summarise(!!combo := sum(count), .groups = 'drop') %>%
    pivot_longer(cols = -c(dict, lang, langname, family, total), names_to = "word", values_to = "count") %>%
    unique()
}

process_datasets <- function(dataset_list, claims_data) {
  results <- list()

  for (dataset_name in names(dataset_list)) {
    dataset <- dataset_list[[dataset_name]]
    df_list <- list()

    for (i in seq_len(nrow(claims_data))) {
      terms <- unlist(claims_data$word_list[i])
      combo_name <- claims_data$combo_name[i]
      df_list[[i]] <- compute_combo(dataset, terms, combo_name)
    }

    results[[dataset_name]] <- bind_rows(df_list)
  }

  return(results)
}

datasets <- list(d_noex = d_noex, d_ex = d_ex)
results <- process_datasets(datasets, d_claims_distinct)

claims_noex <- results$d_noex
claims_ex <- results$d_ex

# Third, we bind rows for terms in cases and claims.

all_noex <- bind_rows(cases_noex, claims_noex)
all_ex <- bind_rows(cases_ex, claims_ex)

weights_noex <- bind_weights_par(all_noex)
weights_ex <- bind_weights_par(all_ex)

compare <- weights_ex %>%
  select(lang, word, zeta) %>%
  rename(zeta_with_ex = zeta) %>%
  left_join(weights_noex %>%
              select(lang, word, zeta) %>%
              rename(zeta_without_ex = zeta), by = c("lang", "word"))

length(unique(compare$lang)) #13
length(unique(compare$word)) #70
cor.test(compare$zeta_with_ex, compare$zeta_without_ex) #0.78

theme_font <- theme(
  text = element_text(size = 10),  # Font size for all text elements
  plot.title = element_text(size=10),
  axis.title = element_text(size = 10),  # Font size for axis titles
  axis.text = element_text(size = 9),  # Font size for axis labels
  axis.ticks.x = element_blank(),
  axis.line.x = element_blank(),
  axis.ticks.y = element_blank(),
  axis.line.y = element_blank()
)

p <- ggplot(compare, aes(x = zeta_without_ex, y =zeta_with_ex)) +
  geom_jitter(size=0.5) +
  geom_smooth(method=lm, size=0.3) +
  theme_classic()   +
  theme_font +
  labs(x=expression(L^{lang} * " score based on counts excluding examples"), y=expression(L^{lang} * " score based on counts including examples")) +
  annotate("text", x = 6, y = Inf, label = "r = 0.78***", size = 4, hjust = 1.2, vjust = 1.2)

ggsave(here("output/figures/supplementary", "dictionaria.pdf"), p, width = 5, height = 4.5)
