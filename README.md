# cordDqChecker
`CordDqChecker` is a Tool for data quality assessment and reporting in CORD

## Run cordDQCherker to genrate data quality reports

The skript `CordDqChecker.R` reads data from FHIR server or CSV and Excel files. The path varialbe specifies which dataset should be imported.
For Example you can define your path as following:
```path="http://141.5.101.1:8080/fhir/" ```
or
``` path="./Data/medData/dqTestData_KT.csv" ```
or
``` path="./Data/medData/dqTestData_KT.xlsx" ```

Once the source data path is defined, start the skript to check the data quality of your CORD dataset. 
The genrated repots are saved in folder ``` "./Data/Export" ```

## Note
`dqlib` libery needs to be installed

You can install `dqLib` from github with:
``` r
install_github("https://github.com/KaisTahar/dqLib")
```

## Note
`dqlib` libery needs to be installed

You can install `dqLib` from github with:
``` r
install_github("https://github.com/KaisTahar/dqLib")
```

## Example

Here are [examples](https://github.com/KaisTahar/cordDqChecker/tree/master/Data/Export) of generated data quality reports using the cord test dataset

See also: [`CORD-MI`](https://www.medizininformatik-initiative.de/de/CORD)

