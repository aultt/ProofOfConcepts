--Reference Article to setup TDE in AlwaysOn
--https://docs.microsoft.com/en-us/archive/blogs/alwaysonpro/how-to-add-a-tde-encrypted-database-to-an-availability-group

USE master;  
GO  

--Create master key and create certificate to be used as encryption key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'password';  
go  
CREATE CERTIFICATE MyServerCert1 WITH SUBJECT = 'My DEK Certificate';  
go  

--Assign certificate as encryption key for database and turn on encryption
USE tdeAGtest ;  
GO  
CREATE DATABASE ENCRYPTION KEY  
WITH ALGORITHM = AES_128  
ENCRYPTION BY SERVER CERTIFICATE MyServerCert1;  
GO  
ALTER DATABASE tdeAGtest 
SET ENCRYPTION ON;  
GO

--Verify database is now encrypted
USE master
GO
SELECT db.name as [database_name], cer.name as [certificate_name]
FROM sys.dm_database_encryption_keys dek
LEFT JOIN sys.certificates cer
ON dek.encryptor_thumbprint = cer.thumbprint
INNER JOIN sys.databases db
ON dek.database_id = db.database_id
WHERE dek.encryption_state = 3

USE master
GO

--Backup Certificate on Primary to import to secondary
--Certificate will then need to be copied to secondary servers data directory
BACKUP CERTIFICATE MyServerCert1
TO FILE = 'MyServerCert1.cer'
WITH PRIVATE KEY (
  FILE = 'MyServerCert1.pvk',
  ENCRYPTION BY PASSWORD = 'password'
)

--Must make connection to secondary first
--Restores Certificate to secondary server
CREATE CERTIFICATE MyServerCert2
FROM FILE = 'MyServerCert1.cer'
WITH PRIVATE KEY ( FILE = 'MyServerCert1.pvk', 
DECRYPTION BY PASSWORD = 'password')

--Join the database to the availability group
alter availability group TAMZ_DemoHA add database tdeAGTest

--Create new certificate to rotate on primary
CREATE CERTIFICATE MyServerCert2 WITH SUBJECT = 'My DEK Certificate';  
go  

--Backup New certificate on Primary to restore to Secondary
--Certificate will then need to be copied to secondary servers data directory
BACKUP CERTIFICATE MyServerCert2
TO FILE = 'MyServerCert2.cer'
WITH PRIVATE KEY (
  FILE = 'MyServerCert2.pvk',
  ENCRYPTION BY PASSWORD = 'password'
)

--Restore certificate to Secondary Server
CREATE CERTIFICATE MyServerCert2
FROM FILE = 'MyServerCert2.cer'
WITH PRIVATE KEY ( FILE = 'MyServerCert2.pvk', 
DECRYPTION BY PASSWORD = 'password')


--Rotate the Cert
USE [tdeAGtest]
GO
ALTER DATABASE ENCRYPTION KEY
ENCRYPTION BY SERVER CERTIFICATE MyServerCert2;
GO

--Validate on both nodes
USE master
GO
SELECT db.name as [database_name], cer.name as [certificate_name]
FROM sys.dm_database_encryption_keys dek
LEFT JOIN sys.certificates cer
ON dek.encryptor_thumbprint = cer.thumbprint
INNER JOIN sys.databases db
ON dek.database_id = db.database_id
WHERE dek.encryption_state = 3