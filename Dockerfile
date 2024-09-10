FROM rocker/tidyverse:latest

RUN install2.r config emayili pins ggrepel patchwork \
               janitor tidyquant survminer quarto \
    && rm -rf /tmp/downloaded_packages

RUN mkdir -p /opt/ghreports

WORKDIR /opt/ghreports
COPY ./_quarto.yml .
COPY ./index.qmd .
COPY ./about.qmd .

COPY ./scripts scripts
COPY ./reports reports
COPY ./files files

COPY ./make-site.sh .
COPY ./send_email.R .

CMD ["/bin/bash"]
