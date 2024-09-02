library(tidyverse)
library(janitor)
library(tidyquant)
library(patchwork)
library(survival)
library(survminer)

end_date = max(raw_data$createdAt)

raw_data |>
  mutate(closedAt = ymd_hms(closedAt),
         mergedAt = ymd_hms(mergedAt)) |>
  filter(mergedAt > end_date - months(6) |
           closedAt > end_date - months(6) |
           is.na(closedAt) ) |>
  mutate(state = as.integer(!is.na(closedAt)),
         status = case_when(
           is.na(closedAt) ~ "OPEN",
           is.na(mergedAt) ~ "CLOSED",
           TRUE ~ "MERGED"
         )) |>
  mutate(time = case_when(
    status == "OPEN" ~ (end_date - createdAt),
    status == "CLOSED" ~ closedAt - createdAt,
    status == "MERGED" ~ mergedAt - createdAt
  )) |>
  mutate(staff   = author %in% staff$`GitHub Login` | author %in% exstaff,
         bot     = author %in% bots) |>
  filter(!bot) |>
  mutate(time = map_dbl(time, ~{.x/60/60/24})) -> surv_gh

