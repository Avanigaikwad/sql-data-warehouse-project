/*
=============================================================
Create Database and Schemas
=============================================================

Script Purpose:
	This script creats a new database named 'Datawarehouse' after checking if it already exista.
	If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
	within the database: 'bronze','silver' and 'gold'.

WARNING :
	Running this script will drop the entire 'Datawarehouse' database if it exists.
	All data in the database will be permanently deleted. Process with caution
	and ensure you have proper backups before running this script.
*/



USE Master;
GO

-- Drop and recreate the 'Datawarehouse' Database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'dataWarehouse')
BEGIN
	ALTER DATABASE dataWarehouse 
	SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE dataWarehouse;
END;
GO

-- CREATE the 'DataWarehouse' Database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- create schemas for bronze, silver, gold layers
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO








-- to see all databases in msserver
SELECT name
FROM sys.databases;

EXEC sp_databases; -- with database size

-- drop any schema if needed
DROP SCHEMA bronze;

