## Docker Container for GitHub Reports

This container handles the generation of [Ansible GitHub report site](https://connect.eng.ansible.com/github), based on the pins generated from [the pins container](https://github.com/ansible-community/stats-container-github)

## Setup

This container requires three mount points:
- a `config` dir mounted to `/srv/docker-config/github` for the tokens, lists, and email config
- a `pins` dir mounted to `/srv/docker-pins/github` for storing/reading data (this can be ReadOnly as the data comes from the other container)
- a `site` dir mounted to `/opt/ghreports/github` for the rendered site output

### Example dir layout

Inside the container it should look like this:
```
/srv/docker-config
└── github
    ├── email.yml
    ├── scores.yml
    └── staff-list.csv
/srv/docker-pins
└── github
/opt/ghreports
└── github
```

## Config

You can look at the examples in this repo for details

You'll need:
- A `email.yml` to send the email report
- A `scores.yml` to assign weights
- A `staff-list.csv` which contains a `GitHub Login` column

## Build the container

```
podman build --tag github-reports .
```

## Run the container

### Default

The default action will give you a shell:

```
podman run --rm -ti \
  -v /srv/docker-config/github/:/srv/docker-config/github \
  -v /srv/docker-pins/github:/srv/docker-pins/github \
  -v /srv/docker-reports/github:/opt/ghreports/github \
  github-reports:latest 
```

### Generate report site

The site is built using [Quarto](https://quarto.org):

```
podman run --rm -ti \
  -v /srv/docker-config/github/:/srv/docker-config/github \
  -v /srv/docker-pins/github:/srv/docker-pins/github \
  -v /srv/docker-reports/github:/opt/ghreports/output \
  github-reports:latest \
  ./make-site.sh
```

This will output the rendered site to the mounted `output` directory.

### Send summary email

This depends on the site being generated as above - it merely grabs the
`All_top20.png` from the site and sends it with a short summary.

Note the mount point for the 3rd folder is `github` not `output` this time - the existing site needs to be mounted in place

```
podman run --rm -ti \
  -v /srv/docker-config/github/:/srv/docker-config/github \
  -v /srv/docker-pins/github:/srv/docker-pins/github \
  -v /srv/docker-reports/github:/opt/ghreports/github \
  github-reports:latest \
  Rscript ./send_email.R
```

This depends on the email.yml config as above.
