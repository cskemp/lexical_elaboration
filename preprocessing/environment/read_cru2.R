library(tidyverse)
library(here)
library(sf)
# this no longer on CRAN: install with renv::install("ropensci/getCRUCLdata")
library(getCRUCLdata)
library(raster)

# CRU 2 data for windspeed (this variable not included in CRU 4)
select <- dplyr::select

# First set up data frame for gcodes
all_langs <- read_csv(here("data", "biladataset", "bila_dictionaries_full.csv"))  %>%
  select(glottocode, langname, longitude, latitude)  %>%
  unique()

gcodeloc_sf <- st_as_sf(all_langs, coords = c("longitude", "latitude"),
                    crs = 4326)

# Now define functions for reading CRU files

cru_stack_list <- get_CRU_stack( wnd= TRUE)
cru_stack <- cru_stack_list$wnd

cr_sf <- st_as_sf(rasterToPoints(as(cru_stack, "Raster"), spatial=TRUE))

crf <- st_nearest_feature(gcodeloc_sf, cr_sf)

# nearest cru2 points for Mangareva, Gilbertese are 1500 km away

distances <- st_distance(gcodeloc_sf, cr_sf[crf,], by_element=TRUE)

gcodeloc_sf_nog <- gcodeloc_sf
gcodeloc_sf_nog$cru_distance <- distances
# remove geometry
gcodeloc_sf_nog <- st_set_geometry(gcodeloc_sf_nog, NULL)

d_cru <- bind_cols(gcodeloc_sf_nog, cr_sf[crf,]) %>%
    pivot_longer(cols = -c(glottocode,langname,cru_distance, geometry), names_to = "month", values_to = "value" ) %>%
    select(-geometry) %>%
    group_by(glottocode, langname, cru_distance) %>%
    summarize(maxmonth_wnd= max(value), minmonth_wnd = min(value), avgmonth_wnd = mean(value)) %>%
    ungroup()

all_langs_withdistance <- all_langs %>%
   left_join(d_cru, by = c("glottocode", "langname"))

print_vars <- all_langs_withdistance %>%
  select(glottocode, longitude, latitude, avgmonth_wnd, minmonth_wnd, maxmonth_wnd) %>%
  distinct() %>%
  write_csv(here("data", "foranalyses", "environment_wnd.csv" ))
