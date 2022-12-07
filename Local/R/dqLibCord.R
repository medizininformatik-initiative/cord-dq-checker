#######################################################################################################
# Description: This script provides functions for data quality analysis in CORD-MI
# Date Created: 2021-02-26
#' @author: Kais Tahar, University Medical Center Göttingen
#' @keywords internal
#' @name dqLib
"_PACKAGE"
# ######################################################################################################

#' @title checkCordDQ
#' @description This function checks the quality of loaded data regarding selected quality metrics
#' The default data quality dimensions are completeness, plausibility, uniqueness and concordance
#' @import stringi
#' @export
#'
checkCordDQ <- function ( instID, reportYear, inpatientCases, refData1, refData2, dqInd, repCol, cl, bItemCl, totalRow, oItem,...) {
  vars <- list(...)
  #cl <-rev(repCol)[1]
  if (is.null (cl)) stop("No report design available")
  if (is.null (env$medData)) stop("No data available")
  if (is.null(env$medData$ICD_Primaerkode)) stop("Missing mandatory item: ICD_Primaerkode")
  if (is.null(env$medData$Orpha_Kode)) env$medData$Orpha_Kode <-NA
  else env$dq <- { subset(env$medData, select = repCol)
    env$dq[cl]<-""
  }
  env$tdata$report_year <-reportYear
  if (is.null(oItem)) mv <-totalRow
  mv <-c (totalRow, oItem)
  if (is.null(env$ddata)) basicItem <- setdiff(env$cdata[, bItemCl],mv)
  else basicItem <- setdiff (union(env$cdata[, bItemCl], env$ddata[, bItemCl]),mv)
  if ( !is.null(instID)){
    env$tdata$inst_id <- instID
    instData<- env$medData[which(env$medData$Institut_ID==instID),]
    if (nrow(instData)>0) env$medData <- instData
  }else {
    env$tdata$inst_id <- "ID fehlt"
  }
  #row_no = nrow(env$medData)
  rdDup_no =0
  inputData <-env$medData
  row_no = nrow(inputData)
  eList <-refData1[which(refData1$Unique_SE=="yes"),]
  
  if(!is.empty(env$medData$PatientIdentifikator) & !is.empty(env$medData$Aufnahmenummer) & !is.empty(env$medData$ICD_Primaerkode) & !is.empty(env$medData$Orpha_Kode))
  {
    env$medData<-env$medData[!duplicated(env$medData[c("PatientIdentifikator", "Aufnahmenummer", "ICD_Primaerkode","Orpha_Kode")]),]
    env$dq <- subset(env$medData, select = repCol)
    env$dq[cl]<-""
    dup <-inputData[duplicated(inputData[c("PatientIdentifikator", "Aufnahmenummer", "ICD_Primaerkode","Orpha_Kode")],fromLast=TRUE),]
    if (!dim(dup)[1]==0)
    { 
      dup$dupRdCase <-NA
      icdList <-which(!( dup$ICD_Primaerkode =="" | is.na(dup$ICD_Primaerkode) | is.empty(dup$ICD_Primaerkode)))
      for(i in icdList){
        iCode <- stri_trim(as.character(dup$ICD_Primaerkode[i]))
        oCode <- stri_trim(as.character(dup$Orpha_Kode[i]))
        if (is.element(iCode, stri_trim(as.character(eList$IcdCode))))
        {
          dup$dupRdCase[i] = "yes"
        }
        else if (!is.na(as.numeric(oCode))) {
          dup$dupRdCase[i] = "yes"
        }
      }
      dupRd <-dup[which(dup$dupRdCase=="yes"),]
      rdDup_no <- length (unique(dupRd$Aufnahmenummer))
      env$dup <-dup
      
    } else   rdDup_no =0

  }
  else if(!is.empty(env$medData$PatientIdentifikator) & !is.empty(env$medData$Aufnahmenummer) & !is.empty(env$medData$ICD_Primaerkode))
  {
    env$medData<-env$medData[!duplicated(env$medData[c("PatientIdentifikator", "Aufnahmenummer", "ICD_Primaerkode")]),]
    env$dq <- subset(env$medData, select = repCol)
    env$dq[cl]<-""
    #dup <-which(duplicated(medData[c("PatientIdentifikator", "Aufnahmenummer", "ICD_Primaerkode")], fromLast=TRUE))
    dup <-inputData[duplicated(inputData[c("PatientIdentifikator", "Aufnahmenummer", "ICD_Primaerkode")], fromLast=TRUE),]
    if (!dim(dup)[1]==0)
    { 
      dup$dupRdCase <-NA
      icdList <-which(!( dup$ICD_Primaerkode =="" | is.na(dup$ICD_Primaerkode) | is.empty(dup$ICD_Primaerkode)))
      for(i in icdList){
        iCode <- stri_trim(as.character(dup$ICD_Primaerkode[i]))
        if (is.element(iCode, stri_trim(as.character(eList$IcdCode))))
        {
          dup$dupRdCase[i] = "yes"
        }
      }
      dupRd <-dup[which(dup$dupRdCase=="yes"),]
      rdDup_no <- rdDup_no +length (unique(dupRd$Aufnahmenummer))
      env$dup <-base::rbind(env$dup, dup)
    }else   rdDup_no =0
  }
  if(!is.empty(env$medData$PatientIdentifikator)) env$tdata$patient_no = length (unique(env$medData$PatientIdentifikator))
  if(!is.empty(env$medData$Aufnahmenummer)) env$tdata$case_no = length (env$medData$Aufnahmenummer[which(!duplicated(env$medData$Aufnahmenummer)& ! is.na(env$medData$Aufnahmenummer))])
  
  #D1 completeness
  keyD1 <- checkD1( refData1, cl, basicItem, bItemCl)
  env$mItem <- keyD1$mItem
  env$tdata <- addD1(env$tdata, keyD1$k2_orpha_no, keyD1$k2_orphaCheck_no)
  itemVec <- names (env$medData)
  inter <- intersect (basicItem, itemVec)
  env$tdata <- getSubjCompleteness(env$tdata,"PatientIdentifikator", inter, env$medData)
  if(!is.empty(vars)) caseItems <- vars[[1]]
  else caseItems <- NULL
  if(!is.null(caseItems)) env$tdata$case_completeness_rate<- round(getCaseCompletenessRate(env$cdata, env$ddata, caseItems),2)
  #D2 plausibility
  keyD2 <- checkD2( refData2, bItemCl, cl)
  env$tdata <- addD2( env$tdata, keyD2$k1_rd_counter, keyD2$k1_check_counter)
  #D3 uniqueness
  env$tdata$duplicateCase_no = row_no - nrow(env$medData)
  env$tdata$duplicateRdCase_no =rdDup_no
 # env$tdata$duplication_rate <- round((env$tdata$duplicateCase_no/row_no)*100,2)
  keyD3 <- checkD3( refData1, refData2, cl)
  env$tdata <- addD3(env$tdata, keyD3$k3_unambiguous_rdDiag_no,  keyD3$k3_unambiguous_rdCase_no, keyD3$k3_checkedRdCase_no)
  total<-getTotalStatistic(bItemCl, totalRow)
  total$value_completeness_rate <- 100-env$tdata$missing_value_rate
  total$range_plausibility_rate <-100-env$tdata$outlier_rate
  env$tdata <-total
  #D4 concordance
  keyD4 <- checkD4(cl)
  env$tdata <- addD4(env$tdata,  keyD4$k4_counter_orpha, keyD4$k4_counter_orphaCase, keyD3$k3_unambiguous_rdCase_no, inpatientCases)
  if(!is.empty(vars) & length(vars)>=2) concRef <- vars[[2]]
  else concRef <- NULL
  if(!is.null(concRef)) env$tdata$conc_with_refValues<-getConcWithRefValues(env$tdata$tracerCase_rel_py_ipat, concRef)
  
  orphaCases <- env$dq[which(env$dq$orphaCase=="yes"),]
  rdCases <- env$dq[which (env$dq$CheckedRdCase=="yes"),]
  env$tdata$orphaPatient_no_py = length(unique(orphaCases$PatientIdentifikator))
  env$tdata$rdPatient_no_py = length(unique(rdCases$PatientIdentifikator))
  
  td<-getUserSelectedMetrics(dqInd, env$tdata)
  out <- list()
  out[["metric"]] <-td
  out[["mItem"]] <-env$mItem
  out

}

