# Script to generate GH love data

# Staff & Bots --------------------------------------------------------------------

bots <- c('ansibot', 'ansibullbot', 'patchback',
          'dependabot', 'modular-magician', 'pre-commit-ci')

exstaff <- c()

last_action <- function(df) {
  df |>
    distinct(author, createdAt) |>
    group_by(author) |>
    arrange(createdAt) |>
    slice_tail(n=1)
}

parse_data <- function(end = Sys.time(), raw_data, head = NA, threshold = NA) {
  # pre-process
  raw_data |>
    select(org, repo, number, type, author, comments, createdAt) -> df

  # Issues & PRs
  df |>
    filter(createdAt <= end) |>
    mutate(duration = interval(createdAt, end) %/% months(1),
           score = case_when(
             type == 'pull_request' ~ scores$pr * (scores$decay^duration),
             type == 'issue'        ~ scores$issue * (scores$decay^duration)
           )) |>
    add_count(author) |>
    count(author, n, wt = score, name = "total_score", sort = T) -> gh

  # Comments
  df |>
    unnest(comments) |> unnest(comments) |> # why twice?
    mutate(comment_time = map_chr(comments, "createdAt") |> ymd_hms(),
           comment_author = map(comments, 'author') %>%
             map_chr('login', .default = NA)) |>
    filter(comment_time <= end) -> comments_df

  comments_df |>
    mutate(duration = interval(comment_time, end) %/% months(1),
           score = case_when(
             type == 'pull_request' ~ scores$prcomment    * (scores$decay^duration),
             type == 'issue'        ~ scores$issuecomment * (scores$decay^duration)
           )) |>
    mutate(score = if_else(author == comment_author,
                           score * scores$selfcomment, score)) |>
    add_count(author) |>
    count(author, n, wt = score, name = "total_score", sort = T) -> comments

  # Hard cut-off data
  rbind(
    (df |> filter(createdAt <= end) |> last_action()), #issues/prs
    (comments_df |> last_action())                     #comments
  ) |> last_action() -> last_actions

  left_join(gh,comments,by='author') |>
    transmute(author,
              n = n.x + n.y,
              total_score = total_score.x + total_score.y) |>
    arrange(-total_score) |>
    filter(!is.na(author)) |>
    mutate(staff   = author %in% staff$`GitHub Login`,
           exstaff = author %in% exstaff,
           bot     = author %in% bots) |>
    filter(!staff) |>
    filter(!exstaff) |>
    filter(!bot) |>
    left_join(last_actions, by = 'author') |>
    filter(createdAt >= end - days(scores$timeout)) # createdAt => last-action
}

# test:
# parse_data(raw_data = raw_data)
tibble(index = 35:0) |>
  mutate(end = map_chr(index, ~{(as.Date(max(raw_data$createdAt)) - months(.x)) |> as.character() }) |> ymd(),
         data = map(end, parse_data, raw_data = raw_data)) -> gh_love
