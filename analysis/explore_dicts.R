library(tidyverse)
library(dplyr)
library(here)
library(patchwork)
library(data.table)
library(ggplot2)
library(lemon)

ld <- read_csv(here("output/results", "hierarchical_lr_dict.csv"))
ll <- read_csv(here("output/results", "hierarchical_lr_lang.csv"))

unique(ld$convergence)
unique(ld$convergence_set)

dicts <- read_csv(here("data/biladataset", "bila_dictionaries.csv")) %>%
  select(id, glottocode) %>% unique() %>% rename(dict = id, lang = glottocode)

ld2 <- ld %>%
  select(word, dict, zeta) %>%
  rename(l_dict = zeta) %>%
  unique() %>%
  mutate(dict = sub("^dict", "", dict)) %>%
  left_join(dicts, by = "dict") %>%
  left_join(ll %>% select(word, zeta, lang) %>%
              rename(l_lang = zeta), by = c("word", "lang"))

# see if any NAs in lang column
check <- ld2 %>% filter(is.na(lang))

# identify languages with multiple dictionaries
multi <- dicts %>%
  group_by(lang) %>%
  summarise(n = n_distinct(dict)) %>%
  ungroup() %>%
  filter(n > 1) %>% select(lang) %>%
  unique() %>% pull()

ld3 <- ld2 %>%
  # choose languages with multiple dictionaries
  filter(lang %in% multi)

lang <- ld3 %>%
  select(word, lang, l_lang) %>%
  unique() %>%
  pivot_wider(names_from = lang, values_from = l_lang)


# first we compute correlation of every dictionary score with its corresponding language score and average them

calculate_avg_correlation <- function(ld3, lang_df) {

  lang_long <- lang_df %>%
    pivot_longer(-word, names_to = "lang", values_to = "l_lang")

  avg_correlations <- list()


  for (target_lang in colnames(lang_df)[-1]) {
    dict <- ld3 %>%
      filter(lang == target_lang) %>%
      select(word, dict, l_dict) %>%
      pivot_wider(names_from = dict, values_from = l_dict) %>%
      left_join(lang_df %>% select(word, all_of(target_lang)), by = "word")

    correlations <- dict %>%
      select(-word) %>%
      summarise(across(-all_of(target_lang), ~ cor(.data[[target_lang]], ., use = "pairwise.complete.obs")))

    avg_correlation <- correlations %>%
      pivot_longer(everything(), names_to = "variable", values_to = "correlation") %>%
      summarise(avg_correlation = mean(correlation, na.rm = TRUE)) %>%
      pull(avg_correlation)

    avg_correlations[[target_lang]] <- avg_correlation
  }

  result <- tibble(language = names(avg_correlations),
                   avg_correlation = unlist(avg_correlations))

  return(result)
}

average_correlations <- calculate_avg_correlation(ld3, lang)

avg_cor <- average_correlations %>%
  left_join(dicts %>%
              group_by(lang) %>%
              summarise(no_dicts = n_distinct(dict)) %>%
              ungroup() %>% rename(language=lang), by = "language")

mean(avg_cor$avg_correlation) #0.58
sd(avg_cor$avg_correlation) #0.16

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

# next we compute correlation of every dictionary score with all language scores

dict <- ld3 %>%
  select(word, dict, l_dict) %>%
  unique() %>%
  pivot_wider(names_from = dict, values_from = l_dict)

results_list <- list()

for (dictionary_name in colnames(dict)[-1]) {

  temp_results <- data.frame(lang = character(), corr = numeric(), rank = numeric(), stringsAsFactors = FALSE)

  for (language_name in colnames(lang)[-1]) {

    correlation_value <- cor(dict[[dictionary_name]], lang[[language_name]], use = "pairwise.complete.obs")

    temp_results <- rbind(temp_results, data.frame(
      lang = language_name,
      corr = correlation_value,
      stringsAsFactors = FALSE
    ))
  }

  temp_results$rank_f <- 1 - frank(-temp_results$corr, ties.method = "random") / max(frank(-temp_results$corr, ties.method = "random"))
  temp_results$rank <- rank(-temp_results$corr, ties.method = "min")

  temp_results$dict <- dictionary_name

  results_list[[dictionary_name]] <- temp_results
}

final_results <- do.call(rbind, results_list)

rank <- final_results %>%
  left_join(dicts %>% rename(langtrue = lang), by = "dict") %>%
  filter(lang == langtrue) %>%
  group_by(lang) %>%
  summarise(mean_rank = mean(rank),
            mean_rank_f = mean(rank_f),
            no_dicts = n_distinct(dict)) %>%
  ungroup()

mean(rank$mean_rank_f) #0.96
sd(rank$mean_rank_f) #0.05

# plot results

avg_cor <- avg_cor %>%
  mutate(dict_bin = factor(case_when(
    no_dicts == 2 ~ "2 dictionaries",
    no_dicts >= 3 & no_dicts <= 5 ~ "3-5 dictionaries",
    no_dicts >= 6 & no_dicts <= 10 ~ "6-10 dictionaries",
    no_dicts >= 11 ~ ">10 dictionaries"
  ), levels = c("2 dictionaries", "3-5 dictionaries", "6-10 dictionaries", ">10 dictionaries")))

rank <- rank %>%
  mutate(dict_bin = factor(case_when(
    no_dicts == 2 ~ "2 dictionaries",
    no_dicts >= 3 & no_dicts <= 5 ~ "3-5 dictionaries",
    no_dicts >= 6 & no_dicts <= 10 ~ "6-10 dictionaries",
    no_dicts >= 11 ~ ">10 dictionaries"
  ), levels = c("2 dictionaries", "3-5 dictionaries", "6-10 dictionaries", ">10 dictionaries")))


p1 <- ggplot(avg_cor, aes(x = dict_bin, y = avg_correlation)) +
  #geom_violin(trim = FALSE) +
  geom_violinhalf(flip = TRUE) +
  #geom_jitter(size = 0.5) +
  geom_dotplot(binaxis = "y", stackdir = "down", dotsize = 0.2, binwidth= 0.03)  +
  theme_classic() +
  theme_font +
  labs(x = "", y = expression("Average correlation of " * L^{lang} * " with its corresponding " * L[R]^{dict} * " scores"))

p2 <- ggplot(rank, aes(x = dict_bin, y = mean_rank_f)) +
  #geom_violin(trim = FALSE) +
  geom_violinhalf(flip = TRUE) +
  #geom_jitter(size = 0.5) +
  geom_dotplot(binaxis = "y", stackdir = "down", dotsize = 0.15, binwidth= 0.02)  +
  theme_classic() +
  theme_font + ylim(0.4,1) +
  geom_hline(yintercept = 0.5, linetype = "dashed", size = 0.5, color = "gray") +
  labs(x = "", y = expression("Average rank based on correlations of " * L[R]^{dict} * " with all " * L^{lang} * " scores"))

combined <- p1 + p2 + plot_annotation(tag_levels = 'a',  tag_suffix = ')')
ggsave(here("output/figures/supplementary/multidict.pdf"), combined, width = 12, height = 5)
