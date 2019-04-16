#Variables to aid in File Identification
$CurrentDay = (Get-Date).ToString("yyyyMMdd")
$PreviousDay = (Get-Date).AddDays(-1).ToString("yyyyMMdd")

#Production Server Connections
$ProductionBackupPath = '\\ohsql8510\Backup\OHSQL8500C$TAMZ_DemoHA\AdventureWorks2012\FULL\'
$DatabaseName = 'AdventureWorks2012'
$ProductionbDBFilename = "$($DatabaseName)_Full_$($PreviousDay)_*.bak"
$ProductionBackupFile = Join-Path $ProductionBackupPath $ProductionbDBFilename
#Removed reference as copy will occur with SSIS or ADF
#$ProductionFilePath = '\\ohsql8510\Files\AdventureWorksFiles'
#$FilePattern = '*.txt'

#Staging and Utility Server
$StagingSQLServer = 'OHSQL8512'
$UtilityScriptPath = 'E:\Scrubbing\Utility'
$StagingBackupDestination = 'E:\Staging\Backup'
$StagingFileDestination = 'E:\Staging\Files'
$ScrubbedBackupDestination = 'E:\Scrubbing\Backup'
$ScrubbedBackupArchive = 'E:\Scrubbing\Archive'
$DBScrubberFileName = 'DB_Scrubber.bat'
$FileScrubberFileName = 'File_Scrubber.bat'
$StagingBackupFile = Join-Path $StagingBackupDestination $ProductionbDBFilename

#Azure 
$AzureDBServer = 'AESQL003'
$ScrubbedSharePath = 'Share\ScrubbedDBBackup'
$ScrubbedArchivePath = 'Share\ArchivedDBBackup'
$AzureDBScrubbedPath = Join-Path "\\$AzureDBServer" -ChildPath $ScrubbedSharePath
$AzureDBArchivedPath = Join-Path "\\$AzureDBServer" -ChildPath $ScrubbedArchivePath
#$Cred =Get-Credential

#Copy Production Backup and Files to Staging Area 
Copy-Item $ProductionBackupFile -Destination $StagingBackupDestination
#Removed reference as copy will occur with SSIS or ADF
#Copy-Item $ProductionFilePath -Filter $FilePattern  -Destination $StagingFileDestination -Recurse

#Restore Production Backup on Staging Server
get-childitem $StagingBackupDestination | Restore-DbaDatabase -SqlInstance $StagingSQLServer -WithReplace

#Remove Production Backup from staging
Remove-Item $StagingBackupFile -Confirm:$false 

#Scrub Database
$DBScrubber = Join-Path $UtilityScriptPath -ChildPath $DBScrubberFileName
$DBResult = Start-Process -FilePath $DBScrubber -Wait -PassThru
If ($DBResult.ExitCode -eq 0){ Write-Verbose "Successfully ran DB Scrubber!"}
else { Write-Error "DB Scrubber Batch Failed!"}

#Scrub Files
$FileScrubber = Join-Path $UtilityScriptPath -ChildPath $FileScrubberFileName
$FileResult = Start-Process -FilePath $FileScrubber -Wait -PassThru
If ($FileResult.ExitCode -eq 0){ Write-Verbose "Successfully ran File Scrubber!"}
else { Write-Error "File Scrubber Batch Failed!"}

#Backup Scrubbed Database
Backup-Dbadatabase -SqlInstance $StagingSQLServer -Database $DatabaseName -BackupDirectory $ScrubbedBackupDestination -Type FULL -ReplaceInName -CompressBackup

#Import module to allow us to leverage BitsTransfer cmdlets
Import-Module bitstransfer

#Copy Scrubbed Backup file to Azure SQL Server Asynchronously
$ScrubbedDbBackupFile = Get-Item -Path "$ScrubbedBackupDestination\$($DatabaseName)_$($CurrentDay)*.bak"
$DBBitsTransfer= start-bitstransfer -Source $ScrubbedDbBackupFile.FullName -Destination $AzureDBScrubbedPath -Priority High -Credential $Cred -Asynchronous 

#Continue to loop checking the Pecentage complete writing progress back
While( ($DBBitsTransfer.JobState.ToString() -eq 'Transferring') -or ($DBBitsTransfer.JobState.ToString() -eq 'Connecting') )
{
    Start-Sleep -Seconds 5
    $pct = [int](($DBBitsTransfer.BytesTransferred*100) / $DBBitsTransfer.BytesTotal)
    Write-Progress -Activity "Copying file..." -CurrentOperation "$pct% complete"
}


#Verify Backup file was successfully transfered. If so archive the file.
if ($DBBitsTransfer.JobState -eq 'Transferred')
{
    Start-Sleep -Seconds 5
    Complete-BitsTransfer -BitsJob $DBBitsTransfer.JobId
    Move-Item $ScrubbedDbBackupFile -Destination $ScrubbedBackupArchive
    
}
else
{Write-Error "Copy of $ScrubbedDbBackupFile Failed! "}

#Restore Scrubbed Database to Azure Server
$RestoreResult = get-childitem $AzureDBScrubbedPath | Restore-DbaDatabase -SqlInstance $AzureDBServer -WithReplace 
$AzureDBScrubbedFilePath = Join-Path $AzureDBScrubbedPath -ChildPath $ScrubbedDbBackupFile.Name

#Verify Restore Completed Successfully
if ($RestoreResult.RestoreComplete)
{
    Move-Item $AzureDBScrubbedFilePath -Destination $AzureDBArchivedPath
    Write-Verbose "Database $RestoreResult.Database restored in $RestoreResult.DatabaseRestoreTime"
}
else
{Write-Error "Restore of $RestoreResult.Database Failed." }


#If we were going to copy to Blob using AZCopy the following would be leveraged
#Copy Files to Azure Files
#$AzureFileShare = ''
#$AzureFilesShareKey = ''
#AzCopy /Source:$StagingFileDestination /Dest:$AzureFileShare /DestKey:$AzureFilesShareKey /Pattern:$FilePattern /S
