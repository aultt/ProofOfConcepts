-- Reset the demo
ALTER TABLE Patients ALTER COLUMN LastName DROP MASKED
ALTER TABLE Patients ALTER COLUMN MiddleName DROP MASKED
ALTER TABLE Patients ALTER COLUMN StreetAddress DROP MASKED
ALTER TABLE Patients ALTER COLUMN ZipCode DROP MASKED
go

-- Expose only first letter of last name
ALTER TABLE Patients ALTER COLUMN LastName ADD MASKED WITH (FUNCTION = 'partial(1, "xxxx", 0)')

-- Full mask for middle initial, street address, and zip code
ALTER TABLE Patients ALTER COLUMN MiddleName ADD MASKED WITH (FUNCTION = 'default()')
ALTER TABLE Patients ALTER COLUMN StreetAddress ADD MASKED WITH (FUNCTION = 'default()')
ALTER TABLE Patients ALTER COLUMN ZipCode ADD MASKED WITH (FUNCTION = 'default()')
