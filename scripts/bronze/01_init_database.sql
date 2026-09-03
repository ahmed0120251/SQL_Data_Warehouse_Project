
```sql
/*
===============================================================================
Script Name : 01_init_database.sql
Author      : Ahmed Amin
Description : Initializes the Data Warehouse environment and creates the
              Medallion Architecture schemas used throughout the project.
              
              Architecture:
              Bronze → Raw Data Ingestion
              Silver → Data Cleansing & Transformation
              Gold   → Business-Ready Data & Reporting
===============================================================================
*/

-- Switch to the system database before recreating the Data Warehouse.
USE master;
GO

-- Recreate the Data Warehouse to ensure a clean development environment.
-- WARNING: This operation permanently deletes the existing database and
--          all objects and data contained within it.
IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = 'DataWarehouse'
)
BEGIN
    -- Terminate active connections and roll back open transactions
    -- to allow the database to be safely dropped.
    ALTER DATABASE DataWarehouse
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;

    -- Remove the existing Data Warehouse database.
    DROP DATABASE DataWarehouse;
END
GO

-- Create a fresh Data Warehouse database.
CREATE DATABASE DataWarehouse;
GO

-- Switch to the newly created Data Warehouse.
USE DataWarehouse;
GO

-- Create the Medallion Architecture schemas.
-- Bronze: Raw data ingested from source systems without business transformations.
CREATE SCHEMA bronze;
GO

-- Silver: Cleaned, standardized, and transformed data prepared for modeling.
CREATE SCHEMA silver;
GO

-- Gold: Business-ready data optimized for analytics, reporting, and BI.
CREATE SCHEMA gold;
GO

-- Confirm successful database and schema initialization.
PRINT '>>> DataWarehouse and Medallion Architecture initialized successfully. <<<';
```