#------------------------------------------------------------------------------------------------------
# functions for the completeness dimension (D1)
#------------------------------------------------------------------------------------------------------

#' @title checkD1
#' @description This function checks the quality of loaded data regarding the completeness dimension (D1)
#'
checkD1 <- function ( refData, cl, basicItems,bItemCl){
  env$medData<- env$medData[!sapply(env$medData, function(x) all( is.empty(x) | is.na(x)))]
  mItem <- getMissingItem(basicItems)
  if (!is.null(env$cdata)) env$cdata <- getMissingValue(env$cdata, bItemCl, "missing_value", "missing_item")
  if (!is.null(env$ddata))env$ddata <- getMissingValue(env$ddata, bItemCl, "missing_value", "missing_item")
  if (!is.null(env$medData$Orpha_Kode)) dqList <- append(checkOrphaCodingCompleteness(refData, cl), list (mItem=mItem))
  else {
    dqList <-list(k2_orphaCheck_no =0,k2_orpha_no=0,mItem=mItem)
    #env$tdata$tracerCase_no <- 0
  }
  dqList
}

#' @title getSubjCompleteness
#' @description This function evaluates the completeness of recorded subjects such as inpatient or outpatients
#' @export
#'
getSubjCompleteness <-function(rep, subj, itemVec, medData) {
  if (all(itemVec %in%  colnames(medData)==TRUE))
  {
    basicData <-subset(medData, select= itemVec)
    basicData[basicData==""] <-NA
    subj_no <-length(unique(basicData[[subj]]))
    completeData <- na.omit(basicData)
    complete_subj_no_py <-length(unique(completeData[[subj]]))
    rep$incomplete_subject_no_py <-subj_no-complete_subj_no_py
    rep$subject_completeness_rate <-100-round((rep$incomplete_subject_no_py/subj_no)*100,2)
  }
  else {
    rep$incomplete_subject_no_py <-subj_no
    rep$subject_completeness_rate <-0
  }
  
  rep
}

#' @title getCaseCompletenessRate
#' @description This function evaluates the completeness of case module
#'
getCaseCompletenessRate<-function (cdata, ddata, caseItems){
  mvr =0
  for (item in caseItems) {
    index = which(cdata$basicItem==item)[1]
    if (!is.null(index) & !is.na(index) ) {
      if (cdata$N_Item[index]==0)   mvr <-mvr +100
      else mvr <-mvr+cdata$missing_value_rate[index]
    }
    else{
      index = which(ddata$basicItem==item)[1]
      if (!is.null(index) & !is.na(index)){
        if (ddata$N_Item[index]==0)   mvr <-mvr +100
        else mvr <-mvr+ddata$missing_value_rate[index]
      }
    }

  }
  cc <-(100-(mvr/length(caseItems)))
  cc
}

