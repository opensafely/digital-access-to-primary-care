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
df_measures <- read_csv(here("output", "measures", "consultation_measures.csv"), na = "(Redacted)") %>%
  mutate(method = ifelse(stringr::str_starts(measure, "count_"), "count", "has"))

# Set plot specifications
x_breaks <- seq(min(df_measures$interval_end), max(df_measures$interval_end), by = 7)
unique(df_measures$measure)

measures_levels <- c("has_appointments_during2020_weekly_age", "has_appointments_during2020_weekly_age_band", "has_virtual_during2020_weekly_age", "has_virtual_during2020_weekly_age_band", "count_appointments_during2020_weekly_age", "count_appointments_during2020_weekly_age_band", "count_virtual_during2020_weekly_age", "count_virtual_during2020_weekly_age_band")
measures_labels <- c("Appointments table by age", "Appointments table by age band", "Virtual consultation codes by age", "Virtual consultation codes by age_band", "Appointments table by age", "Appointments table by age band", "Virtual consultation codes by age", "Virtual consultation codes by age band")

#age_levels <- c(FALSE, TRUE)
#age_labels <- c("Age < 65", "Age >= 65")

# Plot ratio for "has_"
plot_ratio_has_consultations <- df_measures %>%
  filter(method == "has") %>%
  ggplot(aes(
    x = interval_end,
    y = ratio,
    group = factor(measure,
                   levels = measures_levels,
                   labels = measures_labels
    )
  )) +
  geom_point() +
  labs(
    x = NULL,
    y = "Percentage of seen appointment aged >= 18 with one or more consultations",
  ) +
  geom_line(
    size = .7,
    alpha = .4,
  ) +
  facet_grid(
    rows = vars(factor(measure,
                       levels = measures_levels,
                       labels = measures_labels
    )),
    scales = "free_y"
  ) +
  scale_y_continuous(labels = scales::label_percent()) +
  scale_x_date(breaks = x_breaks, labels = scales::label_date_short())

ggsave(here("output", "figures", "plot_ratio_has_consultations.png"),
       plot = plot_ratio_has_consultations, width = 10, height = 10
)

# Plot ratio for "count_"
plot_ratio_count_consultations <- df_measures %>%
  filter(method == "count") %>%
  ggplot(aes(
    x = interval_end,
    y = ratio,
    group = factor(measure,
                   levels = measures_levels,
                   labels = measures_labels
    )
  )) +
  geom_point() +
  labs(
    x = NULL,
    y = "Total count of consultations for seen appointments aged >= 18",
  ) +
  geom_line(
    size = .7,
    alpha = .4,
  ) +
  facet_grid(
    rows = vars(factor(measure,
                       levels = measures_levels,
                       labels = measures_labels
    )),
    scales = "free_y"
  ) +
  scale_y_continuous(labels = scales::label_comma()) +
  scale_x_date(
    breaks = x_breaks,
    labels = scales::label_date_short()
  )

ggsave(here("output", "figures", "plot_ratio_count_consultations.png"),
       plot = plot_ratio_count_consultations, width = 10, height = 10
)
