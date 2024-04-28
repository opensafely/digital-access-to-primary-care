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

#Logistic regression without interaction
model1 <- glm(remote_rate ~ age_band + sex + imd_quintile + ethnicity + period,
              data = consultation_datasets, family=binomial(link="logit"), weights= count_appointment)
tidy1=cbind(exp(cbind(coef(model1), confint.default(model1))), summary(model1)$coefficients)  
tidy1 = as.data.frame(tidy1)
names(tidy1) = c('estimate','conf2.5%','conf97.5%', 'Estimate', 'Std. Error', 'z value', 'Pr(>|z|)')

#Interaction model
model2 <- glm(remote_rate ~ age_band + sex + imd_quintile + ethnicity + period + 
                age_band:period + sex:period + imd_quintile:period + ethnicity:period, 
              data = consultation_datasets, family=binomial(link="logit"), weights= count_appointment)
tidy2=cbind(exp(cbind(coef(model2), confint.default(model2))), summary(model2)$coefficients)  
tidy2 = as.data.frame(tidy2)
names(tidy2) = c('estimate','conf2.5%','conf97.5%', 'Estimate', 'Std. Error', 'z value', 'Pr(>|z|)')

#Combine tidy results into a single data frame
combined_models <- bind_rows(tidy1, tidy2)

# Write data
fs::dir_create(here::here("output", "results"))
write.csv(combined_models, here::here("output", "results", "logit_regression_result.csv"))