#' @title checkOrphaCodingCompleteness
#' @description This function checks the completeness of OrphaCoding
#' @import stringi
#'
checkOrphaCodingCompleteness <- function ( refData, cl){
  env$dq$tracer <-NA
  k2_orpha_no =0
  k2_orphaCheck_no=0
  missing_counter1=0
  missing_counter2=0
  refData <-refData[which(refData$Complete=="yes"),]
  #refData <-refData[(which(refData$Type=="1:1" | refData$Type=="n:1")),]
  env$cdata <- addMissingValue("Orpha_Kode",env$cdata, 0,0)
  env$cdata <- addMissingValue("AlphaID_Kode",env$cdata, 0,0)
  if (!is.null(env$medData$ICD_Primaerkode))
  {
    iList <-which(env$medData$ICD_Primaerkode !="" & !is.na(env$medData$ICD_Primaerkode)  & !is.empty(env$medData$ICD_Primaerkode))
    for(i in iList){
      iCode <- stri_trim(as.character(env$medData$ICD_Primaerkode[i]))
      rdRefList<- which(stri_trim(as.character(refData$IcdCode))==iCode)
      if (!is.empty(rdRefList)) {
       #k2_orphaCheck_no = k2_orphaCheck_no +1
        env$dq$tracer[i] <-"yes"
        if("Orpha_Kode" %in% colnames(env$medData)){
          code <-as.character(env$medData$Orpha_Kode[i])
          if(!(is.null(code) | is.na(code) | is.empty(code)))
          {
            oCode <-as.numeric(code)
            if (is.na(oCode)){
              #env$dq[,cl][i] <- paste("Orpha Code",code, "ist nicht valide. ", env$dq[,cl][i] )
              k2_orphaCheck_no = k2_orphaCheck_no +1
              missing_counter1 =missing_counter1 +1
            }
            else {
              k2_orphaCheck_no = k2_orphaCheck_no +1
              k2_orpha_no =k2_orpha_no +1
            }
          }
          else{
            k2_orphaCheck_no = k2_orphaCheck_no +1
            env$dq[,cl][i] <- paste("Missing Orpha Code. ", env$dq[,cl][i])
            missing_counter1 =missing_counter1 +1
          }
        }
        if("AlphaID_Kode" %in% colnames(env$medData)){
          aCode <-as.character(env$medData$AlphaID_Kode[i])
          if (is.na(aCode) | is.empty(aCode)) {
            env$dq[,cl][i] <- paste("Missing AlphaID Code. ", env$dq[,cl][i])
            missing_counter2 =missing_counter2 +1
          }
        }
      }
    }
  }
  else {
    oList <-which(env$medData$Orpha_Kode !="" & !is.na(env$medData$Orpha_Kode)  & !is.empty(env$medData$Orpha_Kode))
    k2_orpha_no = length(oList)
    k2_orphaCheck_no = length(env$medData$Orpha_Kode)
    missing_counter1 = k2_orphaCheck_no - k2_orpha_no
    aList <-which(env$medData$AlphaID_Kode !="" & !is.na(env$medData$AlphaID_Kode)  & !is.empty(env$medData$AlphaID_Kode))
    k2_alpha_no = length(aList)
    k2_checkAlpha_no = length(env$medData$AlphaID_Kode)
    missing_counter2 = k2_checkAlpha_no -k2_alpha_no
  }

  tracer <-env$dq[ which (env$dq$tracer=="yes"),]
  env$tdata$tracerCase_no <- length (unique(tracer$Aufnahmenummer))
  env$cdata <- addMissingValue("Orpha_Kode", env$cdata, missing_counter1,k2_orphaCheck_no )
  env$cdata <- addMissingValue("AlphaID_Kode", env$cdata, missing_counter2 ,k2_orphaCheck_no )

  out <- list()
  out[["k2_orphaCheck_no"]] <-k2_orphaCheck_no
  out[["k2_orpha_no"]] <-k2_orpha_no
  out
}

#' @title addD1
#' @description This function adds indicators and key numbers for the completeness dimension (D1)
#'
addD1<- function ( tdata,  orpha, checkNo) {
  tdata$item_completeness_rate <- 100-tdata$missing_item_rate
  if(checkNo>0){
    tdata$orpha_no <- orpha
    tdata$icdRd_no<- checkNo
    tdata$orphaMissing_no <-checkNo-orpha
    or <- ( orpha/checkNo) * 100
    tdata$orphaCoding_completeness_rate <- round(or,2)
  }
  else {
    tdata$orpha_no <- 0
    tdata$icdRd_no <- 0
    tdata$orphaMissing_no <- NA
    tdata$orphaCoding_completeness_rate<-0
    #tdata$item_completeness_rate <-0
  }
  tdata
}

#------------------------------------------------------------------------------------------------------
# functions for the plausibility dimension (D2)
#------------------------------------------------------------------------------------------------------

#' @title checkD2
#' @description This function checks the quality of loaded data regarding the plausibility dimension (D2)
#'
checkD2 <- function (refData2, bItemCl, cl){
  # get outliers
  if (!is.null(env$ddata))
  {
    dItem <- env$ddata[, bItemCl]
    if (!is.empty(dItem)) {
      for (item in unique(dItem)) {
        env$ddata  <-checkOutlier(env$ddata, item, cl)
      }
    }

  }
  # check ICD10-Orpha
  if (!is.null(env$medData$Orpha_Kode)) out <-checkOrphaCoding(refData2, bItemCl, cl)
  else out <- list (k1_rd_counter=0,k1_check_counter=0 )
  out
}

