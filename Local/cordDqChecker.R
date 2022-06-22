#######################################################################################################
#' @description Data quality analysis and reporting for CORD-MI
#' @author Kais Tahar, University Medical Center Göttingen
#' Project CORD-MI, grant number FKZ-01ZZ1911R
#######################################################################################################
rm(list = ls())
setwd("./")
# installall required packages
source("./R/installPackages.R")
library(dqLib)
library(openxlsx)
options(warn=-1)# to suppress warnings

cat("####################################***CordDqChecker***########################################### \n \n")
# check missing packages
pack <- unique(as.data.frame( (installed.packages())[,c(1,3)]))
dep <- c("dqLib", "fhircrackr", "writexl", "stringi")
depPkg <-subset(pack, pack$Package %in% dep)
diff <-setdiff(dep, depPkg$Package)
if (!is.empty(diff)) paste ("The following packages are missing:", toString (diff)) else{ 
  cat ("The following dependencies are installed:\n")
  print(depPkg, quote = TRUE, row.names = FALSE)
}
cat ("\n ####################################### Data Import ########################################## \n")
#------------------------------------------------------------------------------------------------------
# Setting path and variables
#------------------------------------------------------------------------------------------------------
# Export file name
exportFile = "DQ-Report_fhirTestData"
# report year
reportYear <-2020
# inpatient case number
Sys.setenv(INPATIENT_CASE_NO=10000)
# path to fhir server
Sys.setenv(FHIR_SERVER="http://141.5.101.1:8080/fhir/")
inpatientCases <- as.numeric(Sys.getenv("INPATIENT_CASE_NO"))
path <- Sys.getenv("FHIR_SERVER")
max_FHIRbundles <- Inf # Inf

# CSV and XLSX file formats are supported
#exportFile = "DQ-Report_dqTestData"
#path="./Data/medData/dqTestData.csv"
#path="./Data/medData/dqTestData.xlsx"

bItemCl <-"basicItem"
totalRow <-"Total"
#defining mandatory and optional items
cdata <- data.frame(
  basicItem= c("PatientIdentifikator","Aufnahmenummer", "Institut_ID",  "Geschlecht","PLZ", "Land","Kontakt_Klasse", "Fall_Status", "DiagnoseRolle", "ICD_Primaerkode","Orpha_Kode", "Total")
)
ddata <- data.frame(
  basicItem= c ( "Geburtsdatum",  "Aufnahmedatum", "Entlassungsdatum", "Diagnosedatum", "Total")
)
# optional items
oItem = c("Orpha_Kode")
tdata <- data.frame(
  pt_no =NA, case_no =NA
)
repCol=c( "PatientIdentifikator", "Aufnahmenummer", "ICD_Primaerkode","Orpha_Kode")

#------------------------------------------------------------------------------------------------------
# Import ref. Data
#------------------------------------------------------------------------------------------------------
refData1 <- read.table("./Data/refData/Tracerdiagnosen_AlphaID-SE-2022.csv", sep=",",  dec=",", na.strings=c("","NA"), encoding = "UTF-8",header=TRUE)
refData2 <- read.table("./Data/refData/icd10gm2022_alphaidse_edvtxt.txt", sep="|", dec= "," , quote ="", na.strings=c("","NA"), encoding = "UTF-8")
headerRef1<- c ("IcdCode", "Complete_SE", "Unique_SE")
headerRef2<- c ("Gueltigkeit", "Alpha_ID", "ICD_Primaerkode1", "ICD_Manifestation", "ICD_Zusatz","ICD_Primaerkode2", "Orpha_Kode", "Label")
names(refData1)<-headerRef1
names(refData2)<-headerRef2

#------------------------------------------------------------------------------------------------------
# Import CORD data
#------------------------------------------------------------------------------------------------------
medData <- NULL
if (is.null(path) | path=="")  stop("No path to data") else {
  if (grepl("fhir", path))
  {
    source("./R/dqFhirInterface.R")
    medData<- instData[ format(as.Date(instData$Entlassungsdatum, format="%Y-%m-%d"),"%Y")==reportYear, ]
  }else{ ext <-getFileExtension (path)
  if (ext=="csv") medData <- read.table(path, sep=";", dec=",",  header=T, na.strings=c("","NA"), encoding = "latin1")
  if (ext=="xlsx") medData <- read.xlsx(path, sheet=1,skipEmptyRows = TRUE)
  }
  if (is.null (medData)) stop("No data available")
}
#filter for report year
medData<- medData[format(as.Date(medData$Entlassungsdatum, format="%Y-%m-%d"),"%Y")==reportYear, ]
if (is.empty(medData)) stop("No data available for reporting year:", reportYear)
dItem <-names(medData)
msg <-cat("\n The following data items are loaded: \n")
print(paste(msg, dItem))

