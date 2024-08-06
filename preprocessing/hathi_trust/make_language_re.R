library(here)
library(dplyr)
library(tidyverse)
library(lingtypology)
library(unidecoder)
library(stringi)

# https://github.com/rich-iannone/UnidecodeR
# devtools::install_github("rich-iannone/unidecoder")

# data/forpreprocessing/glottolog_variant_names.tsv was created by running
# > python read_glottolog_language_names.py > ../../data/forpreprocessing/glottolog_variant_names.tsv

lstring <- read_delim(here("data/forpreprocessing/glottolog_variant_names.tsv"), delim = "\t") %>%
  mutate(l_no_parens = str_replace(label, " \\(.*\\)", "")) %>%
  mutate(num_words = str_count(l_no_parens, "[^\\s]+")) %>%
  mutate(contains_digits = str_detect(l_no_parens, "\\d+")) %>%
  filter(num_words == 1 & !(contains_digits)) %>%
  mutate(name_len = nchar(l_no_parens)) %>%
  mutate(alnum= str_replace_all(l_no_parens, "[^[:alnum:]]", "")) %>%
  mutate(without_accents = stri_trans_general(l_no_parens, "Latin-ASCII"))

# Some of these are genuine language names, but most hits for the genuine names are spurious. Removing a few genuine names is OK
# because some dictionaries for these languages will still be picked up (e.g. if they have English in the title)

stopwords <- c("The", "the", "In", "in", "To", "to", "For", "for", "Britannica", "J", "J.", "W", "W.", "M", "M)", "E",
               "Lee", "Music", "De", "Al", "is", "Men", "etc", "etc.", "Being", "Are", "As", "As.", "as", "Dana", "Have", "Day",  "Dian",
               "More", "more", "War", "U", "That", "Ci", "Bian", "One", "Four", "Be", "Some", "Alan", "Da", "Ik", "La", "Non", "May",
               "Lang", "Age", "Man", "Co", "Pa", "Wo", "Die", "u", "Late", "Le", "Con", "Den", "Usage", "Ji", "Wa", "Yu", "Bu", "Du", "Van",
               "White", "Ma", "West", "Dem", "This", "Shu", "Yi", "Shi", "South", "Western", "Na", "Central", "central", "Ke", "Wu",
               "Ten", "Home", "So", "Su", "Ho", "Ab", "Jo", "Te", "Para", "Hua", "Chen", "East", "Same", "same", "Vo", "But", "Sa",
               "Cheng", "Fa", "Yuan", "Yo", "Eastern", "Maria", "Se", "Jargon", "Thompson", "Una", "Yong", "Wen", "Island", "Mining",
               "Alle", "Gong",  "Moore", "Jie", "Til", "Standard", "King", "Pro", "Coast", "DO", "Do", "SI", "Si", "Air", "Esperanto",
               "Han", "Latinum", "Lengua", "Hui", "Castellano", "Norman", "Dai", "San", "Ko", "Sam", "Ba", "Mu", "Ri", "Tu", "Mo",
               "Gu", "Lu", "Me", "Chi", "Cho", "Ku", "Ben", "Dan", "Io", "Leo", "Northern", "Southern", "esperanto", "southern",
               "Maritime", "Gold", "These", "Were", "Interior", "Of", "S", "B", "E.", "S.", "B.", "Book", "Ei", "Li", "En",  "Zi",
               "Chu", "Copper", "Di", "No", "Among", "Wei", "Cor", "Yin", "Par", "Jing", "Fu", "Leonard", "Cant", "Por", "Colin",
               "Tom", "Allan", "Plain", "Frances", "Sussex", "Linda", "Era", "Golden", "Massachusetts"       )

all_names <-  lstring %>%
  select(label, l_no_parens, alnum, without_accents) %>%
  pivot_longer(c("l_no_parens", "alnum", "without_accents"), values_to = "name_string") %>%
  select(name_string) %>%
  unique() %>%
  arrange(name_string) %>%
  filter(!(name_string %in% stopwords))

 write_csv(all_names, here("data", "forpreprocessing", "language_names.csv"))
