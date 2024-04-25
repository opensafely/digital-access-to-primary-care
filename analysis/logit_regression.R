# Load packages
library(arrow)
library(here)
library(magrittr)
library(dplyr)
library(readr)
library(tidyr)
library(purrr)
library(MASS)
library(broom)

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
    period = case_when(
    start_date == "2019-03-23" ~ "2019",
    start_date == "2020-03-23" ~ "2020",
    start_date == "2021-03-23" ~ "2021",
    TRUE ~ NA_character_  # If none of the conditions match, assign NA
    ),
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

# create a new variable with consultation No= 0 or Yes=1
consultation_datasets$remote <- ifelse(consultation_datasets$count_virtual_consultation > 0, 1, 0)

# create a new variable representing the ratio of virtual consultation and appointment
consultation_datasets <- consultation_datasets %>%
  mutate(remote_rate = remote / count_appointment)

#Binomial logit models with/without interactions
model1 <- glm(remote_rate ~ age_band + sex + imd_quintile + ethnicity + period, data = consultation_datasets, family=binomial(link="logit"), weights= count_appointment)
tidy1 <- tidy(model1, conf.int=TRUE, exponentiate = TRUE)

model2 <- glm(remote_rate ~ age_band + sex + imd_quintile + ethnicity + period + age_band*period, data = consultation_datasets, family=binomial(link="logit"), weights= count_appointment)
tidy2 <- tidy(model2, conf.int=TRUE, exponentiate = TRUE)

model3 <- glm(remote_rate ~ age_band + sex + imd_quintile + ethnicity + period + sex*period, data = consultation_datasets, family=binomial(link="logit"), weights= count_appointment)
tidy3 <- tidy(model3, conf.int=TRUE, exponentiate = TRUE)

model4 <- glm(remote_rate ~ age_band + sex + imd_quintile + ethnicity + period + imd_quintile*period, data = consultation_datasets, family=binomial(link="logit"), weights= count_appointment)
tidy4 <- tidy(model4, conf.int=TRUE, exponentiate = TRUE)

model5 <- glm(remote_rate ~ age_band + sex + imd_quintile + ethnicity + period + ethnicity*period, data = consultation_datasets, family=binomial(link="logit"), weights= count_appointment)
tidy5 <- tidy(model5, conf.int=TRUE, exponentiate = TRUE)

# Combine tidy results into a single data frame
combined_tidy <- bind_rows(tidy1, tidy2, tidy3, tidy4, tidy5)

# Write data
fs::dir_create(here::here("output", "results"))
write.csv(combined_tidy, here::here("output", "results", "combined_regression_result.csv"))