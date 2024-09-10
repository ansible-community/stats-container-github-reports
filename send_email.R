config <- config::get(file = '/srv/docker-config/github/email.yml')
date <- Sys.Date()

quarto::quarto_render(
  input = 'reports/_email.qmd',
  output_format = 'html'
)

setwd('reports')
msg <- emayili::envelope() |>
  emayili::from("gsutclif+ds@redhat.com") |>
  emayili::to(config$email_targets) |>
  emayili::subject(paste0("GitHub weekly reports - ", date)) |>
  emayili::html('_email.html')

smtp <- emayili::gmail(
  username = config$email_config$username,
  password = config$email_config$password
)

smtp(msg, verbose = TRUE)
