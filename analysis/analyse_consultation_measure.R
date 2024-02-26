# Load packages
library(here)
library(readr)
library(magrittr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(fs)
library(broom)

# Read csv summary dataset
df_measures <- read_csv(here("output", "measures", "consultation_measures.csv"))

#drop some levels in the variables before the regression analyses
df_measures <- df_measures %>%
  subset(ethnicity != "missing" & imd_quintile != "Missing")

#transform variables into factors for the regression analyses
df_measures <- df_measures %>%
  mutate(
    period = case_when(
      grepl("^count_virtual_pre2019", measure) ~ "2019",
      grepl("^count_virtual_during2020", measure) ~ "2020",
      grepl("^count_virtual_during2021", measure) ~ "2021",
      TRUE ~ NA_character_  # Default case if none of the conditions are met
    ),
    ethnicity = factor(ethnicity, ordered = FALSE),
    sex = factor(sex, ordered = FALSE),
    imd_quintile = factor(imd_quintile, ordered = FALSE)
  )

# Convert the period variable to a factor with appropriate levels
df_measures$period <- factor(df_measures$period, levels = c("2019", "2020", "2021"))
df_measures$age_band <- factor(df_measures$age_band, levels = c("age_18_49", "age_50_64", "age_65_74", "age_75_84", "age_greater_equal_85"))

# Run a glm binomial regression model with logit link
model1 <- glm(ratio ~ age_band + sex + imd_quintile + ethnicity + period, data = df_measures, family=binomial(link="logit"), weights= denominator)
tidy1 <- tidy(model1, conf.int=TRUE, exponentiate = TRUE)
summary_text1 <- capture.output(print(tidy1, n = 30))
model2 <- glm(ratio ~ age_band + sex + imd_quintile + ethnicity + period + age_band:period, data = df_measures, family=binomial(link="logit"), weights= denominator)
tidy2 <- tidy(model2, conf.int=TRUE, exponentiate = TRUE)
summary_text2 <- capture.output(print(tidy2, n = 30))

# Write data
fs::dir_create(here::here("output", "results"))
write_lines(c("model without interaction'", summary_text1), here("output", "results", "consultation_model.txt"))
write_lines(c("model with interaction'", summary_text2), here("output", "results", "consultation_model.txt"), append = TRUE)
