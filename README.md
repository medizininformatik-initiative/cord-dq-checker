# <p align="center"> cordDqChecker </p>
## <p align="center"> Rare Diseases in German Health Information Systems – A set of Metrics and Tools for a German-wide Study on Distributed Data Quality Assessments </p>

To make sufficient data available for clinical research in rare diseases (RD), the research network “Collaboration on Rare Diseases” ([`CORD-MI`](https://www.medizininformatik-initiative.de/de/CORD)) of the Medical Informatics Initiative  ([`MII`](https://www.medizininformatik-initiative.de/en/start)) connects twenty four university hospitals in Germany. `CordDqChecker` contains the code version and all instructions used for conducting a German-wide study on distribued data quality (DQ) assessments within the CORD-MI research network. This repository therefore provides a set of metrics and tools for local as well as distributed DQ assessment and reporting on RDs.
 
Acknowledgement: This work was done within the “Collaboration on Rare Diseases” of the Medical Informatics Initiative (CORD-MI) funded by the German Federal Ministry of Education and Research (BMBF), under grant number: FKZ-01ZZ1911R.

## 1. Local Execution
We would like to note that the developed tool supports HL7 FHIR as well as file formats such as CSV or Excel. To conduct local DQ assessments, please follow the following instructions. 
1. clone reposistory and checkout branch FDPG_study
   - Run the git command: ``` git clone --branch FDPG_study https://github.com/medizininformatik-initiative/cord-dq-checker.git ```

2. Go to the folder `./Local` and edit the file `config.yml` with your local variables
   - Set your custom variables (v1...v5)
     - Define your organization name (v1) and data input path (v2). This variable specifies which data set should be imported. When importing CSV or Excel data formats,   please define the headers as specified in the examples stored in `Local/Data/medData`. You can, for example, define your path as following:
	   - ```path="http://141.5.101.1:8080/fhir/" ```
	  or
	   - ``` path="./Data/medData/dqTestData.csv" ```
	  or
	   - ``` path="./Data/medData/dqTestData.xlsx" ```

     - Set proxy and access configuration (v3) if required 
     - Set the number of inpatient case for each year (v4) as following:
  ``` inpatientCases_number: !expr list ("2015"=800, "2016"=900, "2017"=940, "2018"=950, "2019"=990,  "2020"=997, "2021"=999, "2022"=1000) ```
     - Set the corresponding code for filtering inpatient cases (v5) else default = NULL
   - Please change the variables v6 - v10 only if technical or legal restrictions otherwise prevent successful execution! In this context we would like to note that we use the CORD-MI list of diagnoses version 2.0 (=v2) as a default reference for required diagnoses (see v9). We additionally provide the list of diagnoses version 1.0 as CSV file if required due to local restrictions (=v1). The reference Lists for required diagnoses are stored in the folder `./Local/Data/refData` 

3. Once the source data path and local variables are defined, start the script using this command: ```Rscript cordDqChecker.R ``` to assess the quality of your data. You can also run this script using Rstudio or Dockerfile. To avoid local dependency issues just run the command ```sudo docker-compose up``` in the folder `./Local` to get the script running

4. The script generates two files per year analyzed – the first one is a CSV file that contains the calculated DQ metrics, while the second file is an Excel file that contains a report on DQ violations. To enable users to find the DQ violations and causes of these violations, this report provides sensitive information such as Patient Identifier (ID) or case ID – it is meant for internal use only. The generated reports are saved in the folder `./Local/Data/Export`. To share the CSV files about DQ metrics please follow the instruction provided in section 2

**Note:** To enable cross-site reporting, please share with us the first report of each year (CSV files) that only contains aggregated results on DQ metrics. Please don’t share the reports about DQ violations (Excel files) to meet the data privacy requirements.

## 2. Cross-Site reporting
To enable cross-site reporting on DQ in CORD-MI we provide an encrypted cloud environment for sharing the locally generated DQ reports with the Data Management Office in Göttingen. Please follow the following instruction to share the local reports on DQ metrics.

1. Go to [`Cryptshare`](https://cryptshare.med.uni-goettingen.de)
2. Click on “Provide” and follow the wizard to share the local DQ reports. The Email address of the recipient is: Kais.Tahar@med.uni-goettingen.de
3. After having shared the transfer, Kais Tahar will contact you to get the password

**Note:** For more information on Cryptshare, see the following [`User Manual`](https://wiki.cryptshare.com/w/CSSCurrent_en:User_Manual).

## 3. Examples of Local Reports
Here are some [examples](https://github.com/medizininformatik-initiative/cord-dq-checker/tree/FDPG_study/Local/Data/Export) of data quality reports generated locally using sythetic data.	

## 4. Data Quality Metrics
- The data quality framework [`dqLib`](https://github.com/KaisTahar/dqLib) has been used as an R package for generating specific reports on DQ related issues and metrics. The used version of `dqLib` is availabe in the folder `./Local/R`.
- The following DQ indicators and parameters are configured by default reports:
  | Dimension  | DQ Indicator | 
  | ------------- | ------------- |
  | completeness  | item completeness rate, value completeness rate, subject completeness rate, case completeness rate, orphaCoding completeness rate  | 
  | plausibility  | orphaCoding plausibility rate, range plausibility rate | 
  | uniqueness | RD case unambiguity rate, RD case dissimilarity rate |
  | concordance |concordance with reference values| 
  
  |DQ Parameter | Description |
  |-------------------------- | ------------|
  | inpatient cases |  number of inpatient cases per year in a given hospital |
  | RD inpatients |  number of RD inpatient per year in a given data set |
  | Orpha inpatients |  number of Orpha inpatient per year in a given data set |
  | RD cases | number of RD cases per year in a given data set |
  | Orpha cases |  number of Orpha cases per year in a given data set |
  | tracer cases |  number of tracer RD cases per year in a given data set |
  | RD cases rel. frequency| relative frequency of inpatient RD cases per year per 100.000 cases|
  | Orpha cases rel. frequency| relative frequency of inpatient Orpha cases per year per 100.000 cases|
  | tracer cases rel. frequency| relative frequency of inpatient tracer RD cases per year per 100.000 cases|
  | missing mandatory data items |  number of missing data items per year in a given data set |
  | missing mandatory data values| number of missing data values per year in a given data set |
  | incomplete subjects |  number of incomplete inpatient records per year in a given data set |
  | orphacodes |  number of Orphacodes per year in a given data set |
  | missing orphacodes |  number of missing Orphacodes per year in a given data set |
  | outliers | number of detected outliers per year in a given data set |
  | implausible links | number of implausible code links per year in a given data set |
  | ambiguous RD cases | number of ambiguous RD cases per year in a given data set |
  | duplicated RD cases |  number of duplicated RD cases per year in a given data set |
  
- The following references are required to assess the quality of orphacoding and can be easily updated with new versions: (1) The standard Alpha-ID-SE terminology [1], and (2) a reference for tracer diagnoses such as the list provided in [2]. The used version of Alpha-ID-SE and tracer diagnoses (see `config.yml`) are also stored in the folder for references `./Local/Data/refData` 
  
	[1]   BfArM - Alpha-ID-SE [Internet]. [cited 2022 May 23]. Available from: [BfArM](https://www.bfarm.de/EN/Code-systems/Terminologies/Alpha-ID-SE/_node.html) 
	
	[2]   Tahar K, Martin T, Mou Y, et al. Distributed Data Quality Assessment Across CORD-MI Consortia. [doi:10.3205/22gmds116](https://www.egms.de/static/en/meetings/gmds2022/22gmds116.shtml)


## 5. Note

-  You can also run `cordDqChecker` using Rstudio or Dockerfile. When using Rstudio, all required packages should be installed automatically using the script [`installPackages.R`]( https://github.com/medizininformatik-initiative/cord-dq-checker/tree/FDPG_study/Local/R/installPackages.R ). We would like to note that the `fhircrackr` package is only required to run local DQ assessments on FHIR data. To avoid local dependency issues go to folder `./Local` and just run the command `sudo docker-compose up` to get `cordDqChecker` running

- The missing item rate will be calculated based on FHIR [implementation guidlines of the MII core data set](https://www.medizininformatik-initiative.de/en/basic-modules-mii-core-data-set). Hence, mandatory items of the basic modules Person, Case and Diagnosis are required

- To cite `cordDqChecker`, please use the following **BibTeX** entry: 
  ```
  @software{Tahar_cordDqChecker,
  author = {Tahar, Kais},title = {{cordDqChecker}},
  url = {https://github.com/medizininformatik-initiative/cord-dq-checker},
  year = {2021}
  }

  ```
See also: [`CORD-MI`](https://www.medizininformatik-initiative.de/de/CORD)

