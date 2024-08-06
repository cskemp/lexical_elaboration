library(tidyverse)
library(here)
library(pdftools)

# folder containing PDF files
pdf_folder <- here("rawdata", "downloaded", "nonhathi_class")

# output folder
output_folder <- here("data", "foranalyses", "pdf_search")

# strings to search for

# load word lists used for concept rain, smell, and taste: they are taken from ../analysis/analyze_cases.Rmd
rain_initial <- c("rain", "raindrop", "rainfall", "rainwater", "drizzle", "mizzle", "downpour", "pelter")
smell_initial <- c("smell", "odor", "scent", "effluvium", "smelling", "sniff", "snuff",
                   "olfaction", "fragrance", "perfume", "stench")
taste_initial <- c("taste", "flavor", "savor", "savoring", "gustation", "taster", "tasting",
                   "aftertaste", "insipidity", "savoriness", "unsavoriness", "sweetness",
                   "sourness", "acidity")

# let's take out words that are absent from noun version of BILA.

nounsinbila <- read_csv(here("data", "biladataset", "bila_long_noun_lemmatized.csv")) %>%
  select(word) %>% distinct() %>% pull(word)

rain_second <- intersect(rain_initial, nounsinbila)
smell_second <- intersect(smell_initial, nounsinbila)
taste_second <- intersect(taste_initial, nounsinbila)

# the above lists were collected in a way that works for the count file in lemmatized version
# to make fair comparison, we'll add inflected forms as well as UK variant forms

features <- read_tsv(here("data", "forpreprocessing", "lemma_features.tsv")) %>%
  rename(word=original_word)

spelling <- read_csv(here("rawdata", "downloaded", "uk_us_spelling.csv")) %>%
  rename(word = US) %>%
  left_join(features, by = "word")

for (i in 1:nrow(features)) {
  if (features$word[i] %in% spelling$UK) {
    index <- which(spelling$UK == features$word[i])
    features$lemmatized_word[i] <- spelling$lemmatized_word[index]
  }
}

rain_add <- features %>%
  filter(lemmatized_word %in% rain_second,
         word != lemmatized_word) %>%
  pull(word)

rain_final <- c(rain_second, rain_add)

smell_add <- features %>%
  filter(lemmatized_word %in% smell_second,
         word != lemmatized_word) %>%
  pull(word)

smell_final <- c(smell_second, smell_add)

taste_add <- features %>%
  filter(lemmatized_word %in% taste_second,
         word != lemmatized_word) %>%
  pull(word)

taste_final <- c(taste_second, taste_add)

# undo comment to search strings for other groups
search_strings <- rain_final
#search_strings <- smell_final
#search_strings <- taste_final

# turn search strings into a regular expression

pattern <- paste("\\b(", paste(search_strings, collapse = "|"), ")\\b", sep = "")

# List PDF files in the folder
pdf_files <- list.files(path = pdf_folder, pattern = "\\.pdf$", full.names = TRUE)

# Function for searching in each pdf
process_pdf <- function(file_path) {
    outpref <- str_remove(basename(file_path), ".pdf")
    file_conn <- file(paste0(output_folder, "/", outpref, "_", search_strings[1], ".txt"), "w")

    pdf_text <- pdf_text(file_path)

    # Convert the text into a character vector
    pdf_lines <- unlist(strsplit(pdf_text, "\n"))

    # Search for PATTERN and print context surrounding each hit
    for (i in seq_along(pdf_lines)) {
      if (grepl(pattern, pdf_lines[i], ignore.case = TRUE)) {
        start_line <- max(1, i - 3)  # Get two lines before the hit (or from the beginning)
        end_line <- min(length(pdf_lines), i + 3)  # Get two lines after the hit (or until the end)
        context_lines <- pdf_lines[start_line:end_line]

        # Print the context lines
        cat("Line:", i, "\n", file = file_conn)
        cat(context_lines, sep = "\n", file = file_conn)
        cat("--------------\n", file = file_conn)
      }
    }
    close(file_conn)
}

# Apply the function to each PDF file
results <- lapply(pdf_files, process_pdf)

