$certPath = 'E:\TDECert\'
$certName = 'MyServerCert2'
$miResourceGroup = 'tim-sqlmi-east-prod'
$miConnection = 'tamzsqlmieast'
$certPasswordSecret = 'certPassword'
$keyVaultName = 'TAMZ-MS-KeyVault'
$certPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $certPasswordSecret


#System Generated Variables
$certCerPath = Join-Path -Path $certPath -ChildPath "$certName.cer"
$certPvkPath = Join-Path -Path $certPath -ChildPath "$certName.pvk"
$certPfxPath = Join-Path -Path $certPath -ChildPath "$certName.pfx"

#This needs to be installed.  This is part of the Windows 10 SDK
#Must be added into Visual Studio
Set-Location 'C:\Program Files (x86)\Windows Kits\10\bin\10.0.18362.0\x64\'
.\pvk2pfx.exe -pvk $certPvkPath  -pi $certPassword.SecretValueText -spc $certCerPath -pfx $certPfxPath

$fileContentBytes = Get-Content $certPfxPath -Encoding Byte
$base64EncodedCert = [System.Convert]::ToBase64String($fileContentBytes)
$securePrivateBlob = $base64EncodedCert  | ConvertTo-SecureString -AsPlainText -Force
$securePassword = $certPassword.SecretValue
Add-AzSqlManagedInstanceTransparentDataEncryptionCertificate -ResourceGroupName $miResourceGroup `
    -ManagedInstanceName $miConnection -PrivateBlob $securePrivateBlob -Password $securePassword