#' @title checkOrphaCoding
#' @description This function checks the plausibility of ICD-Orpha Coding
#' @import stringi
#'
checkOrphaCoding<- function (refData2, bItemCl, cl) {
  k1_check_counter =0
  k1_rd_counter=0
  if(!is.empty(env$medData$ICD_Primaerkode)){
    iList <-which(env$medData$ICD_Primaerkode !="" & !is.na(env$medData$ICD_Primaerkode) & !is.empty(env$medData$ICD_Primaerkode))
    for(i in iList){
      iCode <- stri_trim(as.character(env$medData$ICD_Primaerkode[i]))
      oCode <-as.numeric(as.character(env$medData$Orpha_Kode[i]))
      code <-as.character(env$medData$Orpha_Kode[i])
      if (is.na(oCode) & !is.na(code) ) {
        k1_check_counter =k1_check_counter+1
        #env$dq[,cl][i] <- paste("Orpha Code ist nicht valide. ", env$dq[,cl][i] )
        msg<- paste("ICD10-Orpha combination:" , iCode,"-", code ,  "is implausible according to Alpha-ID-SE.",  env$dq[,cl][i])
        env$dq[,cl][i] <- msg

      }
      else if (!(is.null(oCode) | is.na(code) | is.empty(oCode))){
        iRefList<- which(stri_trim(as.character(refData2$ICD_Primaerkode1))==iCode)
        if (!is.empty (iRefList)){
          oRefList <- ""
          k1_check_counter =k1_check_counter+1
          for (j in iRefList){
            oRefCode <-as.integer(refData2$Orpha_Kode[j])
            oRefList <- append( oRefList,oRefCode)
          }
          if ( !is.element(oCode, oRefList))
          {
            msg<- paste("ICD10-Orpha combination:" , iCode,"-", oCode ,  "is implausible according to Alpha-ID-SE.",  env$dq[,cl][i])
            env$dq[,cl][i] <- msg
          }
          else k1_rd_counter=k1_rd_counter+1
        }
        else{
          if (!(is.null(iCode) |is.na(iCode) | is.empty(iCode))){
            k1_check_counter =k1_check_counter+1
            oRef<- which(as.character (refData2$Orpha_Kode)==oCode)
            if (!is.empty ( oRef)){
              msg<- paste("ICD10-Orpha combination:" , iCode,"-", oCode ,  "is implausible according to Alpha-ID-SE.",  env$dq[,cl][i])
              env$dq[,cl][i] <- msg
            }
          }
        }
      }
    }
  }
  out <- list()
  out[["k1_rd_counter"]] <- k1_rd_counter
  out[["k1_check_counter"]] <- k1_check_counter
  out
}

#' @title checkOutlier
#' @description This function checks the loaded data for outliers
#'
checkOutlier<-function (ddata, item, cl) {
  item.vec <- env$medData[[item]]
  index = which(ddata$basicItem==item)[1]
  if (!is.empty (env$ddata$engLabel)) name <- env$ddata$engLabel[index]
  else name<- item
  if(!is.empty(item.vec)){
    item.vec <-  as.Date(ISOdate(env$medData[[item]], 1, 1))
    out <- getDateOutlier(item.vec)
    if (!is.empty(out)) {
      ddata<- addOutlier (item, ddata, length(out), length(item.vec))
      for(i in out) {
        env$dq[,cl][i] <- paste( "Implausible", name , item.vec[i], "date in the future.")
      }
    }   else ddata <- addOutlier(item, ddata, 0,length(item.vec))

    if(item == "Geburtsdatum")
    {
      item1.vec <-  as.Date(ISOdate(env$medData[["Geburtsdatum"]], 1, 1))
      now<- as.Date(Sys.Date())
      out<-getAgeMaxOutlier(item1.vec,  now, 105)
      if (!is.empty(out)) {
        ddata<- addOutlier (item, ddata, length(out), length(item1.vec) )
        for(i in out) env$dq[,cl][i] <- paste( "Implausible birthdate", item1.vec[i] , "maximal age 105.",  env$dq[,cl][i])
      }
    }

  }
  else if (item!="Total"){
    ddata <- addOutlier(item, ddata, 0,0)
  }
  ddata
}

#' @title addD2
#' @description This function adds indicators and key numbers for the plausibility dimension (D2)
#'
addD2<- function ( tdata,  se, n) {
  if(se>0 & n >0){
    tdata$icdOrpha_no <- n
    tdata$plausible_icdOrpha_no<- se
    tdata$implausible_codeLink_no<- n-se
    or <- ( se/n) * 100
    tdata$orphaCoding_plausibility_rate <- round(or,2)
  }
  else {
    tdata$icdOrpha_no <- 0
    tdata$plausible_icdOrpha_no <- 0
    tdata$implausible_codeLink_no<- 0
    tdata$orphaCoding_plausibility_rate<-NA
  }
  tdata
}

#------------------------------------------------------------------------------------------------------
# functions for D3 uniqueness dimension
#------------------------------------------------------------------------------------------------------

