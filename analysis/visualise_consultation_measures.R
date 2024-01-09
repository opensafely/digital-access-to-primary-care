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

measures_levels <- c("has_appointments_during2020_weekly_age", "has_virtual_during2020_weekly_age", "has_f2f_during2020_weekly_age", "count_appointments_during2020_weekly_age", "count_virtual_during2020_weekly_age", "count_f2f_during2020_weekly_age")
measures_labels <- c("Appointments table", "Virtual consultation codes", "f2f consultation codes", "Appointments table", "Virtual consultation codes", "f2f consultation codes")

age_levels <- c(FALSE, TRUE)
age_labels <- c("Age < 65", "Age >= 65")

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
    y = "Percentage of registered population aged >= 18 with one or more consultations",
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
    cols = vars(factor(age_greater_equal_65,
                       levels = age_levels,
                       labels = age_labels
    ))
  ) +
  scale_y_continuous(labels = scales::label_percent()) +
  scale_x_date(breaks = x_breaks, labels = scales::label_date_short())

ggsave(here("output", "figures", "plot_ratio_has_consultations.png"),
       plot = plot_ratio_has_consultations, width = 10, height = 10
)

# Plot numerator for "count_"
plot_numerator_count_consultations <- df_measures %>%
  filter(method == "count") %>%
  ggplot(aes(
    x = interval_end,
    y = numerator,
    group = factor(measure,
                   levels = measures_levels,
                   labels = measures_labels
    )
  )) +
  geom_point() +
  labs(
    x = NULL,
    y = "Total count of consultations for registered population aged >= 18",
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
    cols = vars(factor(age_greater_equal_65,
                       levels = age_levels,
                       labels = age_labels
    ))
  ) +
  scale_y_continuous(labels = scales::label_comma()) +
  scale_x_date(
    breaks = x_breaks,
    labels = scales::label_date_short()
  )

ggsave(here("output", "figures", "plot_numerator_count_consultations.png"),
       plot = plot_numerator_count_consultations, width = 10, height = 10
)
