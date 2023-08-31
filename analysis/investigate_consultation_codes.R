# Load packages
library(arrow)
library(here)
library(magrittr)
library(dplyr)
library(readr)
library(tidyr)

# Read arrow dataset and assign to df
df_20200401_to_20210331 <- arrow::read_feather(here::here("output", "consultation_dataset_2020-04-01_to_2021-03-31.arrow")) %>%
  dplyr::mutate(start_date = "2020-04-01",
                end_date = "2021-03-31")

count_clinical_codes <- df_20200401_to_20210331 %>%
  select(last_f2f_consultation_code, last_virtual_consultation_code) %>%
  pivot_longer(cols = c(last_f2f_consultation_code, last_virtual_consultation_code),
               names_to = "consultation_type",
               values_to = "snomedct_code") %>%
  group_by(consultation_type, snomedct_code) %>%
  count() %>%
  arrange(-n) %>%
  filter(n >= 7) %>%
  mutate(n = round(n, -1))

fs::dir_create(here::here("output", "data"))
write_csv(count_clinical_codes, here::here("output", "data", "summary_consultation_codes.csv"))
