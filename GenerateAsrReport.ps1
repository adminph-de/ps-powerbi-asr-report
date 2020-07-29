<#
 .SYNOPSIS
    Collects information out of Azure Site Recovery (ASR) into a CVS file.
    By: Patrick Hayo (patrick.hayo@icloud.com)
    Revision: 1.0 
    Data: 2019-03-27

 .DESCRIPTION
    Executable on PowerShell Command Line. 
    Prerequtements: PowerShell, AzureAz Module
    Optional to analyse the data: Microsoft Excel and PowerBI

 .PARAMETER CsvPath
    Destination Directory for the output of the Script.

 .PARAMETER AzSubList
    List of Azure Subscriptions, comma seperated.
#>

#Output Root Path
$CsvPath = "C:\DRIVERS\"
#List of Subscriptions to analyse the ASR Backup Vaults (Comma seperated if more than one)
$AzSubList = @("FLS GBS Azure Subscription","GBS Production", "GBS Testing")

<# ----- DO NOT CHANGE BELOW THIS LINE -----#>

#Generates the current data and time
$CurrentDate = (Get-Date -format "yyyy-MM-dd_hh-mm-ss")

#Create a new directory and set it as active
Set-Location $CsvPath
if (!(Test-Path ($CsvPath + "\" + $CurrentDate))) {
    New-Item -ItemType Directory -Path $CurrentDate
}
Set-Location ($CsvPath + $CurrentDate)
$RootPathName = ((Get-Location).Path + "\")

Function Merge-CsvFiles($dir, $OutFile, $Pattern) {
 # Build the file list
 $FileList = Get-ChildItem $dir -include $Pattern -rec -File | where {$_.Length -ne 0kb}
 # Get the header info from the first file
 Get-Content $fileList[0] | Select-Object -First 1 | Out-File -FilePath $outfile -Encoding ascii
 # Cycle through and get the data (sans header) from all the files in the list
 foreach ($file in $filelist)
 {
   Get-Content $file | Select-Object -Skip 1 | Out-File -FilePath $outfile -Encoding ascii -Append
 }
}

foreach ($AzSub in $AzSubList) {
    Select-AzSubscription $AzSub
    $RecVaults = Get-AzResource -ResourceType Microsoft.RecoveryServices/vaults
    foreach ($RecVault in $RecVaults) {
        $vault = Get-AzureRmRecoveryServicesVault -Name $RecVault.Name -ResourceGroupName $RecVault.ResourceGroupName
        Set-ASRVaultContext -Vault $Vault
        $ASRFabrics = Get-ASRFabric 
        if ($ASRFabrics.count -ne 0) {
            $ProtectionContainer = Get-ASRProtectionContainer -Fabric $ASRFabrics[0]
            $AsrItems = Get-ASRReplicationProtectedItem -ProtectionContainer $ProtectionContainer 
            foreach ($AsrItem in $AsrItems) {
                $AsrObjId = $AsrItem | Select-Object -Property ID
                # Add ResourceGroup
                $RG = $AsrObjId.ID.Substring($AsrObjId.ID.IndexOf("resourceGroups"),$AsrObjId.ID.IndexOf("providers")-$AsrObjId.ID.IndexOf("resourceGroups"))
                $ResourceGroupe = $RG.Substring($RG.IndexOf("/")+1,$RG.Length-$RG.IndexOf("/")-2)
                $AsrItem | Add-Member -type NoteProperty -Name "ResourceGroup" -Value $ResourceGroupe
                # Add BackupVault
                $BV =  $AsrObjId.ID.Substring($AsrObjId.ID.IndexOf("vaults"),$AsrObjId.ID.IndexOf("replicationFabrics")-$AsrObjId.ID.IndexOf("vaults"))
                $BackupVault = $BV.Substring($BV.IndexOf("/")+1,$BV.Length-$BV.IndexOf("/")-2)
                $AsrItem | Add-Member -type NoteProperty -Name "BackupVault" -Value $BackupVault
                # Add SubscriptionID
                $SubId = $AsrObjId.ID.Substring($AsrObjId.ID.IndexOf("Subscriptions"),$AsrObjId.ID.IndexOf("resourceGroups")-$AsrObjId.ID.IndexOf("Subscriptions"))
                $SubscriptionId = $SubId.Substring($SubId.IndexOf("/")+1,$SubId.Length-$SubId.IndexOf("/")-2)
                $AsrItem | Add-Member -type NoteProperty -Name "SubscriptionId" -Value $SubscriptionId
                # Add SubscriptionName
                $AsrItem | Add-Member -type NoteProperty -Name "SubscriptionName" -Value (Get-AzSubscription -SubscriptionId $SubscriptionId).Name
                }
                $AsrItems | Export-Csv -Path ($RootPathName + $AzSub + "__" + $RecVault.Name + "__" + $ASRFabrics[0].FriendlyName + ".csv") -NoTypeInformation -UseCulture
            }
        }
    Merge-CsvFiles -dir $RootPathName -OutFile (Join-Path $RootPathName ($AzSub + "_merged.csv")) -Pattern ($AzSub + "*.csv")
}
Merge-CsvFiles -dir $RootPathName -OutFile (Join-Path $RootPathName ("AsrAnalysis_merged.csv")) -Pattern "*_merged.csv"