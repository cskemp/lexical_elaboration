# This R file produces results of L^lang scores used for the app.

library(tidyverse)
library(glmmTMB)
library(here)
library(furrr)
library(broom.mixed)

# Run this in a stand-alone console, not RStudio (because RStudio doesn't support future_map() )

source("bind_weights_par.R")

d_wide <- read_csv(here("data", "foranalyses", "d_wide.csv"))

# Compute L^lang score

weights_lr <-  bind_weights_par(d_wide) %>%
  write_csv(here("output", "results", "hierarchical_lr_lang.csv"))

# Compute L^dict score

weights_dict <-  bind_weights_dict(d_wide) %>%
  write_csv(here("output", "results", "hierarchical_lr_dict.csv"))
