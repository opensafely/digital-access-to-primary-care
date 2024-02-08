# Load packages
library(here)
library(readr)
library(magrittr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(fs)

# Read csv summary dataset
df_measures <- read_csv(here("output", "measures", "consultation_measures.csv"))
unique(df_measures$sex)

df_measures <- df_measures %>%
  filter(!sex %in% c("unknown", "intersex"))

write_csv(df_measures, here("output", "measures", "tidy_consultation_measures.csv"))