#' @title checkD3
#' @description This function checks the quality of loaded data regarding uniqueness dimension (D3)
#'
checkD3 <- function (refData1, refData2, cl){
  if (is.null(env$medData$ICD_Primaerkode)) out <-checkUniqueOrphaCoding(cl)
  else if (!is.null(env$medData$Orpha_Kode)) out <-checkUniqueIcdOrphaCoding(refData1, refData2, cl)
       else out <- checkUniqueIcd(refData1, cl)
  out
}
#' @title checkUniqueIcd
#' @description This function checks the uniqueness of SE cases coded using ICD-10
#' @import stringi
#'
checkUniqueIcd <- function (refData1, cl){
  env$dq$rdCase <-NA
  env$dq$CheckedRdCase <- NA
  env$dq$unambiguous_rdCase <-NA
  env$dq$ambiguous_tracer <-NA
  env$dq$tracer <-NA
  eList <-refData1[which(refData1$Unique_SE=="yes"),]
  #eList <-refData1[(which(refData1$Type=="1:1" | refData1$Type=="n:1")),]
  k3_check_counter =0
  k3_rd_counter=0
  rd_counter=0
  if(!is.empty(env$medData$ICD_Primaerkode)){
  iList <-which(env$medData$ICD_Primaerkode !="" & !is.na(env$medData$ICD_Primaerkode)  & !is.empty(env$medData$ICD_Primaerkode))
  for(i in iList){
    iCode <- stri_trim(as.character(env$medData$ICD_Primaerkode[i]))
      if (is.element(iCode, stri_trim(as.character(eList$IcdCode))))
      {
        k3_rd_counter=k3_rd_counter+1
        k3_check_counter =k3_check_counter+1
        env$dq$CheckedRdCase[i] <- "yes"
        env$dq$unambiguous_rdCase[i] = "yes"
        env$dq$rdCase[i] = "yes"
        env$dq$tracer[i] <-"yes"
      }
      else {
        mList <-refData1[(which(refData1$Unique_SE=="no")),]
        iRefList<- which(stri_trim(as.character (mList$IcdCode))==iCode)
        if (!is.empty (iRefList)){
          env$dq$rdCase[i] <-"yes"
          env$dq$tracer[i] <-"yes"
          env$dq$ambiguous_tracer[i] <-"yes"
          #msg<- paste("ICD10 Kodierung",iCode, "ist nicht eindeutig. ICD10-Orpha Relation ist gemäß Tracer-Diagnosenliste vom Typ 1-m. ",  env$dq[,cl][i])
         # msg<- paste("ICD10 Code",iCode, "ist nicht eindeutig.",  env$dq[,cl][i])
          msg<- paste("Ambiguous ICD10 Code",iCode, ". Missing Orpha Code.",  env$dq[,cl][i])
          env$dq[,cl][i] <- msg
          k3_check_counter =k3_check_counter+1
          env$dq$CheckedRdCase[i] <- "yes"

        }
      }
    }
  }

  rd <-env$dq[ which (env$dq$rdCase=="yes"),]
  aRd <-env$dq[ which(env$dq$unambiguous_rdCase=="yes"),]
  checkedRd <-env$dq[ which (env$dq$CheckedRdCase=="yes"),]
  tracer <-env$dq[ which (env$dq$tracer=="yes"),]
  env$tdata$tracerCase_no <- length (unique(tracer$Aufnahmenummer))
  ambigTracer <-env$dq[ which (env$dq$ambiguous_tracer=="yes"),]
  env$tdata$ambiguous_tracerCase_no <- length (unique(ambigTracer$Aufnahmenummer))
  out <- list()
  out[["k3_unambiguous_rdDiag_no"]] <- length(aRd$Aufnahmenummer)
  out[["k3_unambiguous_rdCase_no"]] <- length (unique(aRd$Aufnahmenummer))
  out[["k3_checkedRdCase_no"]] <-  length (unique(checkedRd$Aufnahmenummer))
  out
}

#' @title checkUniqueOrphaCoding
#' @description This function checks the uniqueness of RD cases coded with Orpha numbers
#'
checkUniqueOrphaCoding <- function (cl){
  oList <-which(env$medData$Orpha_Kode !="" & !is.na(env$medData$Orpha_Kode)  & !is.empty(env$medData$Orpha_Kode)& !is.null(env$medData$Orpha_Kode))
  for (i in oList)
  {
    code <-env$medData$Orpha_Kode[i]
    oCode <-as.numeric(as.character(env$medData$Orpha_Kode[i]))
    if (!is.na(oCode)) {
      env$dq$CheckedRdCase[i] <- "yes"
      env$dq$unambiguous_rdCase[i] = "yes"
      env$dq$rdCase[i] = "yes"
    }
    else env$dq[,cl][i] <- paste("Ambiguous Case.",env$dq[,cl][i] )

  }

  out <- list()
  rd <-env$dq[ which (env$dq$rdCase=="yes"),]
  aRd <-env$dq[ which (env$dq$unambiguous_rdCase=="yes"),]
  checkedRd <-env$dq[ which (env$dq$CheckedRdCase=="yes"),]
  out <- list()
  out[["k3_unambiguous_rdDiag_no"]] <- length(aRd$Aufnahmenummer)
  out[["k3_unambiguous_rdCase_no"]] <- length (unique(aRd$Aufnahmenummer))
  out[["k3_checkedRdCase_no"]] <-  length (unique(checkedRd$Aufnahmenummer))

  out
  }

