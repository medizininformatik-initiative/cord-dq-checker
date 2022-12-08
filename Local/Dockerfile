# Dockerfile for local execution
FROM rocker/r-ver:latest
LABEL Maintainer="kais.tahar@med.uni-goettingen.de" 
LABEL Description="CORD Data Quality Checker"
WORKDIR /usr/local/src/myScripts

# install packages
RUN apt-get update -qq && apt-get install -y libxml2-dev libcurl4-openssl-dev libssl-dev
#RUN R -e "install.packages('devtools')"
#Run R -e "devtools::install_github('https://github.com/medizininformatik-initiative/dqLib')"
RUN R -e "install.packages('fhircrackr')"
RUN R -e "install.packages('openxlsx')"
RUN R -e "install.packages('stringi')"
RUN R -e "install.packages('config')"

# copy files
COPY . .

# run R script
CMD Rscript cordDqChecker.R

