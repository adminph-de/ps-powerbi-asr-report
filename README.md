## Azure Site Recovery (ASR) status analysis with PowerShell and PowerBI

This script package colects the real-time information of your Azure ASR setup and save the result to a CSV file.

Running the scripts requires the following modules installed:

  - AzureAz: https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-1.6.0
  
Buliding a PowerBI report out of the result, you need a valid License of Microsoft PowerBI: https://powerbi.microsoft.com

## HowTo Work with the scripts
Change the parameter in the script of your own needs and execute the script. Depending of how many Subscriptions and how many Backup Vaults with ASR enabled you have in your enviornment, the script running time can be between 5 minutes until up to a few hours. During the run, you will get updated infomration at wich point the script is doing its work.

*Execute:*
```.\GenerateAsrReport.ps1```

## Results after running the scripts
After a scucessfully run of the script, you will find all generated results (CSV files) in the defined folder.

The main file which contains all information (Level-1) is the CSV file:
This CSV file contains all the information of all ASR BackupVaults in all your Subscrioptions.

```AsrAnalysis_merged.csv```

If you need to analyse onle the results per Subscription (Level-2) you will find files wiht a naming pattern like this in your folder:

```[SubscriptionName]__merged.csv```

The information per ASR enabled BackupVault(Level-3) has the naming pattern:

```[SubscriptionName]__[BackupVaultName]__[FabricName].csv```

The amougnt of files is depending on how many ASR BackupVauls are working in your Subscriptions.

## PowerBI report
I put an example PowerBI report in the ``èxample``` folder. Including an example data export file. Feel free to try out your own report or extend the example report.

Keep in mind, you need a valid license to use PowerBI.

If you have questions, don't hesitate and get in touch with me.
