calc_daumau <- function(end = Sys.Date(), df) {
  df |>
    mutate(day = as_datetime(cut(createdAt,'day'))) |>
    filter(day > end - days(30)) |>
    filter(day <= end) |>
    count(day, author) -> d

  d |> distinct(author) |> nrow() -> mau
  d |> filter(day == end) |> distinct(author) |> nrow() -> dau
  print(dau)
  print(mau)
  return(dau/mau)
}

calc_daumau <- function(end = Sys.Date(), df) {
  df |>
    mutate(day = as_datetime(cut(createdAt,'day'))) |>
    filter(day > end - days(30)) |>
    filter(day <= end) |>
    count(day, author) -> d

  d |> distinct(author) |> nrow() -> mau
  d |> filter(day == end) |> distinct(author) |> nrow() -> dau
  print(dau)
  print(mau)
  return(dau/mau)
}

raw_data |>
  unnest(comments) |> unnest(comments) |> # why twice?
  mutate(comment_time = map_chr(comments, "createdAt") |> ymd_hms(),
         comment_author = map(comments, 'author') %>%
           map_chr('login', .default = NA),
         type = glue::glue("{type}_comment")) -> comments_df


rbind(raw_data |> select(org, repo, type, number, author, createdAt),
      comments_df |> select(org, repo, type, number, author, createdAt = comment_time)
) |>
  arrange(createdAt) |>
  filter(createdAt > max(raw_data$createdAt - days(365))) -> df

df |>
  mutate(day = as_datetime(cut(createdAt,'day'))) |>
  group_by(day) |>
  distinct(author) |>
  nest(data = -day) |>
  mutate(n = map_int(data, nrow)) -> r

r |>
  ungroup() |>
  mutate(end = row_number(),
         start = end - 29) |>
  slice_tail(n=30) |>
  mutate(m = map2_int(start, end,
                      ~{r$data[.x:.y] |> unlist() |> unique() |> length() }),
         dm = n/m) -> dau_mau


## weekly / 2q

df |>
  mutate(week = as_datetime(cut(createdAt,'week'))) |>
  group_by(week) |>
  distinct(author) |>
  nest(data = -week) |>
  mutate(n = map_int(data, nrow)) -> r

r |>
  ungroup() |>
  mutate(end = row_number(),
         start = end - 26) |>
  slice_tail(n=27) |>
  slice_head(n=26) |>
  mutate(m = map2_int(start, end,
                      ~{r$data[.x:.y] |> unlist() |> unique() |> length() }),
         dm = n/m) -> wau_2qau

