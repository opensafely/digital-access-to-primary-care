# Load packages
library(arrow)
library(here)
library(magrittr)
library(dplyr)
library(readr)
library(tidyr)

# Read arrow dataset and assign to df
df <- arrow::read_feather("output/consultation_dataset.arrow")

# Count number of consultations grouped by age group
# We could add more variables to group by here, e.g., ethnicity sex
df_summary <- df %>% 
  dplyr::group_by(patient_age_ge65) %>%
  dplyr::summarise(counttotal_f2f = sum(count_f2f_consultation, na.rm = TRUE),
                   counttotal_virtual = sum(count_virtual_consultation, na.rm = TRUE),
                   counthas_f2f = sum(has_f2f_consultation, na.rm = TRUE),
                   counthas_virtual = sum(has_virtual_consultation, na.rm = TRUE))

# Add start date and end date to the data
# This currently comes from the dataset definition and this will change once we extract more data
df_summary <- df_summary %>%
  dplyr::mutate(start_date = "2020-04-01",
                end_date = "2021-03-31")

# Pivot data longer so it is easier for further data manipulations or visualisations
df_summary <- df_summary %>%
  pivot_longer(cols = c(counttotal_f2f, counttotal_virtual, counthas_f2f, counthas_virtual),
               names_to = c("summary_type", "consultation_type"),
               values_to = "value", names_sep = "_")

# Write data
write_csv(df_summary, here::here("output/summary_consultation_dataset.csv"))
