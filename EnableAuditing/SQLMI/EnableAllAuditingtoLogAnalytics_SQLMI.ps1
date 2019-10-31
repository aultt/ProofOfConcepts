$SQLResourceGroup = "tim-sqlmi-east-prod"
$LogResourceGroup = "tia-oms-prod-rg"
$ServerName = "tamzsqlmieast"
$WorksspaceName = "tamzms"

$Workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $LogResourceGroup -Name $WorksspaceName
$Dbs = Get-AzSqlInstanceDatabase -ResourceGroupName $SQLResourceGroup -InstanceName $ServerName

foreach ($db in $Dbs.Name)
{
    $SqlResource = Get-AzSqlInstanceDatabase -Name $Db -InstanceName $ServerName -ResourceGroupName $SQLResourceGroup
    $DBdiag=Get-AzDiagnosticSetting -ResourceId $SqlResource.Id | Where-Object {$_.Name -NotLike "SQLSecurityAudit*"}
    If ($null -eq $DBdiag)
    {
        Set-AzDiagnosticSetting -ResourceId $SqlResource.Id -Name "SQLInsights_$DB" -WorkspaceId $Workspace.ResourceId -Enabled $true
    }

    foreach ($categoryobj in $DBdiag.Logs)
    {
        Write-Output "DBDiag for $DB $($categoryobj.Category) is $($categoryobj.Enabled)" 
        if ($categoryobj.Enabled -ne $true -and $categoryobj.Category -ne "SQLSecurityAuditEvents")
        {
            if ($null -ne $Dbdiag.Name){$DBdiag | Set-AzDiagnosticSetting -ResourceId $SqlResource.Id -WorkspaceId $Workspace.ResourceId -Category $categoryobj.Category -MetricCategory basic,InstanceAndAppAdvanced -Enabled $true}
            else {Set-AzDiagnosticSetting -ResourceId $SqlResource.Id -Name "SQLInsights_$DB" -WorkspaceId $Workspace.ResourceId -Category $categoryobj.Category -MetricCategory basic,InstanceAndAppAdvanced -Enabled $true}
        }
    }
}



