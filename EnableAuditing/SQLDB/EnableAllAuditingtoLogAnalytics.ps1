$SQLResourceGroup = "tim-sql-east-prod"
$LogResourceGroup = "tia-oms-prod-rg"
$ServerName = "tamzsqleast"
$WorksspaceName = "tamzms"

$Workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $LogResourceGroup -Name $WorksspaceName
$SQLAudit = Get-AzSqlServerAudit -ResourceGroupName $SQLResourceGroup -ServerName $ServerName

if ($SQLAudit.LogAnalyticsTargetState -ne "Enabled")
{
    Set-AzSqlServerAudit -ResourceGroupName $SQLResourceGroup -ServerName $ServerName -LogAnalyticsTargetState Enabled -WorkspaceResourceId $Workspace.ResourceId
}

$Dbs = Get-AzSqlDatabase -ResourceGroupName $SQLResourceGroup -ServerName $ServerName
foreach ($db in $Dbs.DatabaseName)
{
    $DBAudit = Get-AzSqlDatabaseAudit -ResourceGroupName $SQLResourceGroup -ServerName $ServerName -DatabaseName $db
    Write-Output "DBAudit for $DB is $($DBAudit.LogAnalyticsTargetState)" 
    if ($DBAudit.LogAnalyticsTargetState -ne "Enabled" -and $db -ne "master")
    {
        Set-AzSqlDatabaseAudit -ResourceGroupName $SQLResourceGroup -ServerName $ServerName -DatabaseName $db -LogAnalyticsTargetState Enabled -WorkspaceResourceId $Workspace.ResourceId 
    }

    $SqlResource = Get-AzSqlDatabase -DatabaseName $Db -ServerName $ServerName -ResourceGroupName $SQLResourceGroup
    $DBdiag=Get-AzDiagnosticSetting -ResourceId $SqlResource.ResourceId | Where-Object {$_.Name -NotLike "SQLSecurityAudit*"}
    
    foreach ($categoryobj in $DBdiag.Logs)
    {
        Write-Output "DBDiag for $DB $($categoryobj.Category) is $($categoryobj.Enabled)" 
        if ($categoryobj.Enabled -ne $true -and $categoryobj.Category -ne "SQLSecurityAuditEvents")
        {
            if ($null -ne $Dbdiag.Name){$DBdiag | Set-AzDiagnosticSetting -ResourceId $SqlResource.ResourceId -WorkspaceId $Workspace.ResourceId -Category $categoryobj.Category -MetricCategory basic,InstanceAndAppAdvanced -Enabled $true}
            else {Set-AzDiagnosticSetting -ResourceId $SqlResource.ResourceId -Name "SQLInsights_$DB" -WorkspaceId $Workspace.ResourceId -Category $categoryobj.Category -MetricCategory basic,InstanceAndAppAdvanced -Enabled $true}
        }
    }
}



