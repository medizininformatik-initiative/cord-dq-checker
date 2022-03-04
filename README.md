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

## Note

Before starting `cordDqChecker.R` you need to install required libraries using this script [`installPackages.R`]( https://github.com/KaisTahar/cordDqChecker/blob/master/R/installPackages.R )

## Example

Here are [examples](https://github.com/KaisTahar/cordDqChecker/tree/master/Data/Export) of generated data quality reports using the cord test dataset

See also: [`CORD-MI`](https://www.medizininformatik-initiative.de/de/CORD)

