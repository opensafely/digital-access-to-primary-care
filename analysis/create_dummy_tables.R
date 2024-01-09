# Load packages
library(arrow)
library(here)
library(magrittr)
library(dplyr)
library(readr)
library(tidyr)
library(stringr)
library(fs)
library(purrr)

# Load dummy data
clinical_events <- readr::read_csv(here::here("dummy_tables", "clinical_events.csv"), col_types=list(col_character(), col_character(), col_character()))
f2f_codes <- readr::read_csv(here::here("codelists", "user-KatieDavies_1234-generic-consultation.csv"), col_types=list(col_character()))
virtual_codes <- readr::read_csv(here::here("codelists", "user-KatieDavies_1234-virtual-consultation.csv"), col_types=list(col_character()))
consultation_codes <- c(f2f_codes$code, virtual_codes$code)

# Replace dummy data with data for selected time range and events
clinical_events <- clinical_events %>%
  mutate(date = sample(seq(as.Date("2020-02-01", format="%Y-%m-%d"), as.Date("2020-04-18", format="%Y-%m-%d"), by=1), nrow(clinical_events), replace = TRUE),
         snomedct_code = sample(consultation_codes, nrow(clinical_events), replace = TRUE))

# Write dummy data
readr::write_csv(clinical_events, here::here("dummy_tables", "clinical_events.csv"))
