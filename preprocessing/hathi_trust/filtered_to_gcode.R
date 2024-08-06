library(here)
library(dplyr)
library(tidyverse)
library(lingtypology)
library(stringr)

# Prepare file used for annotating dictionary titles with glottocodes. We use simple string matching to make
# initial guesses about the glottocodes for many dictionaries. For all titles that match up to punctuation, we keep only
# a single representative of the title.

phase1_file <- here("preprocessing", "hathi_trust", "01_initial_volumes.csv")
outfile <-  here("preprocessing", "hathi_trust", "02_with_gcodes_starter.csv")

# Listing of all ids in the Extended Features data set
ef_masterlist_path <- here("preprocessing", "hathi_trust", "ef_file_listing.txt")

# ef_masterlist names have +,= and also have commas
ef_masterlist <- read_delim(ef_masterlist_path, delim = '\t', col_names = FALSE) %>%
  mutate(id = basename(X1)) %>%
  mutate(id = str_replace(id,  ".json.bz2$", "")) %>%
  mutate(id_strip = gsub("[+:=/]", "", id)) %>%
  mutate(id_strip = str_replace_all(id_strip, ",", ".")) %>%
  select(id_strip) %>%
  mutate(ef = 1)

lstring <- glottolog %>%
  select(language) %>%
  mutate(orig_language = language) %>%
  # remove initial parentheses
  mutate(language = str_replace(language, " \\(.*\\)", ""))

gl <- glottolog %>%
  select(language) %>%
  mutate(orig_language = language) %>%
  # remove initial parentheses
  mutate(language = str_replace(language, " \\(.*\\)", "")) %>%
  # keep only alphabet characters, space, hyphen
  mutate(language = gsub("[^a-zA-Z \\-]", "", language))  %>%
  mutate(length = nchar(language)) %>%
  filter(length >2) %>%
  filter(language !="English") %>%
  arrange(desc(length))

# make regex to use when matching language names
langnames <- gl$language %>%
  paste(collapse="|")

dl <- read_csv(phase1_file) %>%
  mutate(id_strip = gsub("[+:=/]", "", id)) %>%
  mutate(id_strip = str_replace_all(id_strip, ",", ".")) %>%
  # keep only volumes classified as good
  filter(classification==1) %>%
  select(-classification, -reason) %>%
  mutate(title_strip = sub("^[\\[\\(]", "", title)) %>%
  mutate(title_strip = str_to_lower(gsub("[^a-zA-Z]", "", title_strip)))  %>%
  # combine title_strip with enumeration so that different volumes of the same dictionary are preserved
  mutate(title_strip = paste(title_strip, enumeration)) %>%
  left_join(ef_masterlist, by = "id_strip") %>%
  # prefer volumes in EF set, newer volumes, and volumes with an OCLC code
  arrange(title_strip, ef, desc(year), oclc)  %>%
  # strip titles that match up to punctuation.
  distinct(title_strip, .keep_all=TRUE) %>%
  filter(ef == 1) %>% # around 383 dictionaries are dropped because they're not in the extended features data set
  select(id, year, title, enumeration, imprint)

longest <- function(ls) {
  if (length(ls) > 0) {
    return(ls[nchar(ls) == max(nchar(ls))][1])
  } else {
    return(NA)
  }
}

short2long<- function(short) {
  if (is.na(short)) {
    return(NA)
  } else {}
    return(gl$orig_language[gl$language==short])
}

short2long_v<- Vectorize(short2long)

get_gcode <- function(langname) {
  gcode <- gltc.lang(langname)
}

pastelist <- function(l) {
  pl <- paste(l, collapse=":")
}
pastelist_v <- Vectorize(pastelist)

dl <- dl %>%
  mutate(autolangname = sapply(str_extract_all(title, langnames), longest)) %>%
  mutate(autolangname = short2long_v(autolangname)) %>%
  mutate(autogcode= sapply(autolangname, get_gcode)) %>%
  mutate(dictlangname = '', gcode='', duplicate='', newlangname ='', newlangnamelink='', delete='', review_flag='') %>%
  mutate(autolangname = pastelist_v(autolangname), autogcode = pastelist_v(autogcode))

write_csv(dl, outfile)
