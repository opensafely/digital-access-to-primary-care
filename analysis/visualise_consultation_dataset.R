# Load packages
library(here)
library(readr)
library(magrittr)
library(dplyr)
library(ggplot2)
library(tidyr)

# Read csv summary dataset
df_summary <- readr::read_csv("output/summary_consultation_dataset.csv")

df_summary %>%
  group_by(consultation_type) %>%
  summarise()

consultation_plot <- ggplot(df_summary, aes(start_date, value, colour = consultation_type)) +
  geom_point() +
  labs(x = NULL, y = "Count of all consultations", colour = "Type of consultation") +
  facet_wrap(~factor(patient_age_ge65, levels = c(TRUE, FALSE), labels = c("Age > 18 and < 65", "Age >= 65")))

ggsave("output/figure_consultation_type_by_age_group.png")
