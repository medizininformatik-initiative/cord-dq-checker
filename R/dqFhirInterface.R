library(fhircrackr)

# fhir search request
searchRequest <- paste0(
  path,
  'Condition?'
)

# get fhir bundles
bundles <- fhir_search(searchRequest, max_bundles =50)
# define design parameters of condition resource
design <- list(
  Conditions = list(
    resource = "//Condition",
    cols = list(
      patient_id = "subject/reference",
      encounter_id = "encounter/reference",
      text= "code/text",
      display = "code/coding/display",
      code = "code/coding/code",
      system = "code/coding/system"

    ),
    style = list(
      sep = " / ",
      brackets = c("[", "]")
    )
  )
)

# convert and save fhir bundles to df condRaw
condRaw <- fhir_crack(bundles, design)$Conditions

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

# remove "Patient/" and "Encounter/"
condTmp3$patient_id <- sub("Patient/", "", condTmp3$patient_id)
condTmp3$encounter_id <- sub("Encounter/", "", condTmp3$encounter_id)
condTmp3$resource_identifier <- NULL

# remove duplicate patients
condTmp3<- unique(condTmp3)

# filter conditions by code system
condIcd <- condTmp3[condTmp3$system=="http://fhir.de/CodeSystem/dimdi/icd-10-gm",]
condOrpha <- condTmp3[condTmp3$system=="http://www.orpha.net",]
condAlphaID <- condTmp3[condTmp3$system=="http://fhir.de/CodeSystem/dimdi/alpha-id",]

# split icd code in pri and sec codes
condIcd$pri_code <- ifelse(nchar(condIcd$code)>6,sapply(strsplit(condIcd$code,' '), function(x) x[1]),condIcd$code)
condIcd$sec_code <- ifelse(nchar(condIcd$code)>6,sapply(strsplit(condIcd$code,' '), function(x) x[2]),'-')

#clean up
condIcd$system <- NULL
condIcd$code <- NULL
names(condIcd) <- c("PatId", "EncId", "Diagnosetext", "ICD_Text","ICD_Primaerkode", "ICD_Manifestation")

# Orpha and AlphaID data
condOrpha$system <- NULL
condOrpha$display <- NULL
names(condOrpha) <- c("PatId", "EncId", "Diagnosetext", "Orpha_Kode")
condAlphaID$system <- NULL
condAlphaID$display <- NULL
names(condAlphaID) <- c("PatId", "EncId", "Diagnosetext", "AlphaID_Kode")

# join conditions data
conditions <-Reduce(function(x, y) merge(x, y, all=T), list(condIcd,condOrpha, condAlphaID))
institution_id <- unlist(strsplit(conditions$PatId,'-P-'))[ c(TRUE,FALSE) ]
instData <- cbind( institution_id, conditions)
headers <- c ("Institut_ID","PatientIdentifikator","Aufnahmenummer","DiagnoseText","ICD_Text","ICD_Primaerkode","ICD_Manifestation","Orpha_Kode","AlphaID_Kode")
names(instData)<-headers


