library(tidyverse)
library(here)
library(igraph)
library(readxl)
library(testthat)

dict_path <- here("data", "biladataset", "bila_dictionaries_full.csv")
wordcount_path <- here("data", "biladataset", "bila_matrix_nounverbadj_full.csv")
wordcount_long_path <- here("data", "biladataset", "bila_long_nounverbadj_full.csv")
wordcount_noun_path <- here("data", "biladataset", "bila_long_noun_full.csv")

# dictionaries with duplicates
d_dup <- read_csv(dict_path)

# the full version includes 2671 dictionaries in 659 languages
expect_equal(nrow(d_dup), 2671)
expect_equal(length(unique(d_dup$glottocode)), 659)

idlang <- d_dup %>%
  select(id, langname, title, imprint, year, glottocode)

swadesh <- read_tsv(here("rawdata", "downloaded", "Swadesh-1955-215.tsv")) %>%
  mutate(word = ENGLISH) %>%
  select(word) %>%
  mutate(word = str_replace(word, "\\*", "")) %>%
  mutate(word = map_chr(str_split(word, " "), 1))

wordcount <-  read_csv(wordcount_path,  col_types = cols(id = col_character(),
                                           .default=col_double()))

expect_equal(length(setdiff(d_dup$id, wordcount$id)), 0)
expect_equal(length(setdiff(wordcount$id, d_dup$id)), 0)

# the full version includes 20213 tokens of nouns, verbs, and adjectives
wordcount_long <-  read_csv(wordcount_long_path) %>%
  filter(!endsWith(word, "_data"))
expect_equal(length(unique(wordcount_long$word)), 20213)

# the full version includes 12036 noun tokens
wordcount_noun <-  read_csv(wordcount_noun_path) %>%
  filter(!endsWith(word, "_data"))
expect_equal(length(unique(wordcount_noun$word)), 12036)

# Dropping small dictionaries and dictionaries with engprop <30 reduces the set of distinct glottocodes from 659 to 615 in size.

d_counts <- wordcount %>%
  # we treat wiktionary-filtered forms as non-English forms
  mutate(engprop_data = 100*(all_english_count_data-all_wiktionary_filtered_data)/all_token_count_data) %>%
  # keep only dictionaries with 5000 or more total tokens and engprop > 30
  filter(all_token_count_data >= 5000 & engprop_data >= 30) %>%
  select(id, any_of(swadesh$word)) %>%
  mutate(swadesh_word_count_data = select(., !(ends_with("_data") | id)) %>% apply(1, sum, na.rm=TRUE)) %>%
  # normalize counts across swadesh words
  mutate(across(-c(id, ends_with("_data")), ~(.x * 1000/swadesh_word_count_data))) %>%
  select(id,  !(ends_with("_data"))) %>%
  mutate_all(~replace_na(., 0))

# should be no NAs anywhere
expect_false(any(is.na(d_counts)))

#dups <- c("pacific.middlekhmer_jenner_midd1376",  "uc1.31822038792743", "webonary.buli_kroger_buli1254", "uva.x002254364",   "other.hawaiian_pukui_hawa1245",  "uva.x002399497", "uiug.30112058487908", "uva.x004477031", "hawaii.ilokano_constantino_ilok1237",  "pacific.tetun_morris_tetu1246", "uva.x001223031")

#sparkd_dups <- sparkd %>%
#  filter(id %in% dups)

#sparkd <- sparkd %>%
#  head(10) %>%
#  bind_rows(sparkd_dups)

distances <- dist(d_counts[, -1], method = "euclidean")
# Convert the distances to a square matrix
distance_matrix <- as.matrix(distances)
rownames(distance_matrix) <- d_counts$id
colnames(distance_matrix) <- d_counts$id

distances_long <- as_tibble(as.data.frame(distance_matrix)) %>%
  mutate(id_a = d_counts$id) %>%
  gather(key = "id_b", value = "distance", -id_a)

close_dictionaries <- distances_long %>%
  filter(id_a != id_b) %>%
  arrange(distance) %>%
  head(5000) %>%
  left_join(idlang, by = c("id_a" = "id")) %>%
  left_join(idlang, by = c("id_b" = "id")) %>%
  rename(langname_a = langname.x, title_a = title.x, imprint_a = imprint.x, year_a = year.x, glottocode_a = glottocode.x,
         langname_b = langname.y, title_b = title.y, imprint_b = imprint.y, year_b = year.y, glottocode_b = glottocode.y)  %>%
  select(distance, langname_a, langname_b, title_a, imprint_a, year_a, title_b, imprint_b, year_b, id_a, id_b, glottocode_a, glottocode_b) %>%
  write_csv(here("data", "forpreprocessing", "close_dictionaries.csv"))

# top 1708 pairs
cl_thresh = 33

# treat pairs as duplicates if their vectors are similar (distance < cl_thresh) and if their glottocodes match
graphcd <- close_dictionaries  %>%
  filter(distance <= cl_thresh) %>%
  filter(glottocode_a == glottocode_b) %>%
  select(id_a, id_b)

