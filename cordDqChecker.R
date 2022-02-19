# Kais Tahar
# Data quality analysis for CORD

rm(list = ls())
setwd("./")
source("./R/installPackages.R")
library(dqLib)
library(openxlsx)
library(stringi)
library(writexl)
########## data import #############
# import CORD med data
studycode = "FHIRtestData"
inpatientCases <- 1000
reportYear <-2020
max_FHIRbundles <- 50 # Inf
path="http://141.5.101.1:8080/fhir/"

# CSV and XLSX file formats are supported
#studycode = "dqTestData"
#path="./Data/medData/dqTestData.csv"
#path="./Data/medData/dqTestData.xlsx"

medData <- NULL
if (grepl("fhir", path))
{
  source("./R/dqFhirInterface.R")
  medData<- instData[ format(as.Date(instData$Entlassungsdatum, format="%Y-%m-%d"),"%Y")==reportYear, ]
}else{ ext <-getFileExtension (path)
if (ext=="csv") medData <- read.table(path, sep=";", dec=",",  header=T, na.strings=c("","NA"), encoding = "latin1")
if (ext=="xlsx") medData <- read.xlsx(path, sheet=1,skipEmptyRows = TRUE)
}
if (is.null (medData)) stop("Keine Daten vorhanden")

# import CORD and Ref. Data
refData1 <- read.table("./Data/refData/cordDqList.csv", sep=",",  dec=",", na.strings=c("","NA"), encoding = "UTF-8")
refData2 <- read.table("./Data/refData/icd10gm2020_alphaid_se_muster_edvtxt_20191004.txt", sep="|",  dec=",", na.strings=c("","NA"), encoding = "UTF-8")
headerRef1<- c ("IcdCode", "OrphaCode", "Type")
headerRef2<- c ("Gueltigkeit", "Alpha_ID", "ICD_Primaerkode1", "ICD_Manifestation", "ICD_Zusatz","ICD_Primaerkode2", "Orpha_Kode", "Label")
names(refData1)<-headerRef1
names(refData2)<-headerRef2
names(medData)
########## DQ Analysis #############a
cdata <- data.frame(
  basicItem=
    c ("PatientIdentifikator","Aufnahmenummer", "Institut_ID",  "Geschlecht","ICD_Primaerkode","Orpha_Kode","AlphaID_Kode", "Total")
)
ddata <- data.frame(
  basicItem=
    c ( "Geburtsdatum",  "Aufnahmedatum", "Entlassungsdatum", "Diagnosedatum", "Total")
)
tdata <- data.frame(
  pt_no =NA, case_no =NA
)

repCol=c( "PatientIdentifikator", "Aufnahmenummer", "ICD_Primaerkode","Orpha_Kode")
setGlobals(medData, repCol, cdata, ddata, tdata)
td <- NULL
if (!is.empty(medData$Institut_ID)){
  inst <- levels(as.factor(medData$Institut_ID))
  for (i in 1:length (inst)) {
    instID <- as.character (inst[i])
    dqInd= c("inst_id", "report_year", "outlier_rate", "orphaCoding_plausibility_rate", "missing_value_rate", "missing_item_rate", "orphaCoding_completeness_rate", "rdCase_uniqueness_rate", "unique_rdCase_relativeFrequency", "orphaCoding_relativeFrequency", "orphaCoding_no",  "unique_rdCase_no", "patient_no", "case_no", "inpatientCases_no")
    td <-checkCordDQ(instID, reportYear, inpatientCases, refData1, refData2, dqInd, "dq_msg", "basicItem", "Total")
  }
  ########## DQ-Report ###################
  path<- paste ("./Data/Export/Datenqualitätsreport_", studycode)
  getReport( repCol, "dq_msg", td, path)
  print(paste("DQ-Reports wurden im folgenden Ordner erstellt:", path))
}else{
  msg <- paste ("Institut_ID fehlt")
  stop(msg)
}
