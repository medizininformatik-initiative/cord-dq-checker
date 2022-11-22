#######################################################################################################
#' @description Data quality analysis and reporting for CORD-MI
#' @author Kais Tahar, University Medical Center Göttingen
#' Project CORD-MI, grant number FKZ-01ZZ1911R
#######################################################################################################
rm(list = ls())
setwd("./")
# installall required packages
source("./R/installPackages.R")
#import dqLib and required packages
source("./R/dqLibCord.R")
source("./R/dqLibCore.R")
library(openxlsx)
library(stringi)
options(warn=-1)# to suppress warnings

cat("####################################***CordDqChecker***########################################### \n \n")
# check missing packages
pack <- unique(as.data.frame( (installed.packages())[,c(1,3)]))
dep <- c("openxlsx", "fhircrackr",  "stringi")
depPkg <-subset(pack, pack$Package %in% dep)
diff <-setdiff(dep, depPkg$Package)
if (!is.empty(diff)) paste ("The following packages are missing:", toString (diff)) else{ 
  cat ("The following dependencies are installed:\n")
  print(depPkg, quote = TRUE, row.names = FALSE)
}
cat ("\n ####################################### Data Import ########################################## \n")

#------------------------------------------------------------------------------------------------------
# Setting path and local variables
#------------------------------------------------------------------------------------------------------
# Execution time
startTime <- base::Sys.time()
#Institut ID
institut_ID = "meDIC_Test"
# path to fhir server
Sys.setenv(FHIR_SERVER="http://141.5.101.1:8080/fhir/")
path <- Sys.getenv("FHIR_SERVER")
# CSV and XLSX file formats are supported
#path="./Data/medData/dqTestData.csv"
#path="./Data/medData/dqTestData.xlsx"
# report year
reportYearStart <-2019
reportYearEnd <-2020
# date format
dateRef ="Entlassungsdatum"
dateFormat="%Y-%m-%d"
# inpatient case number
Sys.setenv(INPATIENT_CASE_NO=997)
inpatientCases <- as.numeric(Sys.getenv("INPATIENT_CASE_NO"))
max_FHIRbundles <- Inf # Inf
# Export file name
exportFile = "DQ-Report_StandortName"
# import CORD tracer diagnoses
# CordTracerList version 2.0
tracerPath <-"./Data/refData/CordTracerList_v2.csv"
# cord tracer version 1.0
#tracerPath <-"./Data/refData/CordTracerList_v1.csv"
cordTracer <- read.table(tracerPath, sep=",",  dec=",", na.strings=c("","NA"), encoding = "UTF-8",header=TRUE)$IcdCode
cordTracer <-""
# number of tracer codes per thread
tracerNo=50

#------------------------------------------------------------------------------------------------------
# Setting ref. Data
#------------------------------------------------------------------------------------------------------
bItemCl <-"basicItem"
totalRow <-"Total"
# defining mandatory and optional items
cdata <- data.frame(
  basicItem= c("PatientIdentifikator","Aufnahmenummer", "Institut_ID",  "Geschlecht","PLZ", "Land","Kontakt_Klasse", "Fall_Status", "DiagnoseRolle", "ICD_Primaerkode","Orpha_Kode", "Total")
)
ddata <- data.frame(
  basicItem= c ( "Geburtsdatum",  "Aufnahmedatum", "Entlassungsdatum", "Diagnosedatum", "Total"),
  engLabel = c("birthdate", "admission date" , "discharge date", "diagnosis date", NA)
)
# optional items
oItem = c("Orpha_Kode")
tdata <- data.frame(
  pt_no =NA, case_no =NA
)
caseItems <- c("PatientIdentifikator","Aufnahmenummer","Kontakt_Klasse", "Fall_Status","ICD_Primaerkode", "Aufnahmedatum", "Entlassungsdatum", "Diagnosedatum","DiagnoseRolle")
concRef <- list (min=593, max=1851)
repCol=c( "PatientIdentifikator", "Aufnahmenummer", "ICD_Primaerkode","Orpha_Kode")
refData1 <- read.table("./Data/refData/Tracerdiagnosen_AlphaID-SE-2022.csv", sep=",",  dec=",", na.strings=c("","NA"), encoding = "UTF-8",header=TRUE)
refData2 <- read.table("./Data/refData/icd10gm2022_alphaidse_edvtxt.txt", sep="|", dec= "," , quote ="", na.strings=c("","NA"), encoding = "UTF-8")
headerRef1<- c ("IcdCode", "Complete_SE", "Unique_SE")
headerRef2<- c ("Gueltigkeit", "Alpha_ID", "ICD_Primaerkode1", "ICD_Manifestation", "ICD_Zusatz","ICD_Primaerkode2", "Orpha_Kode", "Label")
names(refData1)<-headerRef1
names(refData2)<-headerRef2

