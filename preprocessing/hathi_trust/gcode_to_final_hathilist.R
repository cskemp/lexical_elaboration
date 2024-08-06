library(here)
library(tidyverse)

gcodefile <- here("preprocessing", "hathi_trust", "02_with_gcodes_manual.csv")

d <-  read_csv(gcodefile) %>%
  mutate(delete = if_else( (!is.na(duplicate) & is.na(volume) & id != duplicate), 2, delete)) %>%
  filter(is.na(delete)) %>%
  write_csv(here("preprocessing", "hathi_trust", "02_with_gcodes.csv"))


d_id <- d %>%
  select(id) %>%
  write_csv(here("preprocessing", "hathi_trust", "02_hathi_ids.txt"), col_names = FALSE)

