#######################################################################################################
#' @description FHIR interface for data quality assessment in CORD-MI
#' @author Kais Tahar, University Medical Center Göttingen
#' Project CORD-MI, grant number FKZ-01ZZ1911R
#######################################################################################################
library(fhircrackr)

#define fhir search request
if (!exists("cordTracer"))
{
  searchRequest <- paste0(
    path,
    'Patient?',
    '_has:Condition:patient:recorded-date=', reportYear,
    '&_revinclude=Encounter:patient',
    "&_revinclude=Condition:patient"
  )

}else {
  searchRequest <- paste0(
    path,
    'Condition?',
    'code=', cordTracer,
    '&recorded-date=',reportYear,
    "&_include=Condition:encounter",
    '&_include=Condition:subject:Patient'
  )
}

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
if (!is.empty (condRaw))
{
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
} else instData<-NULL

