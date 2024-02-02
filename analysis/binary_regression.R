# Load packages
library(arrow)
library(here)
library(magrittr)
library(dplyr)
library(readr)
library(tidyr)
library(purrr)
library(MASS)

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

#transform variables into factors for the regression analyses
consultation_datasets <- consultation_datasets %>%
  mutate(
    ethnicity = factor(ethnicity, ordered = FALSE),
    sex = factor(sex, ordered = FALSE),
    imd_quintile = factor(imd_quintile, ordered = FALSE)
  )

#create age_band for the regression analysis
consultation_datasets <- consultation_datasets %>%
  mutate(
    age_band = cut(age,
                   breaks = c(18, 50, 65, 75, 85, Inf),
                   labels = c("18-49", "50-64", "65-74", "75-84", "85+"),
                   include.lowest = TRUE)
  )


#drop some levels in the variables before the regression analyses
consultation_datasets <- consultation_datasets %>%
  subset(ethnicity != "missing" & imd_quintile != "Missing" & !(sex %in% c("intersex", "unknown")))


# filter by start date to separate the data to financials years 2019/20
consultation_datasets_filtered <- consultation_datasets %>% filter(start_date == "2019-03-23")

# Run a generalised linear model with binary outcome using has_virtual_consultation as outcome
summary_text1 <- capture.output(summary(glm.nb(count_virtual_consultation ~ age_band + sex + imd_quintile + ethnicity, data = consultation_datasets_filtered)))

# filter by start date to separate the data to financials years 2020/21
consultation_datasets_filtered <- consultation_datasets %>% filter(start_date == "2020-03-23")

# Run a generalised linear model with binary outcome using has_virtual_consultation as outcome
summary_text2 <- capture.output(summary(glm.nb(count_virtual_consultation ~ age_band + sex + imd_quintile + ethnicity, data = consultation_datasets_filtered)))

# filter by start date to separate the data to financials years 2021/22
consultation_datasets_filtered <- consultation_datasets %>% filter(start_date == "2021-03-23")

# Run a generalised linear model with binary outcome using has_virtual_consultation as outcome
summary_text3 <- capture.output(summary(glm.nb(count_virtual_consultation ~ age_band + sex + imd_quintile + ethnicity, data = consultation_datasets_filtered)))

# Write data
fs::dir_create(here::here("output", "results"))
write_lines(c("start_date == '2019-03-23'", summary_text1), here("output", "results", "binary_regression.txt"))
write_lines(c("start_date == '2020-03-23'", summary_text2), here("output", "results", "binary_regression.txt"), append = TRUE)
write_lines(c("start_date == '2021-03-23'", summary_text3), here("output", "results", "binary_regression.txt"), append = TRUE)