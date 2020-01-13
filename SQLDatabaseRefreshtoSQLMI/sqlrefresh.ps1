
#Variables for user to define
$sourceInstance = "OHSQL8512"
$sourceBackupDestination = '\\ohsql8512\e$\Staging\Backup'
$databases = 'DataExfil','AlwaysEncrypted'
$filePattern = "*.bak"
$destinationInstance = 'tamzsqlmieast.9f87b0bfc7d9.database.windows.net'
$keyVaultName = 'TAMZ-MS-KeyVault'
$sqlMISaPasswordSecret = 'sapass'
$sqlMISaNameSecret ='sqlMISaName'
$sqlFileShareURLSecret = 'sqlFileShareURL'
$sqlFileShareKeySecret = 'sqlFileShareKey'

#Autmatically generated Variables
$sqlMISaName = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $sqlMISaNameSecret
$sqlMISAPass = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $sqlMISaPasswordSecret
$sqlMICred = New-Object System.Management.Automation.PSCredential ($sqlMISaName.SecretValueText,$sqlMISAPass.SecretValue)
$azureFileShare = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $sqlFileShareURLSecret
$azureFilesShareKey = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $sqlFileShareKeySecret
$currentDay = (Get-Date).ToString("yyyyMMdd")

Backup-Dbadatabase -SqlInstance $sourceInstance -Database $databases -BackupFileName $dbFilename -BackupDirectory $sourceBackupDestination -Type FULL -ReplaceInName -WithFormat -CompressBackup
    

Foreach ($DB in $Databases)
{
    $dbFilename = "$($db)_Full_$($currentDay).bak"
    #Backup Each database to provided path.  Only one backup will exist for the day therfore we reformat the file and overwrite if it exists
    $backupResult=Backup-Dbadatabase -SqlInstance $sourceInstance -Database $db -BackupFileName $dbFilename -BackupDirectory $sourceBackupDestination -Type FULL -ReplaceInName -WithFormat -CompressBackup
    
    #Verify Results
    if ($backupResult.BackupComplete)
    {
        Write-Verbose "Database $($backupResult.Database) backed up in $($backupResult.Duration)"
        Write-Host "Database $($backupResult.Database) backed up in $($backupResult.Duration)"
    }
    else
    {Write-Error "Restore of $($RestoreResult.Database) Failed." }
}

#Copy Files to Azure Storage /XO only copyies new files /S copies recursively /Y suppresses prompts which allows overwriting existing files
AzCopy /Source:$sourceBackupDestination /Dest:$($AzureFileShare.SecretValueText) /DestKey:$($AzureFilesShareKey.SecretValueText) /Pattern:$FilePattern /S /XO /Y

Foreach ($db in $databases)
{
    $dbFilename = "$($db)_Full_$($currentDay).bak"
    $azureBackupLocation = $($azureFileShare.SecretValueText) +'/'+ $dbFilename
    
    #Restore Database to Azure SQL MI
    $restoreResult = Restore-DbaDatabase -SqlInstance $destinationInstance -WithReplace -DatabaseName $db -Path $azureBackupLocation -SqlCredential $sqlMICred

    #Verify Restore Completed Successfully
    if ($restoreResult.RestoreComplete)
    {
        Write-Verbose "Database $($restoreResult.Database) restored in $($restoreResult.DatabaseRestoreTime)"
        Write-Host "Database $($restoreResult.Database) restored in $($restoreResult.DatabaseRestoreTime)"
    }
    else
    {Write-Error "Restore of $($restoreResult.Database) Failed." }
}



