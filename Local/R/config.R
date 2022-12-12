#######################################################################################################
#' @description Setting local configuration
#' @author Kais Tahar, University Medical Center Göttingen
#' Project CORD-MI, grant number FKZ-01ZZ1911R
#######################################################################################################
library(config)
conf <- config::get(file = paste(getwd(), "/config.yml", sep = ""))

# v1) check for organization_name
if (exists("organization_name", where = conf) && nchar(conf$organization_name) >= 2) {
  institut_ID <- conf$organization_name
}else stop("No organization_name available, please set your organization_name in the config file")

# v2) check for path configuration
if (exists("path", where = conf) && nchar(conf$path) >= 2) {
  path= conf$path
}else stop("No data path found, please set the data path in the config file")

# v3) check for access and proxy configuration
if (exists("username", where = conf) && !is.null(conf$username)) {
  username =conf$username
  password=conf$password
  token =conf$token
}else {
  username = NULL
  password = NULL
  token = NULL
}
if (exists("http_proxy", where = conf) &&  !is.null(conf$http_proxy)) {
  Sys.setenv(http_proxy = conf$http_proxy)
}
if (exists("https_proxy", where = conf) && !is.null(conf$https_proxy)) {
  Sys.setenv(https_proxy = conf$https_proxy)
}
if (exists("no_proxy", where = conf) && !is.null(conf$no_proxy)) {
  Sys.setenv(no_proxy = conf$no_proxy)
}

# v4) check for inpatientCases_number
if (exists("inpatientCases_number", where = conf) && nchar(conf$inpatientCases_number) >= 3) {
  ipatCasesList<- conf$inpatientCases_number
} else {
  stop("No inpatient case number found, Please set the number of inpatient case for each year in the config file")
}

# v5) check inpatientEncounter_code
if (exists("inpatientEncounter_code", where = conf) && !is.null(conf$inpatientEncounter_code)) {
  encounterClass_value <- conf$inpatientEncounter_code
} else {
  encounterClass_value <- NULL
}

# v6) start and end of the reporting period
if (exists("startYear", where = conf) && !is.null(conf$startYear)) {
  if (!grepl("[0-9]{4}", conf$startYear)) stop("No date available for the start of reporting period:", reportYearStart)
  else reportYearStart = conf$startYear
} else {
  reportYearStart = 2015
}
if (exists("endYear", where = conf) && !is.null(conf$endYear)) {
  if (!grepl("[0-9]{4}", conf$endYear)) stop("No date available for the end of reporting period:", reportYearEnd)
  else reportYearEnd = conf$endYear
} else {
  reportYearEnd = 2022
}

# v7) data item and date format for diagnosis recorded date
if (exists("date_format", where = conf) && !is.null(conf$date_format)) {
  dateFormat = conf$date_format
} else {
  dateFormat = "%Y-%m-%d"
}
if (exists("diagnosisDate_item", where = conf) && !is.null(conf$diagnosisDate_item)) {
  diagnosisDate_item = conf$diagnosisDate_item
  dateRef = "Diagnosedatum"
} else {
  diagnosisDate_item = "recordedDate"
  dateRef = "Diagnosedatum"
}

# v8) custom parameters of used fhir data
if (exists("encounterClass_item", where = conf) && !is.null(conf$encounterClass_item)) {
  encounterClass_item= conf$encounterClass_item
} else {
  encounterClass_item= "class/code"
}
if (exists("icdCode_system", where = conf) && !is.null(conf$icdCode_system)) {
  icdSystem= conf$icdCode_system
} else {
  icdSystem="http://fhir.de/CodeSystem/dimdi/icd-10-gm"
}
if (exists("orphaCode_system", where = conf) && !is.null(conf$orphaCode_system)) {
  orphaSystem= conf$orphaCode_system
} else {
  orphaSystem="http://www.orpha.net"
}
if (exists("fhirBundles_max", where = conf) && !is.null(conf$fhirBundles_max)) {
  max_FHIRbundles = conf$fhirBundles_max
} else {
  max_FHIRbundles = "inf"
}
if (exists("tracer_no", where = conf) && !is.null(conf$tracer_no)) {
  tracerNo= conf$tracer_no
} else {
  tracerNo= 25
}

# v9) check for tracer list versions
if (exists("tracerList_version", where = conf) && nchar(conf$tracerList_version) >= 2) {
  if (grepl( "v2", conf$tracerList_version)) {
    tracerPath <-"./Data/refData/CordTracerList_v2.csv"
  }
  else if  (grepl( "v1", conf$tracerList_version)) {
    tracerPath <-"./Data/refData/CordTracerList_v1.csv"
  } 
}else {
  tracerPath <-"./Data/refData/CordTracerList_v2.csv"
}

