
library(tidyverse)
library(here)
library(stringr)
library(pluralize)
# install using
# renv::install("hrbrmstr/pluralize")

# Make whitelist of words to include in BILA even if they fall below frequency threshold later.
# All words on the whitelist are relevant to the analysis of existing claims.

#vocab_path <- here("output", "nounverbadj_vocab.p")
#
## get UK spellings of words present in BILA
#
#spelling_path <- here("data", "forpreprocessing", "uk_us_spelling.csv")
#
#wordsinbila <- readp(vocab_path)
#
#spellinguk <- read_csv(spelling_path) %>%
#  filter(US %in% wordsinbila) %>%
#  pull(UK)

# get absent words in analyses

claims_path <- here("rawdata", "manuallycreated", "examples_of_lexical_elaboration.csv")

wordsinclaims <- read_csv(claims_path) %>%
  mutate(word = str_split(str_replace_all(word_list, "\\s+", ""), ",")) %>%
  unnest(word) %>%
  distinct(word) %>%
  na.omit() %>%
  pull(word)

pluralwordsinclaims <- pluralize(wordsinclaims)

snow_group <- c("snow", "snowball", "snowstorm", "snowfall", "snowflake", "blizzard", "snowdrift", "snowfield", "sleet")
ice_group <- c("ice", "frost", "glacier", "iceberg")
rain_group <- c("rain", "raindrop", "rainfall", "rainwater", "drizzle", "mizzle", "downpour", "pelter")
wind_group <- c("wind", "breeze", "gale", "gust", "squall", "zephyr", "hurricane", "windstorm", "whirlwind", "tornado", "souther", "norther", "wester", "southerly", "northerly", "westerly", "easterly", "northeaster", "southeaster", "northwester", "southwester")
smell_group <- c("smell", "odor", "scent", "effluvium", "smelling", "sniff", "snuff", "olfaction", "fragrance", "perfume", "stench")
taste_group <- c("taste", "flavor", "savor", "savoring", "gustation", "taster", "tasting", "aftertaste", "insipidity", "savoriness", "unsavoriness", "sweetness", "sourness", "acidity")
dance_group <- c("dance", "dancing", "dancer")

wordsincases <- c(snow_group, ice_group, rain_group, wind_group, smell_group, taste_group, dance_group)
pluralwordsincases <- pluralize(wordsincases)

whitelist <- unique(c(wordsinclaims, pluralwordsinclaims, wordsincases, pluralwordsincases)) %>%
  writeLines(here("data", "forpreprocessing", "whitelist.txt"))
