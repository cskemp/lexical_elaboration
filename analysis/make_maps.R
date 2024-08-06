# This R file makes maps of BILA languages.

library(tidyverse)
library(here)
library(xtable)
library(maps)
library(gridExtra)
library(patchwork)

# load master and count files

dict_path <- here("data", "biladataset", "bila_dictionaries.csv")
wordcount_path <- here("data", "biladataset", "bila_matrix_nounverbadj.csv")

dict <- read_csv(dict_path) %>%
  select(id, year, glottolog_langname, glottocode, area, langfamily, longitude, latitude, population, subsistence)

dictwithcount <- read_csv(wordcount_path) %>%
  select(id, ends_with("_data")) %>%
  mutate(length=all_token_count_data) %>%
  left_join(dict, by = "id")

langwithdict <- dictwithcount %>%
  group_by(glottocode) %>%
  summarize(ndicts = n(),
            mlen = mean(length)) %>%
  ungroup() %>%
  left_join(dict %>% select(-id, -year) %>% unique(), by = "glottocode")

# calculate the number of language that have one dictionary or more than 10 dictionaries
nlangs_one <- langwithdict %>%
  filter(ndicts == 1) %>%
  distinct(glottocode) %>%
  nrow()

nlangs_morethanthen <- langwithdict %>%
  filter(ndicts >= 10) %>%
  distinct(glottocode) %>%
  nrow()

# calculate the average dictionary size for those have one dictionary or mora than 10 dictionaries
avglen_one <- langwithdict %>%
  filter(ndicts == 1) %>%
  summarise(avglen = mean(mlen)) %>%
  pull(avglen)

avglen_morethanten <- langwithdict %>%
  filter(ndicts > 10) %>%
  left_join(dictwithcount, by="glottocode") %>%
  mutate(avglen=mean(length)) %>%
  select(avglen) %>% unique() %>%
  pull(avglen)

## create a map

world_map <- map_data("world")

dmap <- langwithdict %>%
  mutate(longitude = ifelse(area %in% c("North America", "South America"), longitude - 360, longitude),
  classndicts = case_when(
    ndicts == 1 ~ "1",
    ndicts >1 & ndicts <= 5 ~ "2-5",
    ndicts >5 & ndicts <= 10 ~ "5-10",
    ndicts > 10 ~ "more than 10"
  ),
  classmlen = case_when(
    mlen >= 5000 & mlen < 40000 ~ "5-40K",
    mlen >= 40000 & mlen < 100000 ~ "40-100K",
    mlen >= 100000 & mlen < 200000 ~ "100-200K",
    TRUE ~ "more than 200K"
  ))

# create a map for all languages in BILA by number of dictionaries
map_ndict <- ggplot() +
  geom_map(data = world_map, map = world_map,
           aes(long, lat, map_id = region),
           color = "white", fill = "gray90", size = 0.1) +
  coord_sf(xlim = c(-150, 180), ylim = c(-50, 80)) +
  geom_point(data = dmap, aes(longitude, latitude, color = classndicts), size = 1, shape = 16) +
  scale_color_manual(name = "number of dictionaries:",
                     values = c("1" = "#2673B4", "2-5" = "#319E72", "5-10" = "#EEE32C", "more than 10" = "#CD5D00")) +
  theme_void() +
  theme(legend.position = "bottom",
        legend.title = element_text(size = 10),
        legend.text = element_text(size = 10))
map_ndict

# create a map for all languages in BILA by average dictionary size

dmap$classmlen <- factor(dmap$classmlen, levels = c("5-40K", "40-100K", "100-200K", "more than 200K"))

map_mlen <- ggplot() +
  geom_map(data = world_map, map = world_map,
           aes(long, lat, map_id = region),
           color = "white", fill = "gray90", size = 0.1) +
  coord_sf(xlim = c(-150, 180), ylim = c(-50, 80)) +
  geom_point(data = dmap, aes(longitude, latitude, color = classmlen), size = 1, shape = 16) +
  scale_color_manual(name = "mean dictionary size:",
                     values = c("5-40K" = "#2673B4", "40-100K" = "#319E72", "100-200K" = "#EEE32C", "more than 200K" = "#CD5D00")) +
  theme_void() +
  theme(legend.position = "bottom",
        legend.title = element_text(size = 10),
        legend.text = element_text(size = 10))
map_mlen

# create a map for languages in robustness set
robustset <- readLines(here("data", "foranalyses", "robustness_set.txt"))

dmap_robust <- dmap %>%
  filter(glottocode %in% robustset)

map_ndict_robust <- ggplot() +
  geom_map(data = world_map, map = world_map,
           aes(long, lat, map_id = region),
           color = "white", fill = "gray90", size = 0.1) +
  coord_sf(xlim = c(-150, 180), ylim = c(-50, 80)) +
  geom_point(data = dmap_robust, aes(longitude, latitude, color = classndicts), size = 1, shape = 16) +
  scale_color_manual(name = "number of dictionaries:",
                     values = c("1" = "#2673B4", "2-5" = "#319E72", "5-10" = "#EEE32C", "more than 10" = "#CD5D00")) +
  theme_void() +
  theme(legend.position = "bottom",
        legend.title = element_text(size = 10),
        legend.text = element_text(size = 10))
map_ndict_robust

combined_plots <- map_ndict + map_mlen + map_ndict_robust +
  plot_layout(ncol = 1) + plot_annotation(tag_levels = 'a',  tag_suffix = ')')

ggsave(filename = here::here("output", "figures", "supplementary", "maps.pdf"), plot = combined_plots,
       device = "pdf", width = 7, height = 9)
