
/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
    Actions Performed:
        - Truncates Silver tables before loading.
        - Cleanses and standardizes source data.
        - Removes unwanted characters and spaces from text fields.
        - Converts source values into appropriate data types.
        - Handles invalid or empty values during the transformation process.
        - Adds the data warehouse creation date to loaded records.
        - Tracks the execution time for each table and the overall process.
        - Handles errors using TRY...CATCH.

Parameters:
    None.
      This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/


USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time DATETIME2, @end_time DATETIME2, @batch_start_time DATETIME2, @batch_end_time DATETIME2;
    
    BEGIN TRY
        SET @batch_start_time = SYSDATETIME();
        PRINT '==================================================';
        PRINT 'Starting Silver Layer Loading Process';
        PRINT '==================================================';

        ------------------------------------------------------------------
        -- 1. crm_customers
        ------------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating & Loading: silver.crm_customers';
        
        TRUNCATE TABLE silver.crm_customers;
        
        INSERT INTO silver.crm_customers (
            customer_id,
            customer_unique_id,
            customer_zip_code_prefix,
            customer_city,
            customer_state,
            dwh_create_date
        )
        SELECT 
            TRIM(REPLACE(customer_id, '"', '')) AS customer_id,
            TRIM(REPLACE(customer_unique_id,'"', '')) AS customer_unique_id,
            NULLIF(TRIM(REPLACE(customer_zip_code_prefix,'"', '')), '') AS customer_zip_code_prefix,
            NULLIF(UPPER(TRIM(customer_city)), '') AS customer_city,
            NULLIF(UPPER(TRIM(customer_state)), '') AS customer_state,
            GETDATE()
        FROM bronze.crm_customers;
        
        SET @end_time = SYSDATETIME();
        PRINT '>> Completed in: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + ' ms';
        PRINT '--------------------------------------------------';

        ------------------------------------------------------------------
        -- 2. crm_orders
        ------------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating & Loading: silver.crm_orders';
        
        TRUNCATE TABLE silver.crm_orders;
        
        INSERT INTO silver.crm_orders (
            order_id,
            customer_id,
            order_status,
            order_purchase_timestamp,
            order_approved_at,
            order_delivered_carrier_date,
            order_delivered_customer_date,
            order_estimated_delivery_date,
            dwh_create_date
        )
        SELECT 
            TRIM(REPLACE(order_id,'"', '')) AS order_id,
            TRIM(REPLACE(customer_id,'"', '')) AS customer_id,
            NULLIF(LOWER(TRIM(REPLACE(order_status,'"',''))), '') AS order_status,
            TRY_CAST(TRIM(order_purchase_timestamp) AS DATETIME2) AS order_purchase_timestamp,
            TRY_CAST(TRIM(order_approved_at) AS DATETIME2) AS order_approved_at,
            TRY_CAST(TRIM(order_delivered_carrier_date) AS DATETIME2) AS order_delivered_carrier_date,
            TRY_CAST(TRIM(order_delivered_customer_date) AS DATETIME2) AS order_delivered_customer_date,
            TRY_CAST(TRIM(order_estimated_delivery_date) AS DATETIME2) AS order_estimated_delivery_date,
            GETDATE()
        FROM bronze.crm_orders;

        SET @end_time = SYSDATETIME();
        PRINT '>> Completed in: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + ' ms';
        PRINT '--------------------------------------------------';

        ------------------------------------------------------------------
        -- 3. crm_order_items
        ------------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating & Loading: silver.crm_order_items';
        
        TRUNCATE TABLE silver.crm_order_items;
        
        INSERT INTO silver.crm_order_items (
            order_id,
            order_item_id,
            product_id,
            seller_id,
            shipping_limit_date,
            price,
            freight_value,
            dwh_create_date
        )
        SELECT 
            TRIM(REPLACE(order_id,'"', '')) AS order_id,
            -- FIX: TINYINT (0-255) risks silent NULLs on any order with 256+ items.
            -- SMALLINT gives a safe range at negligible storage cost.
            TRY_CAST(TRIM(order_item_id) AS SMALLINT) AS order_item_id,
            TRIM(REPLACE(product_id,'"', '')) AS product_id,
            TRIM(REPLACE(seller_id,'"', '')) AS seller_id,
            TRY_CAST(TRIM(shipping_limit_date) AS DATETIME2) AS shipping_limit_date,
            TRY_CAST(TRIM(price) AS DECIMAL(10, 2)) AS price,
            TRY_CAST(TRIM(freight_value) AS DECIMAL(10, 2)) AS freight_value,
            GETDATE()
        FROM bronze.crm_order_items;

        SET @end_time = SYSDATETIME();
        PRINT '>> Completed in: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + ' ms';
        PRINT '--------------------------------------------------';

        ------------------------------------------------------------------
        -- 4. crm_order_payments
        ------------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating & Loading: silver.crm_order_payments';
        
        TRUNCATE TABLE silver.crm_order_payments;
        
        INSERT INTO silver.crm_order_payments (
            order_id,
            payment_sequential,
            payment_type,
            payment_installments,
            payment_value,
            dwh_create_date
        )
        SELECT 
            TRIM(REPLACE(order_id,'"','')) AS order_id,
            -- FIX: same TINYINT risk as order_item_id above.
            TRY_CAST(TRIM(payment_sequential) AS SMALLINT) AS payment_sequential,
            NULLIF(LOWER(TRIM(payment_type)), '') AS payment_type,
            -- FIX: payment_installments as a count of installments is safer as SMALLINT too.
            TRY_CAST(TRIM(payment_installments) AS SMALLINT) AS payment_installments,
            TRY_CAST(TRIM(payment_value) AS DECIMAL(10, 2)) AS payment_value,
            GETDATE()
        FROM bronze.crm_order_payments;

        SET @end_time = SYSDATETIME();
        PRINT '>> Completed in: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + ' ms';
        PRINT '--------------------------------------------------';

        ------------------------------------------------------------------
        -- 5. erp_products
        ------------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating & Loading: silver.erp_products';
        
        TRUNCATE TABLE silver.erp_products;
        
        INSERT INTO silver.erp_products (
            product_id,
            product_category_name,
            product_name_length,
            product_description_length,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm,
            dwh_create_date
        )
        SELECT 
            TRIM(REPLACE(product_id,'"', '')) AS product_id,
            NULLIF(TRIM(product_category_name), '') AS product_category_name,
            TRY_CAST(TRIM(product_name_length) AS INT) AS product_name_length,
            TRY_CAST(TRIM(product_description_length) AS INT) AS product_description_length,
            -- FIX: photos qty as SMALLINT - safe margin, negligible cost.
            TRY_CAST(TRIM(product_photos_qty) AS SMALLINT) AS product_photos_qty,
            TRY_CAST(TRIM(product_weight_g) AS INT) AS product_weight_g,
            TRY_CAST(TRIM(product_length_cm) AS DECIMAL(8, 2)) AS product_length_cm,
            TRY_CAST(TRIM(product_height_cm) AS DECIMAL(8, 2)) AS product_height_cm,
            TRY_CAST(TRIM(product_width_cm) AS DECIMAL(8, 2)) AS product_width_cm,
            GETDATE()
        FROM bronze.erp_products;

        SET @end_time = SYSDATETIME();
        PRINT '>> Completed in: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + ' ms';
        PRINT '--------------------------------------------------';

        ------------------------------------------------------------------
        -- 6. erp_sellers
        ------------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating & Loading: silver.erp_sellers';
        
        TRUNCATE TABLE silver.erp_sellers;
        
        INSERT INTO silver.erp_sellers (
            seller_id,
            seller_zip_code_prefix,
            seller_city,
            seller_state,
            dwh_create_date
        )
        SELECT 
            TRIM(REPLACE(seller_id,'"', '')) AS seller_id,
            NULLIF(TRIM(REPLACE(seller_zip_code_prefix,'"','')), '') AS seller_zip_code_prefix,
            NULLIF(UPPER(TRIM(seller_city)), '') AS seller_city,
            NULLIF(UPPER(TRIM(seller_state)), '') AS seller_state,
            GETDATE()
        FROM bronze.erp_sellers;

        SET @end_time = SYSDATETIME();
        PRINT '>> Completed in: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + ' ms';
        PRINT '--------------------------------------------------';

        ------------------------------------------------------------------
        -- 7. erp_geolocation
        ------------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating & Loading: silver.erp_geolocation';
        
        TRUNCATE TABLE silver.erp_geolocation;
        
        INSERT INTO silver.erp_geolocation (
            geolocation_zip_code_prefix,
            geolocation_lat,
            geolocation_lng,
            geolocation_city,
            geolocation_state,
            dwh_create_date
        )
        SELECT 
            NULLIF(TRIM(REPLACE(geolocation_zip_code_prefix,'"', '')), '') AS geolocation_zip_code_prefix,
            TRY_CAST(TRIM(geolocation_lat) AS DECIMAL(10, 8)) AS geolocation_lat,
            TRY_CAST(TRIM(geolocation_lng) AS DECIMAL(11, 8)) AS geolocation_lng,
            NULLIF(UPPER(TRIM(geolocation_city)), '') AS geolocation_city,
            NULLIF(UPPER(TRIM(geolocation_state)), '') AS geolocation_state,
            GETDATE()
        FROM bronze.erp_geolocation;

        SET @end_time = SYSDATETIME();
        PRINT '>> Completed in: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + ' ms';
        PRINT '--------------------------------------------------';

        ------------------------------------------------------------------
        -- 8. erp_category_translation
        ------------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating & Loading: silver.erp_category_translation';
        
        TRUNCATE TABLE silver.erp_category_translation;
        
        INSERT INTO silver.erp_category_translation (
            product_category_name,
            product_category_name_english,
            dwh_create_date
        )
        SELECT 
            NULLIF(TRIM(product_category_name), '') AS product_category_name,
            NULLIF(TRIM(product_category_name_english), '') AS product_category_name_english,
            GETDATE()
        FROM bronze.erp_category_translation;

        SET @end_time = SYSDATETIME();
        PRINT '>> Completed in: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR) + ' ms';
        PRINT '--------------------------------------------------';

        SET @batch_end_time = SYSDATETIME();
        PRINT '==================================================';
        PRINT 'Silver Layer Loaded Successfully!';
        PRINT 'Total Execution Time: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS VARCHAR) + ' seconds';
        PRINT '==================================================';

    END TRY
    BEGIN CATCH
        PRINT '==================================================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOADING!';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: '  + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'Error State: '   + CAST(ERROR_STATE() AS VARCHAR);
        PRINT '==================================================';
    END CATCH
END;
GO

EXEC silver.load_silver;