# inspecting close pairs with different glottcodes suggests that we should remove Oxford-Duden pictorial dictionaries and photo dictionaries
nonmatch_check <- close_dictionaries  %>%
  filter(distance <= cl_thresh) %>%
  filter(glottocode_a != glottocode_b)

g <- graph_from_data_frame(graphcd)
dict_clusters <- enframe(clusters(g)$membership, name = "id", value = "dcluster") %>%
  mutate(dcluster = as.integer(dcluster) + nrow(d_dup))

d <- d_dup %>%
  # drop dictionaries that were excluded from d_counts for being too small or having small engprop
  filter(id %in% d_counts$id) %>%
  mutate(cluster = row_number()) %>%
  left_join(dict_clusters, by="id") %>%
  mutate(cluster = if_else(!is.na(dcluster), dcluster, cluster)) %>%
  select(-dcluster) %>%
  group_by(cluster) %>%
  # take the most recent entry out of each duplicate pair
  filter(year== max(year))  %>%
  slice(1) %>%
  ungroup()

d_standard <- d_dup %>%
  filter(id %in% d$id) %>%
  filter(!str_detect(title, "Oxford-Duden")) %>%
  # delete picture dictionaries
  filter(!str_detect(title, "photo dictionary")) %>%
  filter(!str_detect(title, "picture")) %>%
  filter(!str_detect(title, "Picture")) %>%
  filter(!str_detect(title, "pictorial")) %>%
  filter(!str_detect(title, "visual")) %>%
  write_csv(here("data", "biladataset", "bila_dictionaries.csv"))

# the standard version includes dictionaries in languages
expect_equal(nrow(d_standard),1606)
expect_equal(length(unique(d_standard$glottocode)),617)

# write standard versions

bila_matrix_nounverbadj <- read_csv( here("data", "biladataset", "bila_matrix_nounverbadj_full.csv")) %>%
  filter(id %in% d_standard$id) %>%
  write_csv(here("data", "biladataset", "bila_matrix_nounverbadj.csv"))

bila_long_nounverbadj <- read_csv( here("data", "biladataset", "bila_long_nounverbadj_full.csv")) %>%
  filter(id %in% d_standard$id) %>%
  write_csv(here("data", "biladataset", "bila_long_nounverbadj.csv"))

# the standard version includes 20208 tokens of nouns, verbs, and adjectives
wordcount_long_standard <-  bila_long_nounverbadj %>%
  filter(!endsWith(word, "_data"))
expect_equal(length(unique(wordcount_long_standard$word)), 20208)

bila_matrix_noun <- read_csv( here("data", "biladataset", "bila_matrix_noun_full.csv")) %>%
  filter(id %in% d_standard$id) %>%
  write_csv(here("data", "biladataset", "bila_matrix_noun.csv"))

bila_long_noun <- read_csv( here("data", "biladataset", "bila_long_noun_full.csv")) %>%
  filter(id %in% d_standard$id) %>%
  write_csv(here("data", "biladataset", "bila_long_noun.csv"))

# the standard version includes 12031 noun tokens
wordcount_noun_standard <-  bila_long_noun %>%
  filter(!endsWith(word, "_data"))
expect_equal(length(unique(wordcount_noun_standard$word)), 12031)

# now we'll write lemmatized version for noun

feature_path <- here("data", "forpreprocessing", "lemma_features.tsv")

# load information extracted from wordnet
features <- read_tsv(feature_path) %>%
  rename(word = original_word) %>%
  mutate(
    nsenses = if_else(str_ends(word, "_data"), NA_integer_, nsenses),
  )

# now we change lemmatized noun in UK variant with that of US variant to combine counts for, say, odor and odour

spelling <- read_csv(here("rawdata", "downloaded", "uk_us_spelling.csv")) %>%
  filter(US %in% bila_long_noun$word) %>%
  rename(word = US) %>%
  left_join(features %>% select(word, lemmatized_word), by = "word")

for (i in 1:nrow(features)) {
  if (features$word[i] %in% spelling$UK) {
    index <- which(spelling$UK == features$word[i])
    features$lemmatized_word[i] <- spelling$lemmatized_word[index]
  }
}

features <- features %>%
  group_by(lemmatized_word) %>%
  mutate(nsenses = max(nsenses)) %>%
  ungroup()

bila_long_noun_lemmatized <- bila_long_noun %>%
  left_join(features, by="word") %>%
  group_by(id, lemmatized_word, nsenses) %>%
  summarise(count=sum(count)) %>%
  ungroup() %>%
  rename(word=lemmatized_word) %>%
  write_csv(here("data", "biladataset", "bila_long_noun_lemmatized.csv"))

# the lemmatized version includes 8577 noun tokens
wordcount_lemma_standard <-  bila_long_noun_lemmatized %>%
  filter(!endsWith(word, "_data"))
expect_equal(length(unique(wordcount_lemma_standard$word)), 8577)
