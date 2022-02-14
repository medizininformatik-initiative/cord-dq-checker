# Kais Tahar
# Data quality analysis for CORD

library(dqLib)
library(openxlsx)

# install R package
setwd("./")
rm(list = ls())
library(devtools)
install_github("https://github.com/KaisTahar/dqLib")
library(stringi)
library(writexl)

########## data import #############
# import CORD med data
studycode = "FHIR_TestData"
path="http://141.5.101.1:8080/fhir/"

# CSV and XLSX file formats are supported
#studycode = "dqTestData"
#path="./Data/medData/dqTestData_KT.csv"
#path="./Data/medData/dqTestData_KT.xlsx"

medData <- NULL
if (grepl("fhir", path))
{
  #source("./R/dqFhirInterface.R")
  source("./R/dqFhirInterface_v2.R")
  year <-2020
  medData<- instData[ format(as.Date(instData$Entlassungsdatum, format="%Y-%m-%d"),"%Y")==year, ]
}else{ ext <-getFileExtension (path)
      if (ext=="csv") medData <- read.table(path, sep=";", dec=",",  header=T, na.strings=c("","NA"), encoding = "latin1")
      if (ext=="xlsx") medData <- read.xlsx(path, sheet=1,skipEmptyRows = TRUE)
}
if (is.null (medData)) stop("Keine Daten vorhanden")
inpatientCases <- 202
# import CORD Ref. Data
refData1 <- read.table("./Data/refData/cordDqList.csv", sep=",",  dec=",", na.strings=c("","NA"), encoding = "UTF-8")
refData2 <- read.table("./Data/refData/icd10gm2020_alphaid_se_muster_edvtxt_20191004.txt", sep="|",  dec=",", na.strings=c("","NA"), encoding = "UTF-8")
names(medData)
mdHeader <- c ("Institut_ID","PatientIdentifikator","Aufnahmenummer","Diagnosetext","ICD_Text","ICD_Primaerkode","ICD_Manifestation","Orpha_Kode","AlphaID_Kode")
headerRef1<- c ("IcdCode", "OrphaCode", "Type")
headerRef2<- c ("Gueltigkeit", "Alpha_ID", "ICD_Primaerkode1", "ICD_Manifestation", "ICD_Zusatz","ICD_Primaerkode2", "Orpha_Kode", "Label")
diff <- setdiff (mdHeader, names (medData))
if (!is.empty (diff)){
  str<- paste (diff,collapse=" " )
  msg <- paste ("Folgende Items fehlen: ", str)
  stop(msg)
}
names(refData1)<-headerRef1
names(refData2)<-headerRef2
dim (medData)

########## DQ Analysis #############
cdata <- data.frame(
  basicItem=
    c ("PatientIdentifikator","Aufnahmenummer", "Institut_ID",  "Geschlecht", "Diagnosetext","ICD_Text","ICD_Primaerkode","Orpha_Kode","AlphaID_Kode", "Total")
)
ddata <- data.frame(
  basicItem=
    c ( "Geburtsdatum",  "Aufnahmedatum", "Entlassungsdatum", "Total")
)
tdata <- data.frame(
  pt_no =NA, case_no =NA
)
repCol=c( "PatientIdentifikator", "Aufnahmenummer", "ICD_Primaerkode","Orpha_Kode")
setGlobals(medData, repCol, cdata, ddata, tdata)
items <- setdiff (cdata$basicItem ,c ("ICD_Primaerkode","Orpha_Kode", "Total"))
cdata <- getMissing(cdata,  cdata$basicItem, "missing_value", "missing_item")
ddata <- getMissing(ddata,  ddata$basicItem,"missing_value", "missing_item")
env$dq$dq_msg<-""
td <- NULL
l  <- NULL
if (!is.empty(env$medData$Institut_ID)){
  inst <- levels(as.factor(medData$Institut_ID))
  for (i in 1:length (inst)) {
    instID <- as.character (inst[i])
    out <-checkCordDQ(instID, inpatientCases, cdata, ddata, refData1, refData2, "dq_msg")
    test<-getTotalStatistic(out$cdata, out$ddata, "basicItem", "Total")
    tdata<-cbind (getTotalStatistic(out$cdata, out$ddata, "basicItem", "Total"),  out$tdata)
    l <- rbind (l, tdata)
    td<-rbind(td,subset(tdata, select= c( inst_id, missing_value_rate, outlier_rate, orphaCoding_completeness, uniqueness_rate, orphaCoding_plausibility_rate, orphaCoding_relativeFrequency, orphaCoding_absoluteFrequency,  uniqueRd_no, pt_no, case_no)))
    }
  
########## DQ-Report ###################
  path<- paste ("./Data/Export/Datenqualitätsreport_", studycode)
  getReport( repCol, "dq_msg", td, path)
  print(paste("DQ-Reports wurden im folgenden Ordner erstellt:", path))

}else{
  msg <- paste ("Institut_ID fehlt")
  stop(msg)
  }