#------------------------------------------------------------------------------------------------------
# Import CORD data
#------------------------------------------------------------------------------------------------------
if (!grepl("[0-9]{4}", reportYearStart)) stop("No date available for the start of reporting period:", reportYearStart)
if (!grepl("[0-9]{4}", reportYearEnd)) stop("No date available for the end of reporting period:", reportYearEnd) else range <-reportYearStart:reportYearEnd
if (is.null(path) | path=="" | is.na(path)) stop("No path to data") else {
  for ( reportYear in range){
    # Execution time
    startTime <- base::Sys.time()
    yearMsg <-paste (" \n \n >>> New reporting year:" , reportYear, "\n \n " )
    cat(yearMsg, sep="\n")
    medData <- NULL
    msg <- NULL
    dataFormat =""
    dqRep <-NULL
    if (grepl("fhir", path))
    {
      dataFormat = "FHIR"
      tracer <- cordTracer
      if (length (tracer) > tracerNo )
      {
        while ( length(tracer) > tracerNo) {
          cordTracer.vec <- tail(tracer, tracerNo)
          cordTracer <- paste0(cordTracer.vec, collapse=", ")
          print(paste ("cordTracer:",    cordTracer, "NO:", length(cordTracer.vec)))
          source("./R/dqFhirInterface.R")
          instData <- instData[ format(as.Date(instData[[dateRef]], format=dateFormat),"%Y")==reportYear, ]
          medData <- base::rbind(medData, instData)
          tracer <- head(tracer, - tracerNo)
        }
        if ( length(tracer) <= tracerNo)
        { 
          cordTracer.vec <- tracer
          cordTracer <- paste0(cordTracer.vec, collapse=", ")
          print(paste ("cordTracer:",    cordTracer, "NO:", length(cordTracer.vec)))
          source("./R/dqFhirInterface.R")
          instData <- instData[ format(as.Date(instData[[dateRef]], format=dateFormat),"%Y")==reportYear, ]
          medData <- base::rbind(medData, instData)
        }
        medData <-base::unique(medData)
        
      } 
      else { 
        cordTracer <- paste0(tracer, collapse=", ")
        print(paste ("cordTracer:",    cordTracer, "NO:", length(tracer)))
        source("./R/dqFhirInterface.R")
        medData<- instData[ format(as.Date(instData[[dateRef]], format=dateFormat),"%Y")==reportYear, ]
      }
    }else{ 
      ext <-getFileExtension(path)
      if (ext=="csv") { 
        dataFormat = "CSV"
        medData <- read.table(path, sep=";", dec=",",  header=T, na.strings=c("","NA"), encoding = "latin1") 
      }
      if (ext=="xlsx") { 
        dataFormat = "Excel"
        medData <- read.xlsx(path, sheet=1,skipEmptyRows = TRUE)
        medData$Entlassungsdatum <- as.Date(medData$Entlassungsdatum,  origin="2020-10-24", format=dateFormat)
      }
    }
    if (is.null (medData)) { 
      warning("No data available")
      next
    }
  # filter for report year
  #medData<- NULL
  medData<- medData[format(as.Date(medData[[dateRef]], format=dateFormat),"%Y")==reportYear, ]
  if (is.null(medData) | (dim(medData)[1]==0)) { 
    endTime <- base::Sys.time()
    timeTaken <-  round (as.numeric (endTime - startTime, units = "mins"), 2)
    dqRep$executionTime_inMin <-timeTaken
    dqRep$dataFormat <- dataFormat
    dqRep$report_year <- reportYear
    dqRep$inst_id <- institut_ID 
    top <- paste ("\n \n ####################################***CordDqChecker***###########################################")
    noDataMsg<- paste("\n No data available for reporting year:", reportYear)
    dqRep$msg <- noDataMsg
    msg <- paste ("\n Data quality analysis for location:", dqRep$inst_id,
                  "\n Report year:", dqRep$report_year,
                  "\n Time taken in min:", timeTaken)
    warning("No data available for reporting year:", reportYear)

    pathExp<- paste ("./Data/Export/", exportFile, "_", dataFormat, "_",  reportYear,  sep = "")
    msg <- paste(msg, noDataMsg,
                 "\n \n ########################################## Export ################################################")
    write.csv(dqRep, paste (pathExp,".csv", sep =""), row.names = FALSE)
    msg <- paste ( msg , "\n \n See the generated report \n >>> in the file path:", pathExp)
    
    bottom <- paste ("\n ####################################***CordDqChecker***###########################################")
    cat(paste (top,msg, bottom, sep="\n"))
    next
  }
  if (!("Institut_ID" %in% names(medData))) medData$Institut_ID=institut_ID
  # if ("Orpha_Kode"  %in% names(medData)) medData$Orpha_Kode = NULL
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
        "item_completeness_rate", 
        "value_completeness_rate", 
        "subject_completeness_rate",
        "case_completeness_rate",
        "orphaCoding_completeness_rate"
      )
      # select DQ indicators for plausibility dimension
      plausInd= c( 
        "range_plausibility_rate", 
        "orphaCoding_plausibility_rate"
      )
      # select DQ indicators for uniqueness dimension
      uniqInd= c(
        "rdCase_unambiguity_rate",
        "rdCase_dissimilarity_rate"
      )
      # select DQ indicators for concordance
      concInd= c(
        "conc_with_refValues",
        "rdCase_rel_py_ipat",
        "orphaCase_rel_py_ipat",
        "tracerCase_rel_py_ipat"
      )
      
      ############ Selection of DQ key numbers ########################
      # select  key numbers for DQ report
      dqKeyNo= c(
        "case_no_py_ipat",
        "patient_no_py", 
        "rdCase_no_py",
        "orphaCase_no_py",
        "tracerCase_no_py",
        "missing_item_no_py",
        "missing_value_no_py",
        "incomplete_subject_no_py",
        "orphaMissing_no_py",
        "implausible_codeLink_no_py",
        "outlier_no_py",
        "ambiguous_rdCase_no_py", 
        "duplicateRdCase_no_py"
      )
      dqRepCol <- c(repMeta, compInd, plausInd, uniqInd, concInd, dqKeyNo)
      # DQ report
      out <-checkCordDQ(instID, reportYear , inpatientCases, refData1, refData2, dqRepCol,repCol, "dq_msg", "basicItem", "Total", oItem, caseItems, concRef)
      dqRep <-out$metric
      mItem <-out$mItem
      dqRep$dataFormat <- dataFormat
      endTime <- base::Sys.time()
      timeTaken <-  round (as.numeric (endTime - startTime, units = "mins"), 2)
      dqRep$executionTime_inMin <-timeTaken
    }
    
    ################################################### DQ Reports ########################################################
    expPath<- paste ("./Data/Export/", exportFile, "_", dataFormat,"_", dqRep$report_year,  sep = "")
    getReport( repCol, "dq_msg", dqRep, expPath)
    
    top <- paste ("\n \n ####################################***CordDqChecker***###########################################")
    msg <- paste ("\n Data quality analysis for location:", dqRep$inst_id,
                  "\n Report year:", dqRep$report_year,
                  "\n Inpatient case:", dqRep$case_no_py_ipat,
                  "\n Patient number:", dqRep$patient_no_py,
                  "\n Coded rdCases:", dqRep$rdCase_no_py,
                  "\n Orpha Cases:", dqRep$orphaCase_no_py,
                  "\n Tracer Cases:", dqRep$tracerCase_no_py,
                  "\n Item completeness rate:", dqRep$item_completeness_rate,
                  "\n Value completeness rate:", dqRep$value_completeness_rate,
                  "\n Subject completeness rate:",  dqRep$subject_completeness_rate,
                  "\n Case completeness rate:",  dqRep$case_completeness_rate,
                  "\n OrphaCoding completeness rate:", dqRep$orphaCoding_completeness_rate,
                  "\n OrphaCoding plausibility rate:", dqRep$orphaCoding_plausibility_rate,
                  "\n RdCase unambiguity rate:", dqRep$rdCase_unambiguity_rate,
                  "\n RdCase dissimilarity rate:", dqRep$rdCase_dissimilarity_rate,
                  "\n RdCase rel. frequency:", dqRep$rdCase_rel_py_ipat,
                  "\n Tacer Cases rel. frequency:", dqRep$tracerCase_rel_py_ipat,
                  "\n Orpha Cases rel. frequency:", dqRep$orphaCase_rel_py_ipat,
                  "\n Concordance with reference values:", dqRep$conc_with_refValues
    )
    
    if (dqRep$missing_item_no_py >0)   msg <- paste (msg, "\n", toString(mItem))
    msg <- paste(msg, 
                 "\n \n ########################################## Export ################################################")
    msg <- paste (msg, "\n \n For more infos about data quality indicators see the generated report \n >>> in the file path:", expPath)
    bottom <- paste ("\n ####################################***CordDqChecker***###########################################\n")
    
    cat(paste (top, msg, bottom, sep="\n"))
  }else{
    msg <- paste ("Institut_ID fehlt")
    stop(msg)
    }
  }
}
