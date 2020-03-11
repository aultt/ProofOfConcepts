Connect-AzAccount

$KeyVaultName = 'TAMZ-MS-KeyVault'
$sourceUserName = 'WindowsAdAccount'
$sourcePasswordName = 'WindowsAdAccountPass'
$targetUserName = 'sqlMISaName'
$targetPasswordName = 'sqlMISaPass'
$dmsAppIdName = 'DMSAPPId'
$dmsAppIdPasswordName = 'DMSAppIdPassword' 

$dmsResourceGroup = 'DMS-POC'
$dmsServiceName = 'tamzdmseast'
$dmsProjectName = 'OHSQL8512-To-tamzsqlmieast'
$dmsTaskName = 'AttemptfromWestStorage5'

$sourceServer = 'ohsql8512.tamz.local'
$backupFileSharePath = '\\ohsql8512.tamz.local\SqlBackups'
$database = 'myTDETest3'
$storageResourceId = '/subscriptions/46f9d7a1-dbc5-4885-ab11-15b2554d63c0/resourceGroups/tim-core-west-prod/providers/Microsoft.Storage/storageAccounts/tamzbackupwest'
$MiResourceId  = '/subscriptions/46f9d7a1-dbc5-4885-ab11-15b2554d63c0/resourceGroups/tim-sqlmi-east-prod/providers/Microsoft.Sql/managedInstances/tamzsqlmieast'

$sourceUser = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $sourceUserName
$sourcePassword = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $sourcePasswordName 
$targetUser = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $targetUserName
$targetPassword = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $targetPasswordName 
$dmsAppId = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $dmsAppIdName
$dmsAppIdPassword = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $dmsAppIdPasswordName

$sourceCred = New-Object System.Management.Automation.PSCredential ($sourceUser.SecretValueText, $sourcePassword.SecretValue)
$targetCred = New-Object System.Management.Automation.PSCredential ($targetUser.SecretValueText, $targetPassword.SecretValue)

$sourceConnInfo = New-AzDataMigrationConnectionInfo -ServerType SQL `
  -DataSource $sourceServer `
  -AuthType WindowsAuthentication `
  -TrustServerCertificate:$true

$targetConnInfo = New-AzDataMigrationConnectionInfo -ServerType SQLMI `
  -MiResourceId $MiResourceId

$backupFileShare = New-AzDataMigrationFileShare -Path $backupFileSharePath -Credential $sourceCred

$selectedDbs = @()
$selectedDbs = New-AzDataMigrationSelectedDB -MigrateSqlServerSqlDbMi -Name $database -TargetDatabaseName $database -BackupFileShare $backupFileShare 

$app =  New-AzDataMigrationAzureActiveDirectoryApp   -ApplicationId $dmsAppId.SecretValueText -AppKey $dmsAppIdPassword.SecretValue
$service =Get-AzDataMigrationService -ResourceGroupName $dmsResourceGroup -Name $dmsServiceName
$project = Get-AzDataMigrationProject -Name $dmsProjectName -ResourceGroupName $dmsResourceGroup -ServiceName $dmsServiceName

$migTask = New-AzDataMigrationTask -TaskType MigrateSqlServerSqlDbMiSync `
  -ResourceGroupName $dmsResourceGroup `
  -ServiceName $service.Name `
  -ProjectName $project.Name `
  -TaskName $dmsTaskName `
  -SourceConnection $sourceConnInfo `
  -SourceCred $sourceCred `
  -TargetConnection $targetConnInfo `
  -TargetCred $targetCred `
  -SelectedDatabase  $selectedDbs `
  -BackupFileShare $backupFileShare `
  -AzureActiveDirectoryApp $app `
  -StorageResourceId $storageResourceId
