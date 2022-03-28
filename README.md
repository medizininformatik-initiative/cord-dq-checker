# cordDqChecker
`CordDqChecker` is a Tool for data quality assessment and reporting in [`CORD-MI`](https://www.medizininformatik-initiative.de/de/CORD)

## Local Execution
To analyse your data quality locally go to folder `./Local` and run `cordDqChecker.R` to genrate data quality reports.

The script `cordDqChecker.R` reads data from FHIR server or from supported file formats such as CSV and Excel. The path varialbe specifies which dataset should be imported.
For Example you can define your path as following:
- ```path="http://141.5.101.1:8080/fhir/" ```
or
- ``` path="./Data/medData/dqTestData.csv" ```
or
- ``` path="./Data/medData/dqTestData.xlsx" ```

The FHIR server ```http://141.5.101.1:8080/fhir/``` is configured by default.
Once the source data path is defined, start the script to check the quality of your data.
The genrated repots are saved in folder ``` "./Local/Data/Export" ```

## Distributed Execution
`cordDqChecker` was successfully tested using [Personal Health Train (PHT)](https://websites.fraunhofer.de/PersonalHealthTrain/) and applied on synthetic data stored in multiple FHIR servers. The aggregated results are stored in folder `./PHT/Data/Export`. To create a PHT image run `./Dockerfile`.

## Data Quality Metrics
- The following indicators and key numbers are configured by default data quality reports:

  | Dimension  | Indicator Name|
  | ------------- | ------------- |
  | completeness  | missing_item_rate, missing_value_rate, orphaCoding_completeness_rate  |
  | plausibility  | outlier_rate, orphaCoding_plausibility_rate |
  | uniqueness | rdCase_uniqueness_rate|
  | concordance | orphaCoding_relativeFrequency, unique_rdCase_relativeFrequency|


  | Key number  | Name |
  | ------------- | ------------- |
  | patient number  |   patient_no|
  | case number  |  case_no|
  | RD case number  | rdCase_no  |
  | orpha code number  |  orphaCoding_no |
  | unique RD case number  | unique_rdCase_no  |


- The following references are currently used to assess the quality of orphacoding and can be easily updated with new codes or versions:
  - Alpha-ID-SE list [1]
  - Hamburger list [2] extended with 1-m relationships of ICD-10 to Orpha codes such as E75.2-(324, 487, 355, 512)

  [1] DIMDI/Alpha-ID-SE list: www.dimdi.de

  [2] Schulz M et alt:. Prävalenz seltener Erkrankungen in der ambulanten Versorgung in Deutschland im Zeitraum 2008 bis 2011, Versorgungsatlas-Bericht. 2015;15/13
  
## Examples of local data quality reports

Here are [examples](https://github.com/medizininformatik-initiative/cord-dq-checker/tree/master/Local/Data/Export) of generated data quality reports using sythetic data

## Note

Before starting `cordDqChecker.R` you need to install required libraries using this script [`installPackages.R`]( https://github.com/medizininformatik-initiative/cord-dq-checker/blob/master/Local/R/installPackages.R )

To cite `cordDqChecker`, please use the following **BibTeX** entry: 
```
@software{Tahar_cordDqChecker,
author = {Tahar, Kais},title = {{cordDqChecker}},
url = {https://github.com/medizininformatik-initiative/cord-dq-checker},
year = {2021}
}

```
See also: [`CORD-MI`](https://www.medizininformatik-initiative.de/de/CORD)

