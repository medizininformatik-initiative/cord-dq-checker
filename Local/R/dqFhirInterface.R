#######################################################################################################
#' @description FHIR interface for data quality assessment in CORD-MI
#' @author Kais Tahar, University Medical Center Göttingen
#' Project CORD-MI, grant number FKZ-01ZZ1911R
#######################################################################################################
library(fhircrackr)

#define fhir search request
searchRequest_x <- paste0(
  path,
  'Patient?',
  '&_revinclude=Encounter:patient',
  "&_revinclude=Condition:patient"
)

searchRequest <- paste0(
  path,
  'Patient?',
  '_has:Condition:patient:recorded-date=ge2020-01-01',
  '&_revinclude=Encounter:patient',
  "&_revinclude=Condition:patient",
  '&_has:Condition:patient:code=A48.3, D18.10, D18.11, D18.12, D18.13, D18.18, D18.19, D45, D47.3, D57.0, D57.1, D57.2, D58.1, D76.1, D76.2, D76.3, D76.4, D82.1, D83.0, D83.1,',
  'D83.2, D83.8, D83.9, D86.0,D86.1, D86.2, D86.3, D86.8, D86.9, D89.8, D89.9, E03.0, E03.1, E24.0, E66.89, E70.0, E71.0, E74.0, E75.0, E75.2, E80.1, E83.0, E83.30, E83.50, E84.0,',
  'E84.1, E84.80, E84.87, E84.88, E84.9, E85.3, F84.2, G10, G11.4, G12.0, G12.1, G21.0, G23.1, G23.2, G23.3, G35, G36, G54.5, G61.0, G70.0, G71.0, G71.2, H35.1, I25.4, I30.1, I30.8,',
  'I30.9, I32.1, I40, I41.1, I41.8, I42.80, I73.1, I78.0, K62.7, K74.3, K76.5, L10.0, L13.0, L56.3, L63.0, L63.1, L93.1, M08.3, M09.00, M09.01, M09.02, M09.03, M09.04, M09.05, M09.06,',
  'M09.07, M09.08, M09.09, M30.0, M30.3, M31.3, M33.0, M33.1, M33.2, M34.1, M35.2, M908.2, M93.2, P27.1, Q00.1, Q04.2, Q05.5, Q05.6, Q05.7, Q05.8, Q17.2, Q20.3, Q21.3, Q22.4, Q22.5, Q23.4,',
  'Q28.21, Q30.0, Q43.1, Q68.8, Q71.6, Q72.7, Q75.0, Q77.1, Q77.4, Q78.0, Q78.2, Q79.0, Q79.2, Q79.6, Q80.1, Q82.2, Q85.1, Q87.4, Q91.0, Q91.1, Q91.2, Q91.4, Q91.5, Q91.6, Q91.7, Q96.1, Q96.2,',
  'Q96.3, Q96.4, Q96.5, Q96.6, Q96.7, Q96.8, Q96.9, Q97.0, R57.8, R65.0, R65.1, R65.2, R65.9, U07.1!, U07.2!, U07.3, U07.4!, U07.5,U08.9, U09.9, U10.9'
)

# get fhir bundles
bundles <- fhir_search(searchRequest, max_bundles =max_FHIRbundles) 

#define the table_description
ConditionTab <- fhir_table_description(
  resource = "Condition",
  cols = list(
    # condition_id = "id",
    patId = "subject/reference",
    encId= "encounter/reference",
    text= "code/text",
    display = "code/coding/display",
    code = "code/coding/code",
    system = "code/coding/system",
    recorded_date = "recordedDate"
  ),
  style = fhir_style(
    sep = " / ",
    brackets = c("[", "]")
  )
)
PatientTab <- fhir_table_description(
  resource = "Patient",
  cols = list(
    instId="meta/source",
    patId= "id",
    birthdate = "birthDate",
    gender = "gender",
    postalCode = "address/postalCode",
    country = "address/country",
    city = "address/city",
    type = "address/type"
  ),
  style = fhir_style(
    sep = " % ",
    brackets = c("[", "]")
  )
)
EncounterTab <- fhir_table_description(
  resource = "Encounter",
  cols = list(
    patId= "subject/reference",
    enId = "id",
    #enId = "identifier/value",
    start = "period/start",
    end = "period/end",
    class = "class/code",
    status ="status",
    admitCode ="hospitalization/admitSource/coding/code",  # Aufnahmeanlass
    diagnosisUse ="diagnosis/use" # admission, billing or discharge
  ),
  # style = list(
  # sep = " % ",
  #brackets = c("[", "]")
  # )
)
design <- fhir_design(ConditionTab, PatientTab, EncounterTab)
fhirRaw<- fhir_crack(bundles, design)
condRaw <- fhirRaw$ConditionTab
#sort out codes
condTmp1 <- fhir_melt(condRaw,
                      columns = c("code", "system", "display"),
                      brackets = c("[","]"),
                      sep = " / ",
                      all_columns = T)


