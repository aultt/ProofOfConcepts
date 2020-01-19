

USE master;  
GO  

--Create database master key for and provide a password.  Replace the password below with one of your own.
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'password';  
go  

--Create Certificate which will encrypt the database encryption key
CREATE CERTIFICATE MyServerCert2 WITH SUBJECT = 'My DEK Certificate';  
go  
USE myTDETest2 ;  
GO  

--Create Database encryption and encrypt it with certificate we created
CREATE DATABASE ENCRYPTION KEY  
WITH ALGORITHM = AES_128  
ENCRYPTION BY SERVER CERTIFICATE MyServerCert2;  
GO  

--Enable Encryption on the database
ALTER DATABASE myTDETest2 
SET ENCRYPTION ON;  
GO


USE master
GO

--Verify Database is encrypted
SELECT db.name as [database_name], cer.name as [certificate_name]
FROM sys.dm_database_encryption_keys dek
LEFT JOIN sys.certificates cer
ON dek.encryptor_thumbprint = cer.thumbprint
INNER JOIN sys.databases db
ON dek.database_id = db.database_id
WHERE dek.encryption_state = 3

USE master
GO
--Backup Certificate.
BACKUP CERTIFICATE MyServerCert2
TO FILE = 'MyServerCert2.cer'
WITH PRIVATE KEY (
  FILE = 'MyServerCert2.pvk',
  ENCRYPTION BY PASSWORD = 'password'
)

