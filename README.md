# cordDqChecker
`CordDqChecker` is a Tool for data quality assessment and reporting in CORD

## Run cordDQCherker to genrate data quality reports

The skript `cordDqChecker.R` reads data from FHIR server or CSV and Excel files. The path varialbe specifies which dataset should be imported.
For Example you can define your path as following:
```path="http://141.5.101.1:8080/fhir/" ```
or
``` path="./Data/medData/dqTestData.csv" ```
or
``` path="./Data/medData/dqTestData.xlsx" ```

Once the source data path is defined, start the skript to check the quality of your data. 
The genrated repots are saved in folder ``` "./Data/Export" ```

## Data Quality Metrics

The following indicatos and key numbers are configured by default data quality report:

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
| case number  |   unique_no|
| unique rare disease number  |   orphaCoding_no|

## Note

Before starting `cordDqChecker.R` you need to install required libraries using this script [`installPackages.R`]( https://github.com/KaisTahar/cordDqChecker/blob/master/R/installPackages.R )

## Example

Here are [examples](https://github.com/KaisTahar/cordDqChecker/tree/master/Data/Export) of generated data quality reports using the cord test dataset

See also: [`CORD-MI`](https://www.medizininformatik-initiative.de/de/CORD)

