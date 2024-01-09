# Load packages
library(arrow)
library(here)
library(magrittr)
library(dplyr)
library(readr)
library(tidyr)
library(purrr)

# Read file paths of all datasets
consultation_dataset_paths <- fs::dir_ls(path = "output/", glob = "*consultation_dataset_*.arrow$")

# Define regex that extracts the date range from the filename
regex_get_dates <- "\\d{4}-\\d{2}-\\d{2}_to_\\d{4}-\\d{2}-\\d{2}"

# Load all datasets and read dates from file names
consultation_datasets <- consultation_dataset_paths %>%
  purrr::map(arrow::read_feather) %>%
  dplyr::bind_rows(.id = "file_name") %>%
  dplyr::mutate(file_name = stringr::str_extract(file_name, regex_get_dates)) %>%
  tidyr::separate(file_name, c("start_date", "end_date"), sep = "_to_")

# filter by start date to separate the data to financials years 2019/20
consultation_datasets_filtered <- consultation_datasets %>% filter(start_date == "2019-04-01")

# Run a generalised linear model with binary outcome using has_virtual_consultation as outcome
summary_text1 <- capture.output(summary(glm(has_virtual_consultation ~ age_greater_equal_65 + sex + imd_quintile + ethnicity, data = consultation_datasets_filtered, family = "binomial")))

# filter by start date to separate the data to financials years 2020/21
consultation_datasets_filtered <- consultation_datasets %>% filter(start_date == "2020-04-01")

# Run a generalised linear model with binary outcome using has_virtual_consultation as outcome
summary_text2 <- capture.output(summary(glm(has_virtual_consultation ~ age_greater_equal_65 + sex + imd_quintile + ethnicity, data = consultation_datasets_filtered, family = "binomial")))

# filter by start date to separate the data to financials years 2021/22
consultation_datasets_filtered <- consultation_datasets %>% filter(start_date == "2021-04-01")

# Run a generalised linear model with binary outcome using has_virtual_consultation as outcome
summary_text3 <- capture.output(summary(glm(has_virtual_consultation ~ age_greater_equal_65 + sex + imd_quintile + ethnicity, data = consultation_datasets_filtered, family = "binomial")))

# Write data
fs::dir_create(here::here("output", "results"))
write_lines(c("start_date == '2019-04-01'", summary_text1), here("output", "results", "binary_regression.txt"))
write_lines(c("start_date == '2020-04-01'", summary_text2), here("output", "results", "binary_regression.txt"), append = TRUE)
write_lines(c("start_date == '2021-04-01'", summary_text3), here("output", "results", "binary_regression.txt"), append = TRUE)