condTmp2 <- fhir_melt(condTmp1,
                      columns = c("code", "system", "display"),
                      brackets = c("[","]"),
                      sep = " / ",
                      all_columns = T)

# clean up conditions
condTmp3 <- fhir_rm_indices(condTmp2, brackets = c("[", "]"))

# remove "Patient/" and Encounter
condTmp3$patId<- sub("Patient/", "", condTmp3$patId)
condTmp3$encId <- sub("Encounter/", "", condTmp3$encId)
condTmp3$resource_identifier <- NULL

# remove duplicate patients
condTmp3<- unique(condTmp3)

# filter conditions by code system
condIcd <- condTmp3[condTmp3$system=="http://fhir.de/CodeSystem/dimdi/icd-10-gm",]
condOrpha <- condTmp3[condTmp3$system=="http://www.orpha.net",]
condAlphaID <- condTmp3[condTmp3$system=="http://fhir.de/CodeSystem/dimdi/alpha-id",]

# split icd code in pri and sec code
condIcd$pri_code <- ifelse(nchar(condIcd$code)>6,sapply(strsplit(condIcd$code,' '), function(x) x[1]),condIcd$code)
condIcd$sec_code <- ifelse(nchar(condIcd$code)>6,sapply(strsplit(condIcd$code,' '), function(x) x[2]),'-')
#clean up
condIcd$system <- NULL
condIcd$code <- NULL
names(condIcd) <- c("PatientIdentifikator","Aufnahmenummer", "Diagnosetext", "ICD_Text", "Diagnosedatum", "ICD_Primaerkode", "ICD_Manifestation")

# OrphaI and AlphaID data
condOrpha$system <- NULL
condOrpha$display <- NULL
names(condOrpha) <- c("PatientIdentifikator","Aufnahmenummer", "Diagnosetext", "Orpha_Kode", "Diagnosedatum")
condAlphaID$system <- NULL
condAlphaID$display <- NULL
names(condAlphaID) <- c("PatientIdentifikator","Aufnahmenummer", "Diagnosetext", "AlphaID_Kode", "Diagnosedatum")

# join condition data
if (!(is.null(condIcd)|is.null (condOrpha)|is.null(condAlphaID))) conditions <-Reduce(function(x, y) base::merge(x, y, all=T), list(condIcd,condOrpha, condAlphaID)) else
  if (!(is.null(condIcd)|is.null (condOrpha))) conditions <-Reduce(function(x, y) base::merge(x, y, all=T), list(condIcd,condOrpha)) else conditions <- condIcd

# convert and save fhir bundles to a data frame patRaw
patRaw <- fhirRaw$PatientTab
patients <- fhir_rm_indices(patRaw, brackets = c("[", "]"))
patients$instId<- gsub("#.*","\\1",patients$instId)
#patients$birthdate <- as.Date(patients$birthdate)
if (isDate(patients$birthdate)) patients$birthdate <-as.Date(patients$birthdate) else
  if (!is.na(as.Date(patients$birthdate,origin ="2021", tryFormats = c("%Y")))) patients$birthdate <-as.Date(ISOdate(patients$birthdate, 06, 30))

names(patients) <- c("Institut_ID","PatientIdentifikator", "Geburtsdatum", "Geschlecht", "PLZ", "Land", "Wohnort", "Adressentyp")
entRaw <- fhirRaw$EncounterTab
encounters <- entRaw
encounters$patId <- sub("Patient/", "", entRaw$patId)
encounters$start <- as.Date(encounters$start)
encounters$end <- as.Date(encounters$end)
names(encounters) <- c("PatientIdentifikator","Aufnahmenummer","Aufnahmedatum", "Entlassungsdatum", "Kontakt_Klasse", "Fall_Status", "Aufnahmeanlass", "DiagnoseRolle")
instData<-Reduce(function(x, y) base::merge(x, y, all=T), list(patients,encounters,conditions))


