FROM rocker/r-ver:latest
MAINTAINER kais.tahar@med.uni-goettingen.de

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
CMD Rscript cordDqChecker.R

