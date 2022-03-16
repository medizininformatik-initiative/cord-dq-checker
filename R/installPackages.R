
# install R package
if(!require('devtools')) install.packages('devtools')
library(devtools)
install_github("https://github.com/KaisTahar/dqLib")
#if(!require('fhircrackr')) install_github("POLAR-fhiR/fhircrackr")
if(!require('fhircrackr')) install.packages('fhircrackr')
if(!require('openxlsx')) install.packages('openxlsx')
