# Dockerfile for distributed execution using PHT
FROM rocker/r-ver:latest
MAINTAINER kais.tahar@med.uni-goettingen.de

# Label
LABEL envs="[{\"name\":\"FHIR_SERVER\",\"type\":\"string\",\"required\":true},{\"name\":\"INPATIENT_CASE_NO\",\"type\":\"string\",\"required\":true}]"

WORKDIR /usr/local/src/myScripts

# copy files
COPY . .

# install packages
RUN apt-get update -qq && apt-get install -y libxml2-dev libcurl4-openssl-dev libssl-dev
RUN R -e "install.packages('devtools')"
RUN R -e "install.packages('fhircrackr')"
RUN R -e "install.packages('openxlsx')"
Run R -e "devtools::install_github('https://github.com/KaisTahar/dqLib')"

# run R script
WORKDIR ./PHT
RUN pwd && ls
CMD Rscript ./cordDqChecker_PHT.R

