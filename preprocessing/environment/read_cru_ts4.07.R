library(tidyverse)
library(here)
library(ncdf4)
library(sf)
library(raster)
library(janitor)

# CRU 4.07 data for temperature and precipitation

select <- dplyr::select

decades <- c("1961.1970.", "1971.1980.", "1981.1990.")

cfile <- "../../rawdata/downloaded/cru_4.07/cru_ts4.07.1961.1970.pre.dat.nc"

# First set up data frame for gcodes
all_langs <- read_csv(here("data", "biladataset", "bila_dictionaries_full.csv"))  %>%
  select(glottocode, langname, longitude, latitude)  %>%
  unique()

gcodeloc_sf <- st_as_sf(all_langs, coords = c("longitude", "latitude"),
                    crs = 4326)

# Now define functions for reading CRU files

read_cru_decade <- function(varname, decade, gcodeloc_sf) {

  cfile <- paste0("../../rawdata/downloaded/cru_4.07/cru_ts4.07.", decade, varname, ".dat.nc")
  # to inspect variable names (and figure out which one to ask for in following line)
  #  ncd <- nc_open(cfile)

  cr_brick <- brick(cfile, varname = varname)
  cr_sf <- st_as_sf(raster::rasterToPoints(cr_brick, spatial=TRUE)) %>%
    clean_names() %>%
    rename_with(~str_remove(., 'x'), -c("geometry")) %>%
    rename_with(~str_remove(., '_16'), -c("geometry")) %>%
    rename_with(~str_remove(., '_15'), -c("geometry"))

  # nearest cru point to each gcode
  crf <- st_nearest_feature(gcodeloc_sf, cr_sf)
  distances <- st_distance(gcodeloc_sf, cr_sf[crf,], by_element=TRUE)

  gcodeloc_sf_nog <- gcodeloc_sf
  gcodeloc_sf_nog$cru_distance <- distances
  # remove geometry
  gcodeloc_sf_nog <- st_set_geometry(gcodeloc_sf_nog, NULL)

  d_cru <- bind_cols(gcodeloc_sf_nog, cr_sf[crf,]) %>%
    pivot_longer(cols = -c(glottocode,langname,cru_distance, geometry), names_to = "year_month", values_to = "value" ) %>%
    separate(year_month, c("year", "month"), convert=TRUE) %>%
    select(-geometry)
}

read_cru_var <- function(varname, decades, gcodeloc_sf) {
   c <- map_dfr(decades, ~ read_cru_decade(varname, .x, gcodeloc_sf) ) %>%
     group_by(glottocode, langname, cru_distance, month) %>%
     summarize(monthavg = mean(value)) %>%
     ungroup() %>%
     group_by(glottocode, langname, cru_distance) %>%
     summarize(maxmonth = max(monthavg), minmonth = min(monthavg), avgmonth = mean(monthavg))
}

cru_pre <- read_cru_var("pre", decades, gcodeloc_sf) %>%
  rename("avgmonth_pre"= avgmonth,  "minmonth_pre"=minmonth, "maxmonth_pre"=maxmonth)

cru_tmp <- read_cru_var("tmp", decades, gcodeloc_sf) %>%
  rename("avgmonth_tmp"= avgmonth,  "minmonth_tmp"=minmonth, "maxmonth_tmp"=maxmonth)


cru <- cru_pre %>%
  left_join(cru_tmp, by = c("glottocode", "langname", "cru_distance"))

all_langs_withdistance <- all_langs %>%
   left_join(cru, by = c("glottocode", "langname"))

print_vars <- all_langs_withdistance %>%
  select(glottocode, longitude, latitude, avgmonth_tmp, minmonth_tmp, maxmonth_tmp, avgmonth_pre, minmonth_pre, maxmonth_pre) %>%
  distinct() %>%
  write_csv(here("data", "foranalyses", "environment_tmp_pre.csv" ))