#' @title checkUniqueIcdOrphaCoding
#' @description This function checks the uniqueness of RD cases coded with ICD-Orpha mapping
#' @import stringi
#'
checkUniqueIcdOrphaCoding <- function (refData1, refData2, cl){
  env$dq$rdCase <-NA
  env$dq$CheckedRdCase <- NA
  env$dq$unambiguous_rdCase <-NA
  env$dq$ambiguous_tracer <-NA
  #eList <-refData1[(which(refData1$Type=="1:1" | refData1$Type=="n:1")),]
  k3_check_counter =0
  k3_rd_counter=0

  if(!is.empty(env$medData$ICD_Primaerkode)){
    cq <- which(env$medData$ICD_Primaerkode=="" | is.na(env$medData$ICD_Primaerkode) | is.empty(env$medData$ICD_Primaerkode))
    #env$cdata <- addMissing("ICD_Primaerkode", env$cdata, length (cq), length(env$medData$ICD_Primaerkode))
    if (!is.empty (cq)) for(i in cq) {
      env$dq[,cl][i]<- paste("Missing ICD-Code. ", env$dq[,cl][i])
      code <- env$medData$Orpha_Kode[i]
      if (! (is.na(code) || is.null(code) || is.empty(code))){
        oCode <-as.numeric(as.character(env$medData$Orpha_Kode[i]))
        #SE-Fälle
        if (!is.na(oCode)) {
          k3_rd_counter=k3_rd_counter+1
          env$dq$rdCase[i] <- "yes"
          env$dq$unambiguous_rdCase [i] = "yes"
          k3_check_counter =k3_check_counter+1
          env$dq$CheckedRdCase[i] <- "yes"
        }
        else{
          env$dq[,cl][i] <- paste("Ambiguous Case.",env$dq[,cl][i] )
         # env$dq[,cl][i] <- paste("Orpha Code",code, "ist nicht valide. ", env$dq[,cl][i] )
        }
      }
    }
    iList <-which(env$medData$ICD_Primaerkode !="" & !is.na(env$medData$ICD_Primaerkode)  & !is.empty(env$medData$ICD_Primaerkode))
    for(i in iList){
      iCode <- stri_trim(as.character(env$medData$ICD_Primaerkode[i]))
      numIcd <-as.numeric(iCode)
      if (!(is.null(iCode) |is.na(iCode) | is.empty(iCode))){
         if ( !is.na(numIcd))
          {
             # nicht valid
             msg<- paste("Invalid ICD code.",  numIcd, env$dq[,cl][i])
             env$dq[,cl][i] <- msg
         }
        else {
          oCode <-env$medData$Orpha_Kode[i]
          numCode <-as.numeric(as.character(env$medData$Orpha_Kode[i]))
          if (!(is.null(oCode) |is.na(oCode) | is.empty(oCode))){
            if ( is.na(numCode))
            {
              # nicht valid
              msg<- paste("Ambiguous Orphacoding.",  env$dq[,cl][i])
              env$dq[,cl][i] <- msg
              
            }
            else {
              
              iRefList<- which(stri_trim(as.character(refData2$ICD_Primaerkode1))==iCode)
              if (!is.empty (iRefList)){
                oRefList <- ""
                k3_check_counter =k3_check_counter+1
                env$dq$CheckedRdCase[i] <- "yes"
                
                for (j in iRefList){
                  oRefCode <-as.integer(refData2$Orpha_Kode[j])
                  oRefList <- append( oRefList,oRefCode)
                }
                if ( !is.element(numCode, oRefList))
                {
                  msg<- paste("Ambiguous Orphacoding.",  env$dq[,cl][i])
                  # msg<- paste("Kodierung ist nicht eindeutig. Relation",iCode,"-", oCode , "ist im BfArM nicht vorhanden. ",  env$dq[,cl][i])
                  env$dq[,cl][i] <- msg
                }
                else { k3_rd_counter=k3_rd_counter+1
                env$dq$rdCase[i] <- "yes"
                env$dq$unambiguous_rdCase [i] = "yes"
                }
              }
              else{
                if (!(is.null(iCode) |is.na(iCode) | is.empty(iCode))){
                  k3_check_counter =k3_check_counter+1
                  env$dq$CheckedRdCase[i] <- "yes"
                  oRef<- which(as.numeric(as.character(refData2$Orpha_Kode))==numCode)
                  if (!is.empty ( oRef)){
                    msg<- paste("Ambiguous Coding.",  env$dq[,cl][i])
                    #msg<- paste("Kodierung ist nicht eindeutig. ICD10 Code",iCode , "ist im BfArM Mapping nicht enthalten. ",  env$dq[,cl][i])
                    env$dq[,cl][i] <- msg
                  }
                }
              }
              
            }
            
          }
          else{
            eList <-refData1[(which(refData1$Unique_SE=="yes")),]
            if (is.element(iCode, stri_trim(as.character(eList$IcdCode))))
            {
              k3_rd_counter=k3_rd_counter+1
              k3_check_counter =k3_check_counter+1
              env$dq$CheckedRdCase[i] <- "yes"
              env$dq$rdCase[i] = "yes"
              env$dq$unambiguous_rdCase [i] = "yes"
            }
            else {
              mList <-refData1[(which(refData1$Unique_SE=="no")),]
              iRefList<- which(stri_trim(as.character (mList$IcdCode))==iCode)
              if (!is.empty (iRefList)){
                env$dq$rdCase[i] = "yes"
                k3_check_counter =k3_check_counter+1
                env$dq$CheckedRdCase[i] <- "yes"
                env$dq$ambiguous_tracer[i] <-"yes"
                # msg<- paste("ICD10 Kodierung",iCode, "ist nicht eindeutig. ICD10-Orpha Relation ist gemäß Tracer-Diagnosenliste vom Typ 1-m. ",  env$dq[,cl][i])
                msg<- paste("Ambiguous ICD10 Code",iCode, ".",  env$dq[,cl][i])
                env$dq[,cl][i] <- msg
              }
            }
          }
          
        }
      }
  
    }
  }

  rd <-env$dq[ which (env$dq$rdCase=="yes"),]
  aRd <-env$dq[ which (env$dq$unambiguous_rdCase=="yes"),]
  checkedRd <-env$dq[ which (env$dq$CheckedRdCase=="yes"),]
  ambigTracer <-env$dq[ which (env$dq$ambiguous_tracer=="yes"),]
  env$tdata$ambiguous_tracerCase_no <- length (unique(ambigTracer$Aufnahmenummer))
  out <- list()
  out[["k3_unambiguous_rdDiag_no"]] <- length(aRd$Aufnahmenummer)
  out[["k3_unambiguous_rdCase_no"]] <- length (unique(aRd$Aufnahmenummer))
  out[["k3_checkedRdCase_no"]] <-  length (unique(checkedRd$Aufnahmenummer))
  out

}

