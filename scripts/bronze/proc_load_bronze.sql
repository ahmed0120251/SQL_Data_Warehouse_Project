*/
    ===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
    @FilePath NVARCHAR(500) = 'C:\Users\Alaa\Downloads\files\'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME, @EndTime DATETIME, @BatchStartTime DATETIME;
    DECLARE @Sql NVARCHAR(MAX);

    BEGIN TRY
        SET @BatchStartTime = GETDATE();
        PRINT '===============================================================================';
        PRINT 'Starting Bronze Layer Load Process';
        PRINT '===============================================================================';

        -- Ensure path ends with a backslash
        IF RIGHT(@FilePath, 1) <> '\' SET @FilePath = @FilePath + '\';

        -- ---------------------------------------------------------------------------
        -- 1. CRM SOURCE TABLES
        -- ---------------------------------------------------------------------------
        PRINT '--> Loading CRM Tables...';

        -- 1.1 Customers
        SET @StartTime = GETDATE();
        TRUNCATE TABLE bronze.crm_customers;
        SET @Sql = 'BULK INSERT bronze.crm_customers FROM ''' + @FilePath + 'olist_customers_dataset.csv'' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @Sql;
        SET @EndTime = GETDATE();
        PRINT '    [+] bronze.crm_customers loaded in ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' s';

        -- 1.2 Orders
        SET @StartTime = GETDATE();
        TRUNCATE TABLE bronze.crm_orders;
        SET @Sql = 'BULK INSERT bronze.crm_orders FROM ''' + @FilePath + 'olist_orders_dataset.csv'' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @Sql;
        SET @EndTime = GETDATE();
        PRINT '    [+] bronze.crm_orders loaded in ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' s';

        -- 1.3 Order Items
        SET @StartTime = GETDATE();
        TRUNCATE TABLE bronze.crm_order_items;
        SET @Sql = 'BULK INSERT bronze.crm_order_items FROM ''' + @FilePath + 'olist_order_items_dataset.csv'' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @Sql;
        SET @EndTime = GETDATE();
        PRINT '    [+] bronze.crm_order_items loaded in ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' s';

        -- 1.4 Order Payments
        SET @StartTime = GETDATE();
        TRUNCATE TABLE bronze.crm_order_payments;
        SET @Sql = 'BULK INSERT bronze.crm_order_payments FROM ''' + @FilePath + 'olist_order_payments_dataset.csv'' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @Sql;
        SET @EndTime = GETDATE();
        PRINT '    [+] bronze.crm_order_payments loaded in ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' s';

        -- ---------------------------------------------------------------------------
        -- 2. ERP SOURCE TABLES
        -- ---------------------------------------------------------------------------
        PRINT '--> Loading ERP Tables...';

        -- 2.1 Products
        SET @StartTime = GETDATE();
        TRUNCATE TABLE bronze.erp_products;
        SET @Sql = 'BULK INSERT bronze.erp_products FROM ''' + @FilePath + 'olist_products_dataset.csv'' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @Sql;
        SET @EndTime = GETDATE();
        PRINT '    [+] bronze.erp_products loaded in ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' s';

        -- 2.2 Sellers
        SET @StartTime = GETDATE();
        TRUNCATE TABLE bronze.erp_sellers;
        SET @Sql = 'BULK INSERT bronze.erp_sellers FROM ''' + @FilePath + 'olist_sellers_dataset.csv'' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @Sql;
        SET @EndTime = GETDATE();
        PRINT '    [+] bronze.erp_sellers loaded in ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' s';

        -- 2.3 Geolocation
        SET @StartTime = GETDATE();
        TRUNCATE TABLE bronze.erp_geolocation;
        SET @Sql = 'BULK INSERT bronze.erp_geolocation FROM ''' + @FilePath + 'olist_geolocation_dataset.csv'' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @Sql;
        SET @EndTime = GETDATE();
        PRINT '    [+] bronze.erp_geolocation loaded in ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' s';

        -- 2.4 Product Category Translation
        SET @StartTime = GETDATE();
        TRUNCATE TABLE bronze.erp_category_translation;
        SET @Sql = 'BULK INSERT bronze.erp_category_translation FROM ''' + @FilePath + 'product_category_name_translation.csv'' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, CODEPAGE = ''65001'');';
        EXEC sp_executesql @Sql;
        SET @EndTime = GETDATE();
        PRINT '    [+] bronze.erp_category_translation loaded in ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' s';

        PRINT '===============================================================================';
        PRINT 'Bronze Layer Load Completed Successfully. Total Duration: ' 
              + CAST(DATEDIFF(SECOND, @BatchStartTime, GETDATE()) AS NVARCHAR) + ' seconds';
        PRINT '===============================================================================';

    END TRY
    BEGIN CATCH
        PRINT '===============================================================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER LOAD';
        PRINT 'Error Message : ' + ERROR_MESSAGE();
        PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Line    : ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '===============================================================================';
    END CATCH
END
GO
