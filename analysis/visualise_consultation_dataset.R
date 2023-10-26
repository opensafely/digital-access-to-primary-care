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
df_summary <- read_csv(here("output", "data", "summary_consultation_dataset.csv"),
  na = "(Redacted)",
  col_types = list(value = "i")
)

# Create figure with sum of all consultations (this counts multiple consultations per patient)
plot_n_sum_consultation_by_age <- df_summary %>%
  filter(summary_type == "n_count") %>%
  ggplot(aes(x = start_date, y = value, fill = consultation_type)) +
  geom_bar(stat = "identity", position = position_dodge()) +
  labs(
    x = NULL,
    y = "Count of all consultations",
    fill = "Type of consultation"
  ) +
  facet_wrap(~ factor(age_greater_equal_65,
    levels = c(FALSE, TRUE),
    labels = c("Age > 18 and < 65", "Age >= 65")
  ))

ggsave(here("output", "figures", "figure_n_sum_consultation_by_age.png"))

# Create figure with sum of all patients that had consultations
plot_n_has_consultation_by_age <- df_summary %>%
  filter(summary_type == "n_has") %>%
  ggplot(aes(x = start_date, y = value, fill = consultation_type)) +
  geom_bar(stat = "identity", position = position_dodge()) +
  labs(
    x = NULL,
    y = "Count of patients with consultations",
    fill = "Type of consultation"
  ) +
  scale_x_date(
      labels = scales::label_date_short()
    ) +
  scale_y_continuous(
    labels = scales::label_comma()
    ) +
  facet_wrap(~ factor(age_greater_equal_65,
    levels = c(FALSE, TRUE),
    labels = c("Age > 18 and < 65", "Age >= 65")
  ))

ggsave(here("output", "figures", "figure_n_has_consultation_by_age.png"))