#' @title addD3
#' @description This function adds indicators and key numbers for uniqueness dimension (D3)
#'
addD3<- function (tdata, uRdDiag,  uRdCase, checkNo) {
  if(checkNo >0){
    tdata$unambiguous_rdCase_no <- uRdCase
    tdata$rdCase_no<- checkNo
    tdata$ambiguous_rdCase_no <-checkNo- uRdCase
    ur <- ( uRdCase/checkNo) * 100
    tdata$rdCase_unambiguity_rate <- round (ur,2)
    tdata$unambiguous_rdDiagnosis_no<- uRdDiag
    tdata$duplication_rate <- round((tdata$duplicateCase_no/(tdata$case_no+tdata$duplicateCase_no))*100,2)
    tdata$case_dissimilarity_rate <- 100-tdata$duplication_rate
    tdata$duplicated_rdCase_rate <- round((tdata$duplicateRdCase_no/(checkNo+tdata$duplicateRdCase_no))*100, 2)
    tdata$rdCase_dissimilarity_rate <-  100-tdata$duplicated_rdCase_rate
  }
  else {
    tdata$unambiguous_rdCase_no <- 0
    tdata$rdCase_no <- 0
    tdata$rdCase_unambiguity_rate<- 0
    tdata$unambiguous_rdDiagnosis_no<- 0
    tdata$ambiguous_rdCase_no <- NA
    env$tdata$duplication_rate <- NA
    tdata$rdCase_dissimilarity_rate <- NA
    tdata$duplicated_rdCase_rate <-NA
    tdata$case_dissimilarity_rate <-NA
  }
  tdata
}

#------------------------------------------------------------------------------------------------------
# functions for concordance dimension (D4)
#------------------------------------------------------------------------------------------------------
#' @title checkD4
#' @description This function checks the quality of loaded data regarding the concordance dimension (D4)
#'
checkD4 <- function (cl) {
  iList <-which(env$medData$ICD_Primaerkode !="" & !is.na(env$medData$ICD_Primaerkode)  & !is.empty(env$medData$ICD_Primaerkode))
  k4_counter_icd= length(iList)
  if (!is.null(env$medData$Orpha_Kode)){
    k4_counter_orpha = getOrphaCodeNo (cl)
    k4_counter_orphaCase =getOrphaCaseNo(cl)
  }
  else { k4_counter_orpha=0
    k4_counter_orphaCase =0
  }
  out <- list()
  out[["k4_counter_icd"]] <- k4_counter_icd
  out[["k4_counter_orpha"]] <- k4_counter_orpha
  out[["k4_counter_orphaCase"]] <- k4_counter_orphaCase
  out
}

#' @title getOrphaCaseNo
#' @description This function calculates the number of Orpha cases
#'
getOrphaCaseNox <- function (cl) {
  orphaCaseNo =0
  dup<-env$medData[(duplicated(env$medData[c("Aufnahmenummer")]) | duplicated(env$medData[c("Aufnahmenummer")], fromLast=TRUE))&is.na(env$medData$Orpha_Kode),]
  if (nrow(dup)>0)
  {
    medData<-env$medData[!(duplicated(env$medData[c("Aufnahmenummer")], fromLast=TRUE)&is.na(env$medData$Orpha_Kode)),]
    medData<-medData[!duplicated(env$medData[c("Aufnahmenummer")]),]

  }
  else medData<- env$medData[!duplicated(env$medData[c("Aufnahmenummer")]),]
  oList <-which(medData$Orpha_Kode !="" & !is.na(medData$Orpha_Kode)  & !is.empty(medData$Orpha_Kode) & !is.null(medData$Orpha_Kode))
  if (!is.empty (oList)) for(i in oList) {
    code <-medData$Orpha_Kode[i]
    oCode <-as.numeric(as.character(medData$Orpha_Kode[i]))
    if (!is.na(oCode))  orphaCaseNo =  orphaCaseNo +1
    else env$dq[,cl][i] <- paste("Invalid Orpha code",code, env$dq[,cl][i] )
  }
  orphaCaseNo
}

getOrphaCaseNo<- function (cl){
  env$dq$orphaCase <- NA
  orphaCaseNo =0
  oList <-which(env$medData$Orpha_Kode !="" & !is.na(env$medData$Orpha_Kode)  & !is.empty(env$medData$Orpha_Kode)& !is.null(env$medData$Orpha_Kode))
  for (i in oList)
  {
    code <-env$medData$Orpha_Kode[i]
    oCode <-as.numeric(as.character(env$medData$Orpha_Kode[i]))
    if (!is.na(oCode)) env$dq$orphaCase[i] = "yes"
    #else env$dq[,cl][i] <- paste("Orpha Code",code, "ist nicht valide. ", env$dq[,cl][i] )

  }
  oc <-env$dq[ which (env$dq$orphaCase=="yes"),]
  orphaCaseNo <- length (unique(oc$Aufnahmenummer))
  orphaCaseNo
}

