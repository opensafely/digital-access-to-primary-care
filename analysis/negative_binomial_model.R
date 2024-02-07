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

# Run a glm negative binomial regression model using count_virtual_consultation as outcome for 2019/20
model1 <- (glm.nb(count_virtual_consultation ~ age_band + sex + imd_quintile + ethnicity, data = consultation_datasets_filtered))
coef_table1 <- as.data.frame(exp(coef(model1)))
confint_table1 <- as.data.frame(exp(confint.default(model1)))
pvalues1 <- summary(model1)$coefficients[, "Pr(>|z|)"]
result_table1 <- cbind(coef_table1, confint_table1, pvalues1)
summary_text1 <- capture.output(print(result_table1))

# filter by start date to separate the data to financials years 2020/21
consultation_datasets_filtered <- consultation_datasets %>% filter(start_date == "2020-03-23")

# Run a glm negative binomial regression model using count_virtual_consultation as outcome for 2020/21
model2 <- (glm.nb(count_virtual_consultation ~ age_band + sex + imd_quintile + ethnicity, data = consultation_datasets_filtered))
coef_table2 <- as.data.frame(exp(coef(model2)))
confint_table2 <- as.data.frame(exp(confint.default(model2)))
pvalues2 <- summary(model2)$coefficients[, "Pr(>|z|)"]
result_table2 <- cbind(coef_table2, confint_table2, pvalues2)
summary_text2 <- capture.output(print(result_table2))

# filter by start date to separate the data to financials years 2021/22
consultation_datasets_filtered <- consultation_datasets %>% filter(start_date == "2021-03-23")

# Run a glm negative binomial regression model using count_virtual_consultation as outcome for 2021/22
model3 <- (glm.nb(count_virtual_consultation ~ age_band + sex + imd_quintile + ethnicity, data = consultation_datasets_filtered))
coef_table3 <- as.data.frame(exp(coef(model3)))
confint_table3 <- as.data.frame(exp(confint.default(model3)))
pvalues3 <- summary(model3)$coefficients[, "Pr(>|z|)"]
result_table3 <- cbind(coef_table3, confint_table3, pvalues3)
summary_text3 <- capture.output(print(result_table3))

# filter by start date to separate the data to financials years 2019/20
consultation_datasets_filtered <- consultation_datasets %>% filter(start_date == "2019-03-23")

# Run a glm negative binomial regression model using count_appointment as outcome for 2019/20
model4 <- (glm.nb(count_appointment ~ age_band + sex + imd_quintile + ethnicity, data = consultation_datasets_filtered))
coef_table4 <- as.data.frame(exp(coef(model4)))
confint_table4 <- as.data.frame(exp(confint.default(model4)))
pvalues4 <- summary(model4)$coefficients[, "Pr(>|z|)"]
result_table4 <- cbind(coef_table4, confint_table4, pvalues4)
summary_text4 <- capture.output(print(result_table4))

# filter by start date to separate the data to financials years 2020/21
consultation_datasets_filtered <- consultation_datasets %>% filter(start_date == "2020-03-23")

# Run a glm negative binomial regression model using count_appointment as outcome for 2020/21
model5 <- (glm.nb(count_appointment ~ age_band + sex + imd_quintile + ethnicity, data = consultation_datasets_filtered))
coef_table5 <- as.data.frame(exp(coef(model5)))
confint_table5 <- as.data.frame(exp(confint.default(model5)))
pvalues5 <- summary(model5)$coefficients[, "Pr(>|z|)"]
result_table5 <- cbind(coef_table5, confint_table5, pvalues5)
summary_text5 <- capture.output(print(result_table5))

# filter by start date to separate the data to financials years 2021/22
consultation_datasets_filtered <- consultation_datasets %>% filter(start_date == "2021-03-23")

# Run a glm negative binomial regression model using count_appointment as outcome for 2021/22
model6 <- (glm.nb(count_appointment ~ age_band + sex + imd_quintile + ethnicity, data = consultation_datasets_filtered))
coef_table6 <- as.data.frame(exp(coef(model6)))
confint_table6 <- as.data.frame(exp(confint.default(model6)))
pvalues6 <- summary(model6)$coefficients[, "Pr(>|z|)"]
result_table6 <- cbind(coef_table6, confint_table6, pvalues6)
summary_text6 <- capture.output(print(result_table6))

# Write data
fs::dir_create(here::here("output", "results"))
write_lines(c("start_date == '2019-03-23'", summary_text1), here("output", "results", "nb_regression.txt"))
write_lines(c("start_date == '2020-03-23'", summary_text2), here("output", "results", "nb_regression.txt"), append = TRUE)
write_lines(c("start_date == '2021-03-23'", summary_text3), here("output", "results", "nb_regression.txt"), append = TRUE)
write_lines(c("start_date == '2019-03-23'", summary_text4), here("output", "results", "nb_regression.txt"), append = TRUE)
write_lines(c("start_date == '2020-03-23'", summary_text5), here("output", "results", "nb_regression.txt"), append = TRUE)
write_lines(c("start_date == '2021-03-23'", summary_text6), here("output", "results", "nb_regression.txt"), append = TRUE)