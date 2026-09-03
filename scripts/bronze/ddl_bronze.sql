
/*
===============================================================================
Script Name : 02_create_bronze_tables.sql
Description : DDL for Bronze Layer (Raw Staging). Defines raw tables for CRM 
              and ERP source systems using NVARCHAR strings to prevent load errors.
===============================================================================
*/

USE DataWarehouse;
GO

-- ============================================================================
-- 1. CRM SOURCE TABLES
-- ============================================================================
-- 1. crm_customers
IF OBJECT_ID('bronze.crm_customers', 'U') IS NOT NULL DROP TABLE bronze.crm_customers;
CREATE TABLE bronze.crm_customers (
    customer_id              NVARCHAR(50),
    customer_unique_id       NVARCHAR(50),
    customer_zip_code_prefix NVARCHAR(10),
    customer_city            NVARCHAR(100),
    customer_state           NVARCHAR(5)
);
-- 2. crm_orders
IF OBJECT_ID('bronze.crm_orders', 'U') IS NOT NULL DROP TABLE bronze.crm_orders;
CREATE TABLE bronze.crm_orders (
    order_id                       NVARCHAR(50),
    customer_id                    NVARCHAR(50),
    order_status                   NVARCHAR(20),
    order_purchase_timestamp       NVARCHAR(30),
    order_approved_at              NVARCHAR(30),
    order_delivered_carrier_date   NVARCHAR(30),
    order_delivered_customer_date  NVARCHAR(30),
    order_estimated_delivery_date  NVARCHAR(30)
);
-- 3. crm_order_items
IF OBJECT_ID('bronze.crm_order_items', 'U') IS NOT NULL DROP TABLE bronze.crm_order_items;
CREATE TABLE bronze.crm_order_items (
    order_id              NVARCHAR(50),
    order_item_id         NVARCHAR(10),
    product_id            NVARCHAR(50),
    seller_id             NVARCHAR(50),
    shipping_limit_date   NVARCHAR(30),
    price                 NVARCHAR(20),
    freight_value         NVARCHAR(20)
);
-- 4. crm_order_payments
IF OBJECT_ID('bronze.crm_order_payments', 'U') IS NOT NULL DROP TABLE bronze.crm_order_payments;
CREATE TABLE bronze.crm_order_payments (
    order_id              NVARCHAR(50),
    payment_sequential    NVARCHAR(10),
    payment_type          NVARCHAR(30),
    payment_installments  NVARCHAR(10),
    payment_value         NVARCHAR(20)
);

-- ============================================================================
-- 2. ERP SOURCE TABLES
-- ============================================================================
-- 5. erp_products
IF OBJECT_ID('bronze.erp_products', 'U') IS NOT NULL DROP TABLE bronze.erp_products;
CREATE TABLE bronze.erp_products (
    product_id                 NVARCHAR(50),
    product_category_name      NVARCHAR(100),
    product_name_length        NVARCHAR(10), -- Corrected spelling
    product_description_length NVARCHAR(10), -- Corrected spelling
    product_photos_qty         NVARCHAR(10),
    product_weight_g           NVARCHAR(10),
    product_length_cm          NVARCHAR(10),
    product_height_cm          NVARCHAR(10),
    product_width_cm           NVARCHAR(10)
);
-- 6. erp_sellers
IF OBJECT_ID('bronze.erp_sellers', 'U') IS NOT NULL DROP TABLE bronze.erp_sellers;
CREATE TABLE bronze.erp_sellers (
    seller_id               NVARCHAR(50),
    seller_zip_code_prefix  NVARCHAR(10),
    seller_city             NVARCHAR(100),
    seller_state            NVARCHAR(5)
);
-- 7. erp_geolocation
IF OBJECT_ID('bronze.erp_geolocation', 'U') IS NOT NULL DROP TABLE bronze.erp_geolocation;
CREATE TABLE bronze.erp_geolocation (
    geolocation_zip_code_prefix NVARCHAR(10),
    geolocation_lat             NVARCHAR(30),
    geolocation_lng             NVARCHAR(30),
    geolocation_city            NVARCHAR(100),
    geolocation_state           NVARCHAR(5)
);
-- 8. erp_category_translation
IF OBJECT_ID('bronze.erp_category_translation', 'U') IS NOT NULL DROP TABLE bronze.erp_category_translation;
CREATE TABLE bronze.erp_category_translation (
    product_category_name         NVARCHAR(100),
    product_category_name_english NVARCHAR(100)
);
GO

PRINT '>>> Bronze Layer DDL Executed Successfully (9 Tables Created) <<<';