#------------------------------------------------------------------------------------------------------
# Start DQ analysis
#------------------------------------------------------------------------------------------------------
setGlobals(medData, repCol, cdata, ddata, tdata)
td <- NULL
if (!is.empty(medData$Institut_ID)){
  inst <- levels(as.factor(medData$Institut_ID))
  for (i in 1:length (inst)) {
    instID <- as.character (inst[i]) 
    # select meta data for DQ report
    repMeta= c("inst_id", "report_year")
    
    #------------------------------------------------------------------------------------------------------
    # Setting DQ dimensions , indicators and key numbers
    #------------------------------------------------------------------------------------------------------
    ############## Selection of DQ dimensions and indicators #########
    # select DQ indicators for completeness dimension
    compInd= c(
      "missing_item_rate", 
      "missing_value_rate", 
      "orphaCoding_completeness_rate"
    )
    # select DQ indicators for plausibility dimension
    plausInd= c( 
      "outlier_rate", 
      "orphaCoding_plausibility_rate"
    )
    # select DQ indicators for uniqueness dimension
    uniqInd= c(
      "rdCase_unambiguity_rate",
      "duplication_rate"
    )
   # select DQ indicators for concordance
    concInd= c(
      "tracerCase_rel_py_ipat",
      "unambigous_rdCase_rel_py_ipat",
      "orphaCase_rel_py_ipat"
    )

    ############ Selection of DQ key numbers ########################
    # select  key numbers for DQ report
    dqKeyNo= c(
      "case_no_py_ipat",
      "case_no_py", 
      "patient_no_py", 
      "orphaCoding_no_py",
      "rdCase_no_py",
      "orphaCase_no_py",
      "unambigous_rdCase_no_py", 
      "tracerCase_no_py"
    )
    dqRepCol <- c(repMeta, compInd, plausInd, uniqInd,concInd, dqKeyNo)
    # DQ report
    out <-checkCordDQ(instID, reportYear, inpatientCases, refData1, refData2, dqRepCol, repCol, "dq_msg", "basicItem", "Total", oItem)
    dqRep <-out$metric
    mItem <-out$mItem
  }
  
  ################################################### DQ Reports ########################################################
  path<- paste ("./Data/Export/", exportFile, "_", dqRep$report_year,  sep = "")
  getReport( repCol, "dq_msg", dqRep, path)
  top <- paste ("\n \n ####################################***CordDqChecker***###########################################")
  msg <- paste ("\n Data quality analysis for location:", dqRep$inst_id,
                "\n Report year:", dqRep$report_year,
                "\n Inpatient cases:", dqRep$case_no_py_ipat,
                "\n Case number:", dqRep$case_no_py,
                "\n Patient number:", dqRep$patient_no_py,
                "\n Coded rdCases:", dqRep$rdCase_no_py,
                "\n Orpha number:", dqRep$orphaCoding_no_py,
                "\n OrphaCoded rdCases:", dqRep$orphaCase_no_py,
                "\n unambiguity rdCases:", dqRep$unambigous_rdCase_no_py,
                "\n tracer rdCases:", dqRep$tracerCase_no_py,
                "\n Missing item rate:", dqRep$missing_item_rate,
                "\n Missing value rate:", dqRep$missing_value_rate,
                "\n RdCase unambiguity rate:", dqRep$rdCase_unambiguity_rate,
                "\n OrphaCoding completeness rate:", dqRep$orphaCoding_completeness_rate,
                "\n OrphaCoding plausibility rate:", dqRep$orphaCoding_plausibility_rate)
  if (dqRep$missing_item_rate >0)   msg <- paste (msg, "\n Following items are missing:", toString(mItem))
  msg <- paste(msg, 
               "\n \n ########################################## Export ################################################")
  msg <- paste (msg, "\n \n For more infos about data quality indicators see the generated report \n >>> in the file path:", path)
  bottom <- paste ("\n ####################################***CordDqChecker***###########################################")
  cat(paste (top, msg, bottom, sep="\n"))
}else{
  msg <- paste ("Institut_ID fehlt")
  stop(msg)
}
