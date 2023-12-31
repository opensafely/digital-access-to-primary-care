# Load packages
library(arrow)
library(here)
library(magrittr)
library(dplyr)
library(readr)
library(tidyr)
library(purrr)

# Read file paths of all datasets
consultation_dataset_paths <- fs::dir_ls(
  path = "output/",
  glob = "*consultation_dataset_*.arrow$"
)

# Define regex that extracts the date range from the filename
regex_get_dates <- "\\d{4}-\\d{2}-\\d{2}_to_\\d{4}-\\d{2}-\\d{2}"

# Load all datasets and read dates from file names
consultation_datasets <- consultation_dataset_paths %>%
  purrr::map(arrow::read_feather) %>%
  dplyr::bind_rows(.id = "file_name") %>%
  dplyr::mutate(file_name = stringr::str_extract(file_name, regex_get_dates)) %>%
  tidyr::separate(file_name, c("start_date", "end_date"), sep = "_to_")


#Count sum and has (yes/no) of consultations grouped by age group
#We could add more variables to group by here, e.g., ethnicity or sex
df_summary <- consultation_datasets %>%
  dplyr::group_by(start_date, end_date, age_greater_equal_65, sex, imd_quintile) %>%
  dplyr::summarise(
    n_has_appointment = sum(has_appointment, na.rm = TRUE),
    n_has_virtual = sum(has_virtual_consultation, na.rm = TRUE),
  ) %>%
  pivot_longer(
    cols = c(n_has_appointment, n_has_virtual),
    names_to = "summary_type",
    values_to = "value"
  )

# Apply disclosure controls
# Redact values lower or equal 7 and round all other values to nearest 10
df_summary <- df_summary %>%
  mutate(value = case_when(
    value <= 7 ~ NA_real_,
    TRUE ~ round(value, -1)
  ))

# Write data
# Convert all NAs to show "(Redacted)"
fs::dir_create(here::here("output", "data"))
write_csv(df_summary, here::here("output", "data", "summary_consultation_dataset.csv"), na = "(Redacted)")
