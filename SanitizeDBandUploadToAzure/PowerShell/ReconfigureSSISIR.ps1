#Prereq:  Create SAS 

$MyDataFactoryName = "ADF-MI-TAMZ"
$MyAzureSsisIrName = "SSIS-IR"
$MyResourceGroupName = "ADF-MI-POC" 
$MySetupScriptContainerSasUri = "your SAS URI"

Login-AzureRmAccount

Set-AzureRmDataFactoryV2IntegrationRuntime -DataFactoryName $MyDataFactoryName `
                                          -Name $MyAzureSsisIrName `
                                          -ResourceGroupName $MyResourceGroupName `
                                          -SetupScriptContainerSasUri $MySetupScriptContainerSasUri

Start-AzureRmDataFactoryV2IntegrationRuntime -DataFactoryName $MyDataFactoryName `
                                            -Name $MyAzureSsisIrName `
                                            -ResourceGroupName $MyResourceGroupName