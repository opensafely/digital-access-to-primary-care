# Load packages
library(here)
library(readr)
library(magrittr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(fs)

# Create output directory for figures
dir_create(here("output", "figures"))

# Read csv summary dataset
df_summary <- read_csv(here("output", "measures", "consultation_measures.csv"),
  na = "(Redacted)"
)

# Create figure with consultation measure pre2019 (this plots the ratio of virtual consultation using appointments as denominator)
plot_consultation_measure_age <- df_summary %>%
  filter(measure == "virtual_pre2019_weekly_age") %>%
  ggplot(aes(x = "interval_start", y = "ratio")) +
  geom_line() +
  labs(
    x = "Changes in virtual consultation from 2019 to 2020",
    y = "Ratio of virtual consultation to appointments",
  ) +
  facet_wrap(~age_greater_equal_65)

# Create figure with consultation measure during2020 (this plots the ratio of virtual consultation using appointments as denominator)
plot_consultation_measure_age <- df_summary %>%
  filter(measure == "virtual_during2020_weekly_age") %>%
  ggplot(aes(x = "interval_start", y = "ratio")) +
  geom_line() +
  labs(
    x = "Changes in virtual consultation from 2019 to 2020",
    y = "Ratio of virtual consultation to appointments",
  ) +
  facet_wrap(~age_greater_equal_65)

# Create figure with consultation measure during2021 (this plots the ratio of virtual consultation using appointments as denominator)
plot_consultation_measure_age <- df_summary %>%
  filter(measure == "virtual_during2021_weekly_age") %>%
  ggplot(aes(x = "interval_start", y = "ratio")) +
  geom_line() +
  labs(
    x = "Changes in virtual consultation from 2019 to 2020",
    y = "Ratio of virtual consultation to appointments",
  ) +
  facet_wrap(~age_greater_equal_65)

# # Create figure with sum of all consultations (this counts multiple consultations per patient)
# plot_n_sum_consultation_by_age <- df_summary %>%
#   filter(summary_type == "n_count") %>%
#   ggplot(aes(x = start_date, y = value, fill = consultation_type)) +
#   geom_bar(stat = "identity", position = position_dodge()) +
#   labs(
#     x = NULL,
#     y = "Count of all consultations",
#     fill = "Type of consultation"
#   )

# ggsave(here("output", "figures", "figure_n_sum_consultation_by_age.png"))

# # Create figure with sum of all patients that had consultations
# plot_n_has_consultation_by_age <- df_summary %>%
#   filter(summary_type == "n_has") %>%
#   ggplot(aes(x = start_date, y = value, fill = consultation_type)) +
#   geom_bar(stat = "identity", position = position_dodge()) +
#   labs(
#     x = NULL,
#     y = "Count of patients with consultations",
#     fill = "Type of consultation"
#   ) +
#   scale_x_date(
#       labels = scales::label_date_short()
#     ) +
#   scale_y_continuous(
#     labels = scales::label_comma()
#     )

ggsave(here("output", "figures", "figure_pre2019_consultation_measure_by_age.png"))
