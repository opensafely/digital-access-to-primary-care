# Load packages
library(arrow)
library(here)
library(magrittr)
library(dplyr)
library(readr)
library(tidyr)

# Read arrow dataset and assign to df
df_20200401_to_20210331 <- arrow::read_feather("output/consultation_dataset_2020-04-01_to_2021-03-31.arrow")

# Count sum and has (yes/no) of consultations grouped by age group
# We could add more variables to group by here, e.g., ethnicity or sex
df_summary <- df_20200401_to_20210331 %>% 
  dplyr::group_by(age_greater_equal_65) %>%
  dplyr::summarise(n_sum_f2f = sum(count_f2f_consultation, na.rm = TRUE),
                   n_sum_virtual = sum(count_virtual_consultation, na.rm = TRUE),
                   n_has_f2f = sum(has_f2f_consultation, na.rm = TRUE),
                   n_has_virtual = sum(has_virtual_consultation, na.rm = TRUE)) %>%
  dplyr::mutate(start_date = "2020-04-01",
                end_date = "2021-03-31")

# Pivot data longer so it is easier for further data manipulations or visualisations
df_summary <- df_summary %>%
  pivot_longer(cols = c(n_sum_f2f, n_sum_virtual, n_has_f2f, n_has_virtual),
               names_to = c("summary_type", "consultation_type"),
               values_to = "value", names_sep = "_(?=f2f|virtual)")

# Write data
write_csv(df_summary, here::here("output/summary_consultation_dataset.csv"))
