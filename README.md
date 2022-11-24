# cordDqChecker
`CordDqChecker` is a Tool for data quality assessment and reporting in [`CORD-MI`](https://www.medizininformatik-initiative.de/de/CORD).

Acknowledgement: This work was done within the “Collaboration on Rare Diseases” of the Medical Informatics Initiative (CORD-MI) funded by the German Federal Ministry of Education and Research (BMBF), under grant number: FKZ-01ZZ1911R.
## Data Quality Metrics
- The data quality framework [`dqLib`](https://github.com/KaisTahar/dqLib) has been used as an R package for generating specific reports on DQ related issues and metrics.
- The following DQ indicators and parameters are configured by default reports:
  | Dimension  | DQ Indicator | 
  | ------------- | ------------- |
  | completeness  | item completeness rate, value completeness rate, subject completeness rate, case completeness rate, orphaCoding completeness rate  | 
  | plausibility  | orphaCoding plausibility rate, range plausibility rate | 
  | uniqueness | RD case unambiguity rate, RD case dissimilarity rate |
  | concordance |concordance with reference values| 
  
  |DQ Parameter | Description |
  |-------------------------- | ------------|
  | inpatient cases |  number of inpatient cases per year |
  | inpatients |  number of inpatient per year |
  | RD cases | number of RD cases per year |
  | Orpha cases |  number of Orpha cases per year |
  | tracer cases |  number of tracer RD cases per year |
  | RD cases rel. frequency| relative frequency of inpatient RD cases per year per 100.000 cases|
  | Orpha cases rel. frequency| relative frequency of inpatient Orpha cases per year per 100.000 cases|
  | tracer cases rel. frequency| relative frequency of inpatient tracer RD cases per year per 100.000 cases|
  | missing mandatory data items |  number of missing data items per year |
  | missing mandatory data values| number of missing data values per year |
  | incomplete subjects |  number of incomplete inpatient records per year |
  | missing orphacodes |  number of missing Orphacodes per year |
  | outliers | number of detected outliers per year |
  | implausible links | number of implausible code links per year |
  | ambiguous RD cases | number of ambiguous RD cases per year |
  | duplicated RD cases |  number of duplicated RD cases per year |
  
- The following references are required to assess the quality of orphacoding and can be easily updated with new versions: (1) The standard Alpha-ID-SE terminology [1], and (2) a reference for tracer diagnoses such as the list provided in [2].
  
	[1]   BfArM - Alpha-ID-SE [Internet]. [cited 2022 May 23]. Available from: [BfArM](https://www.bfarm.de/EN/Code-systems/Terminologies/Alpha-ID-SE/_node.html) 
	
	[2]   Tahar K, Martin T, Mou Y, et al. Distributed Data Quality Assessment Across CORD-MI Consortia. [doi:10.3205/22gmds116](https://www.egms.de/static/en/meetings/gmds2022/22gmds116.shtml)
	
## Local Execution
To analyse your data quality locally go to folder `./Local` and run `cordDqChecker.R` to genrate data quality reports.

- The script `cordDqChecker.R` reads data from FHIR server or from supported file formats such as CSV and Excel. The path varialbe specifies which dataset should be imported.
For Example you can define your path as following:
  - ```path="http://141.5.101.1:8080/fhir/" ```
  or
  - ``` path="./Data/medData/dqTestData.csv" ```
  or
  - ``` path="./Data/medData/dqTestData.xlsx" ```

- The default values of local variables are set as follows:
  - ``` institut_ID <- "meDIC_Standort ```
  - ``` path="http://141.5.101.1:8080/fhir/"``` 
  - ``` ipatCasesList=list ("2015"=800, "2016"=900, "2017"=940, "2018"=950, "2019"=990,  "2020"=997, "2021"=999, "2022"=1000)```
  - ``` reportYearStart=2015```
  - ``` reportYearEnd=2022 ```
  - ``` dateRef = “Entlassungsdatum” ```
  - ``` dateRefFormat="%Y-%m-%d" ```
  - ```tracerPath="./Data/refData/CordTracerList_v2.csv"``` 

We use the CSV file `"./Local/Data/refData/CordTracerList_v2.csv"` as default reference for tracer diagnoses. We also provide the CORD-MI list of tracer diagnoses version 1.0 in the folder for reference data `"./Local/Data/refData/Export"`. Once the source data path and local variables are defined, start the script to check the quality of your data. The genrated repots are saved in folder `"./Local/Data/Export"`. 

## Local Reports
Here are some [examples](https://github.com/medizininformatik-initiative/cord-dq-checker/tree/FDPG_study/Local/Data/Export) of data quality reports generated locally using sythetic data.

## Note

- Before starting `cordDqChecker.R` you need to install required libraries using this script [`installPackages.R`]( https://github.com/medizininformatik-initiative/cord-dq-checker/tree/FDPG_study/Local/R/installPackages.R )

- To avoid local dependency issues go to folder `./Local` and just run the command `sudo docker-compose up` to get `cordDqChecker` running.
- The missing item rate will be calculated based on FHIR [implementation guidlines of the MII core data set](https://www.medizininformatik-initiative.de/en/basic-modules-mii-core-data-set). Hence, mandatory items of the basic modules Person, Case and Diagnosis are required.

- To cite `cordDqChecker`, please use the following **BibTeX** entry: 
  ```
  @software{Tahar_cordDqChecker,
  author = {Tahar, Kais},title = {{cordDqChecker}},
  url = {https://github.com/medizininformatik-initiative/cord-dq-checker},
  year = {2021}
  }

  ```
See also:  [`dqLib`](https://github.com/medizininformatik-initiative/dqLib)  [`CORD-MI`](https://www.medizininformatik-initiative.de/de/CORD)

