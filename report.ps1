param(
    [Parameter(Mandatory=$true)]
    [string]$JsonFile
)

$json = Get-Content -Raw -Path $jsonfile | ConvertFrom-Json

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$passwd = ConvertTo-SecureString $json.login.SPN_PW -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($json.login.SPN_ID, $passwd) 
$azure = Get-AzEnvironment 'AzureCloud'
Login-AzAccount -Environment $azure -TenantId $json.login.TENANT_ID -Credential $cred -ServicePrincipal -WarningAction Ignore  > $null

if (!(Test-Path ((Get-location).path + "/" + $json.location))) {
    New-Item -ItemType Directory -Path ((Get-location).path + "/" + $json.location)
}
Set-Location ((Get-location).path + "/" + $json.location)
$output = ((Get-Location).path  + ("\"))
$date = (Get-Date -format "yyyyMMddhhmmss")
$subs = @($json.subscription.name)

Function Merge-CsvFiles($dir, $OutFile, $Pattern) {
    # Build the file list
    $FileList = Get-ChildItem $dir -include $Pattern -rec -File | Where-Object {$_.Length -ne 0kb}
    # Get the header info from the first file
    if (! $FileList.count -eq 0 )  {
        Get-Content $fileList[0] | Select-Object -First 1 | Out-File -FilePath $outfile -Encoding ascii
        # Cycle through and get the data (sans header) from all the files in the list
        foreach ($file in $filelist) {
            Get-Content $file | Select-Object -Skip 1 | Out-File -FilePath $outfile -Encoding ascii -Append
        }
    }
}

for($i = 1; $i -le $subs.count; $i++) { 
    $sub = $subs[$i-1]
    Select-AzSubscription $sub > $null
    $RecVaults = Get-AzResource -ResourceType Microsoft.RecoveryServices/vaults
    if (! ($RecVaults.count -eq 0)) {
        for($v=1; $v -le $RecVaults.count; $v++) {
            $RecVault = $RecVaults[$v-1]
            Start-Sleep -Milliseconds 1
            Write-Progress -Id 1 -Activity ("Processing: " + $subs.count + " Subscriptions (Defined in JSON file)") `
                -status ("Processing Subscription: " + $sub + " | Vault Counts: "+ $RecVaults.count ) `
                -percentComplete ($v / $RecVaults.count*100) `
                -CurrentOperation ("Collecting Data form (Vault): " + $RecVault.Name)
            $vault = Get-AzRecoveryServicesVault -Name $RecVault.Name -ResourceGroupName $RecVault.ResourceGroupName
            Set-ASRVaultContext -Vault $Vault > $null
            $ASRFabrics = Get-ASRFabric 
            if ($ASRFabrics.count -ne 0) {
                $ProtectionContainer = Get-ASRProtectionContainer -Fabric $ASRFabrics[0]
                $AsrItems = Get-ASRReplicationProtectedItem -ProtectionContainer $ProtectionContainer 
                for($a=1; $a -le $AsrItems.count; $a++) {
                    $AsrItem = $AsrItems[$a-1]
                    Start-Sleep -Milliseconds 1
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
                    $AsrItems | Export-Csv -Path ((($output + ("~$" + $date +$sub + $RecVaults[$v].Name + $ASRFabrics[0].FriendlyName + ".csv").replace(' ' , ''))).ToLower()) -NoTypeInformation -UseCulture 
            }
        }
        Merge-CsvFiles -dir $output -OutFile (Join-Path $output ("~$" + $date + $sub + ".csv")) -Pattern ("~$" + $date + $sub + "*.csv")
    }
}

Merge-CsvFiles -dir $output -OutFile (Join-Path $output ("report.csv")) -Pattern  ("~$" + $date + "*.csv")
(Get-Content -path ($output + "report.csv")).replace(',',$json.login.delimiter) | Set-Content -Path ($output + "report.csv")
Remove-Item -Path ($output + ("~$" + $date + "*.csv"))