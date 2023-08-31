# Load packages
library(here)
library(readr)
library(magrittr)
library(dplyr)
library(ggplot2)
library(tidyr)

# Create output directory for figures
fs::dir_create(here::here("output", "figures"))

# Read csv summary dataset
df_summary <- readr::read_csv(here::here("output", "data", "summary_consultation_dataset.csv"))

# Create figure with sum of all consultations (this counts multiple consultations per patient)
plot_n_sum_consultation_by_age <- df_summary %>% 
  filter(summary_type == "n_sum") %>%
  ggplot(aes(x = start_date, y = value, fill = consultation_type)) +
    geom_bar(stat = "identity", position = position_dodge()) +
    labs(x = NULL, 
         y = "Count of all consultations",
         fill = "Type of consultation") +
    facet_wrap(~factor(age_greater_equal_65, 
                       levels = c(FALSE, TRUE), 
                       labels = c("Age > 18 and < 65", "Age >= 65")))

ggsave(here::here("output", "figures", "figure_n_sum_consultation_by_age.png"))

# Create figure with sum of all patients that had consultations
plot_n_has_consultation_by_age <- df_summary %>% 
  filter(summary_type == "n_has") %>%
  ggplot(aes(x = start_date, y = value, fill = consultation_type)) +
    geom_bar(stat = "identity", position = position_dodge()) +
    labs(x = NULL, 
         y = "Count of patients with consultations",
         fill = "Type of consultation") +
    facet_wrap(~factor(age_greater_equal_65, 
                       levels = c(FALSE, TRUE), 
                       labels = c("Age > 18 and < 65", "Age >= 65")))

ggsave(here::here("output", "figures", "figure_n_has_consultation_by_age.png"))
