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


# transform data
consultation_datasets$period <- ifelse(consultation_datasets$start_date == "2019-03-23", "2019",
                              ifelse(consultation_datasets$start_date == "2020-03-23", "2020",
                                     ifelse(consultation_datasets$start_date == "2021-03-23", "2021", NA)))

consultation_datasets$period<- factor(consultation_datasets$period, levels = c("2019", "2020", "2021"))

# Define age bands
age_breaks <- c(18, 50, 65, 75, 85, Inf)
age_labels <- c("18-49", "50-64", "65-74", "75-84", "85+")

#Create age_band variable
consultation_datasets$age_band <- cut(consultation_datasets$age, breaks = age_breaks, labels = age_labels, include.lowest = TRUE)

#Create an empty data frame to store the combined results
combined_results <- data.frame()

#Iterate over each period
for (period in c('2019', '2020', '2021')) {
# Subset the data for the current period
period_data <- consultation_datasets[consultation_datasets$period == period, ]
  
# Group remote consultation and appointment by age
age_remote <- aggregate(count_virtual_consultation ~ age_band, data = period_data, FUN = sum)
age_appt <- aggregate(count_appointment ~ age_band, data = period_data, FUN = sum)
  
#Group remote consultation and appointment by sex
sex_remote <- aggregate(count_virtual_consultation ~ sex, data = period_data, FUN = sum)
sex_appt <- aggregate(count_appointment ~ sex, data = period_data, FUN = sum)
  
# Group remote consultation and appointment by ethnicity
ethnicity_remote <- aggregate(count_virtual_consultation ~ ethnicity, data = period_data, FUN = sum)
ethnicity_appt <- aggregate(count_appointment ~ ethnicity, data = period_data, FUN = sum)
  
# Group remote consultation and appointment by IMD
imd_remote <- aggregate(count_virtual_consultation ~ imd_quintile, data = period_data, FUN = sum)
imd_appt <- aggregate(count_appointment ~ imd_quintile, data = period_data, FUN = sum)
  
# Combine all outputs into a single table
age_counts <- bind_cols(age_remote, count_appointment = age_appt$count_appointment)
sex_counts <- bind_cols(sex_remote, count_appointment = sex_appt$count_appointment)
ethnicity_counts <- bind_cols(ethnicity_remote, count_appointment = ethnicity_appt$count_appointment)
imd_counts <- bind_cols(imd_remote, count_appointment = imd_appt$count_appointment)
  
# Add a column for the period
age_counts$period <- period
sex_counts$period <- period
ethnicity_counts$period <- period
imd_counts$period <- period
  
# Append results to the combined data frame
combined_results <- bind_rows(combined_results, age_counts, sex_counts, ethnicity_counts, imd_counts)
}

# Redact values less than 7
combined_results <- combined_results %>%
  mutate(count_virtual_consultation = ifelse(count_virtual_consultation <= 7, NA, count_virtual_consultation),
         count_appointment = ifelse(count_appointment <= 7, NA, count_appointment))

# Save the combined table to a file
fs::dir_create(here::here("output", "data"))
write.csv(combined_results, here::here("output", "data", "summary_consultation_datasets.csv"), na = "(Redacted)")
