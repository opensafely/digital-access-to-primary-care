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

# Get all datasets
consultation_dataset_paths <- dir_ls(
  path = "output/",
  glob = "*consultation_dataset_*.arrow$"
)

# Define regex that extracts the date range from the filename
regex_get_dates <- "\\d{4}-\\d{2}-\\d{2}_to_\\d{4}-\\d{2}-\\d{2}"

# Load all datasets and read dates from file names
consultation_datasets <- consultation_dataset_paths %>%
  map(read_feather) %>%
  bind_rows(.id = "file_name") %>%
  mutate(file_name = str_extract(file_name, regex_get_dates)) %>%
  separate(file_name, c("start_date", "end_date"), sep = "_to_")

last_appointment_status <- consultation_datasets %>%
  select(last_appointment_status) %>%
  group_by(last_appointment_status) %>%
  count() %>%
  mutate(n = round(n, -1))

dir_create(here("output", "data"))
write_csv(last_appointment_status, here("output", "data", "summary_last_appointment_status.csv"))
