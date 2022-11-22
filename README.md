# cordDqChecker
`CordDqChecker` is a Tool for data quality assessment and reporting in [`CORD-MI`](https://www.medizininformatik-initiative.de/de/CORD).

Acknowledgement: This work was done within the “Collaboration on Rare Diseases” of the Medical Informatics Initiative (CORD-MI) funded by the German Federal Ministry of Education and Research (BMBF), under grant number: FKZ-01ZZ1911R.
## Data Quality Metrics
- The following indicators and key numbers are configured by default data quality reports:

  | Dimension  | Indicator Name|
  | ------------- | ------------- |
  | completeness  | missing_item_rate, missing_value_rate, orphaCoding_completeness_rate  |
  | plausibility  | outlier_rate, orphaCoding_plausibility_rate |
  | uniqueness | rdCase_unambiguity_rate, duplication_rate|
  | concordance | orphaCoding_rel_py_ipt, unambiguous_rdCase_rel_py_ipat, tracerCase_rel_py_ipat|


  | Key number  | Name |
  | ------------- | ------------- |
  | inpatient case number per year  |   case_no_p_ipat|
  | case number per year |  case_no_py|
  | patient number per year  |   patient_no_py|
  | orpha code number per year  |  orphaCoding_no_py |
  | RD case number per year  | rdCase_no_py  |
  | Orpha-coded case number per year| orphaCase_no_py |
  | unambiguous-RD case number per year | unambiguous_rdCase_no_py  |
- The data quality framework [`dqLib`](https://github.com/medizininformatik-initiative/dqLib) has been used as an R package for generating specific reports on data quality related issues and metrics.
- The following references are required to assess the quality of orphacoding and can be easily updated with new versions:
  - The standard Alpha-ID-SE terminology [1]
  - A reference for tracer diagnoses such as the list provided in [2].
  
    [1]   BfArM - Alpha-ID-SE [Internet]. [cited 2022 May 23]. Available from: https://www.bfarm.de/EN/Code-systems/Terminologies/Alpha-ID-SE/_node.html 
    
    [2]   List of Tracer Diagnoses Extracted from Alpha-ID-SE Terminology [Internet]. 2022 [cited 2022May 24]. Available from: https://doi.org/21.11101/0000-0007-F6DF-9 


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
  - ``` reportYear=2020 ```
  - ``` max_FHIRbundles=50 ```
  - ``` INPATIENT_CASE_NO=10000 ```
  - ```path="http://141.5.101.1:8080/fhir/"``` 
  - ```tracerPath="./Data/refData/CordTracerList_v2.csv"``` 


We use the CSV file `"./Local/Data/refData/CordTracerList_v2.csv"` as default reference for tracer diagnoses. We also provide the CORD-MI list of tracer diagnoses version 1.0 in the folder for reference data `"./Local/Data/refData/Export"`. Once the source data path and local variables are defined, start the script to check the quality of your data. The genrated repots are saved in folder `"./Local/Data/Export"`. 

## Local Reports
Here are some [examples](https://github.com/medizininformatik-initiative/cord-dq-checker/tree/master/Local/Data/Export) of data quality reports generated locally using sythetic data.

## Note

- Before starting `cordDqChecker.R` you need to install required libraries using this script [`installPackages.R`]( https://github.com/medizininformatik-initiative/cord-dq-checker/blob/master/Local/R/installPackages.R )

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

