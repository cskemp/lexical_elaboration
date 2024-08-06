# This R file produces results of L^lang scores used for the app.

library(tidyverse)
library(glmmTMB)
library(here)
library(furrr)
library(broom.mixed)

# Run this in a stand-alone console, not RStudio (because RStudio doesn't support future_map() )

source("bind_weights_par.R")

d_wide <- read_csv(here("data", "foranalyses", "d_wide.csv"))

weights_lr <-  bind_weights_par(d_wide) %>%
  write_csv(here("output", "results", "hierarchical_lr_lang.csv"))

my_mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

lang_data <- read_csv(here("data", "biladataset", "bila_dictionaries.csv")) %>%
    select(-langname) %>%
    # now use glottolog_langname
    rename(langname = glottolog_langname) %>%
    select(langname, glottocode, area, langfamily, longitude, latitude) %>%
    unique() %>%
    group_by(glottocode, area, langfamily, longitude, latitude) %>%
    summarize(langname = my_mode(langname))

app_data <- weights_lr %>%
    select(lang, word, zeta) %>%
    rename(glottocode = lang) %>%
    left_join(lang_data, by = "glottocode") %>%
    arrange(desc(zeta)) %>%
    write_csv(here("output", "results", "bila_app_stats.csv"))

# make smaller version for online Shiny app
word_counts <- d_wide %>%
    group_by(word) %>%
    summarize(count = sum(count)) %>%
    arrange(desc(count))

top_words_medium <- word_counts %>%
    head(6000)

top_words_small <- top_words_medium %>%
    head(2000)

app_data_medium <- app_data %>%
    filter(word %in% top_words_medium$word) %>%
    write_csv(here("output", "results", "bila_app_stats_6000.csv"))

app_data_small <- app_data %>%
    filter(word %in% top_words_small$word) %>%
    write_csv(here("output", "results", "bila_app_stats_2000.csv"))

