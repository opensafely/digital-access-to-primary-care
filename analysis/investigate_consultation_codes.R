# Load packages
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

# Read file paths of all datasets
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


count_clinical_codes <- consultation_datasets %>%
  select(last_f2f_consultation_code, last_virtual_consultation_code) %>%
  pivot_longer(
    cols = c(last_f2f_consultation_code, last_virtual_consultation_code),
    names_to = "consultation_type",
    values_to = "snomedct_code"
  ) %>%
  group_by(consultation_type, snomedct_code) %>%
  count() %>%
  replace_na(list(snomedct_code = "(Missing)")) %>%
  mutate(consultation_type = str_extract(consultation_type, "f2f|virtual")) %>%
  arrange(consultation_type, -n) %>%
  filter(n >= 7) %>%
  mutate(n = round(n, -1))

dir_create(here("output", "data"))
write_csv(count_clinical_codes, here("output", "data", "summary_consultation_codes.csv"))