#' @title getOrphaCodeNo
#' @description This function calculates the number of Orpha codes
#'
getOrphaCodeNo <- function (cl) {
  k4_counter_orpha =0
  oList <-which(env$medData$Orpha_Kode !="" & !is.na(env$medData$Orpha_Kode)  & !is.empty(env$medData$Orpha_Kode) & !is.null(env$medData$Orpha_Kode))
  if (!is.empty (oList)) for(i in oList) {
    code <-env$medData$Orpha_Kode[i]
    oCode <-as.numeric(as.character(env$medData$Orpha_Kode[i]))
    if (!is.na(oCode)) k4_counter_orpha = k4_counter_orpha +1
    else env$dq[,cl][i] <- paste("Invalid Orpha code.",code, env$dq[,cl][i] )
  }
  k4_counter_orpha
}

#' @title addD4
#' @description This function adds indicators and key numbers for the concordance dimension (D4)
#'
addD4<- function (tdata,orpha,orphaCase, uRd, inPtCase) {
   if (! (is.empty(tdata$report_year) | is.na(tdata$report_year)))
    {
      tdata$patient_no_py <-tdata$patient_no
      tdata$case_no_py <- tdata$case_no
      tdata$rdCase_no_py <- tdata$rdCase_no
      tdata$tracerCase_no_py <- tdata$tracerCase_no
      tdata$case_no_py_ipat <-inPtCase
      tdata$orphaCoding_no_py <- orpha
      tdata$orphaMissing_no_py <- tdata$orphaMissing_no
      tdata$implausible_codeLink_no_py <- tdata$implausible_codeLink_no
      tdata$missing_value_no_py <- tdata$missing_value_no
      tdata$missing_item_no_py <- tdata$missing_item_no
      tdata$outlier_no_py <- tdata$outlier_no
      tdata$duplicateCase_no_py <-tdata$duplicateCase_no
      tdata$duplicateRdCase_no_py <-tdata$duplicateRdCase_no
      tdata$ambiguous_rdCase_no_py <- tdata$ambiguous_rdCase_no

      rd <- (tdata$rdCase_no_py/inPtCase) * 100000
      tdata$rdCase_rel_py_ipat  <-  round (rd,0)
      tracer <- (tdata$tracerCase_no_py/inPtCase) * 100000
      tdata$tracerCase_rel_py_ipat  <-  round (tracer,0)

      tdata$case_no <-NULL
      tdata$patient_no <- NULL
      tdata$rdCase_no <-NULL
      tdata$case_no <-NULL
      tdata$tracerCase_no <-NULL
      tdata$missing_item_no <-NULL
      tdata$missing_value_no <- NULL
      tdata$outlier_no <- NULL
      tdata$duplicateCase_no <-NULL
      tdata$orphaMissing_no <- NULL
      tdata$implausible_codeLink_no<-NULL
      tdata$duplicateRdCase_no <-NULL
      tdata$ambiguous_rdCase_no <- NULL

      if(orphaCase>0){
        tdata$orphaCase_no_py <-orphaCase
        or <- ( orphaCase/inPtCase) * 100000
        tdata$orphaCase_rel_py_ipat   <- round (or,0)
        #tdata$orphaCase_rel_py  <- getPercentFormat(or)

      }
      else {
        tdata$orphaCase_rel_py_ipat  <- 0
        tdata$orphaCase_no_py <- 0
      }
      if(uRd>0){
        tdata$unambiguous_rdCase_no_py <-uRd
        rf <- ( uRd/inPtCase) * 100
        tdata$unambiguous_rdCase_rel_py_ipat <- round (rf,2)
      }
      else {
        tdata$unambiguous_rdCase_no_py <- 0
        tdata$unambiguous_rdCase_rel_py_ipat <- 0
      }

   }

  tdata
}
#' @title getConcWithRefValues
#' @description This function evaluates the concordance of tracer cases with reference values from the literature of national references
#'
getConcWithRefValues <- function(tracerCase_rel_py_ipat, concRef){
  conc =NA
  if (is.integer(tracerCase_rel_py_ipat) | is.double(tracerCase_rel_py_ipat))
  {
    if (concRef[["min"]] <= tracerCase_rel_py_ipat && tracerCase_rel_py_ipat<=concRef[["max"]] ) conc=1
    else conc =0
  }
 
  #env$tdata$conc_with_refValues =conc
  conc
}

#' @title getConcIndicator
#' @description This function calculates the z-score value to measure concordance indicators such as the concordance of RD cases or the concordance of tracer cases
#' @import stats
#'
getConcIndicator <- function(dist, index){
  concInd <-round (((dist[index]- mean(dist))/sd(dist)),2)
  concInd
}


#------------------------------------------------------------------------------------------------------
# Functions to generate data quality reports
#------------------------------------------------------------------------------------------------------
#' @title geReport
#' @description This function generates data quality reports about detected quality issues, user selected indicators and key numbers
#' @import openxlsx utils
#' @export
#'
getReport <- function (repCol, cl, td, path) {
  repCol = append (repCol, cl)
  repData <-subset(env$dq, select= repCol)
  dfq <-repData[ which(env$dq[,cl]!="")  ,]
  dfq[nrow(dfq)+1,] <- NA
  dfq[nrow(dfq)+1,1] <- env$mItem
  sheets <- list("DQ_Report"=dfq, "DQ_Metrics" = td)
  write.xlsx(sheets, paste (path,".xlsx", sep =""))
  write.csv(td, paste (path,".csv", sep =""), row.names = FALSE)
  # env <-NULL
}

#' @title getExtendedReport
#' @description This function generates an extended data quality reports with infos about Projecathon use cases
#' @import openxlsx
#' @export
#'
getExtendedReport <- function ( repCol,cl, td, useCase, path) {
  repData <-subset(env$dq,select= repCol)
  dfq <-repData[ which(env$dq[,cl]!="")  ,]
  sheets <- list("DQ_Report"=dfq, "DQ_Metrics"= td, "Projectathon"=useCase)
  write.xlsx(sheets, path)
}
