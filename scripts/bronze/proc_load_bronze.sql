
/*
===============================================================================
Script Name : 02_create_bronze_tables.sql
===============================================================================
Script Purpose:
    This script creates the raw staging tables in the 'bronze' schema.
    The Bronze Layer stores source data in its raw form before any
    cleansing, transformation, or business rules are applied.

    The script performs the following actions:
    - Drops existing Bronze tables if they already exist.
    - Creates raw staging tables for CRM source data.
    - Creates raw staging tables for ERP source data.
    - Uses NVARCHAR data types to preserve source values and minimize
      data conversion issues during the initial data ingestion process.

Source Systems:
    - CRM (Customer Relationship Management)
    - ERP (Enterprise Resource Planning)

Tables Created:
    CRM:
    - bronze.crm_customers
    - bronze.crm_orders
    - bronze.crm_order_items
    - bronze.crm_order_payments
    - bronze.crm_order_reviews

    ERP:
    - bronze.erp_products
    - bronze.erp_sellers
    - bronze.erp_geolocation
    - bronze.erp_category_translation

Notes:
    These tables are designed for raw data ingestion. Data types and
    business transformations will be handled in subsequent layers.

===============================================================================
*/

USE DataWarehouse;
GO

/*
===============================================================================
1. CRM SOURCE TABLES
===============================================================================
*/

IF OBJECT_ID('bronze.crm_customers', 'U') IS NOT NULL
    DROP TABLE bronze.crm_customers;

CREATE TABLE bronze.crm_customers (
    customer_id              NVARCHAR(50),
    customer_unique_id       NVARCHAR(50),
    customer_zip_code_prefix NVARCHAR(10),
    customer_city            NVARCHAR(100),
    customer_state           NVARCHAR(5)
);


IF OBJECT_ID('bronze.crm_orders', 'U') IS NOT NULL
    DROP TABLE bronze.crm_orders;

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


IF OBJECT_ID('bronze.crm_order_items', 'U') IS NOT NULL
    DROP TABLE bronze.crm_order_items;

CREATE TABLE bronze.crm_order_items (
    order_id          NVARCHAR(50),
    order_item_id     NVARCHAR(10),
    product_id        NVARCHAR(50),
    seller_id         NVARCHAR(50),
    shipping_limit_date NVARCHAR(30),
    price             NVARCHAR(20),
    freight_value     NVARCHAR(20)
);


IF OBJECT_ID('bronze.crm_order_payments', 'U') IS NOT NULL
    DROP TABLE bronze.crm_order_payments;

CREATE TABLE bronze.crm_order_payments (
    order_id            NVARCHAR(50),
    payment_sequential  NVARCHAR(10),
    payment_type        NVARCHAR(30),
    payment_installments NVARCHAR(10),
    payment_value       NVARCHAR(20)
);


IF OBJECT_ID('bronze.crm_order_reviews', 'U') IS NOT NULL
    DROP TABLE bronze.crm_order_reviews;

CREATE TABLE bronze.crm_order_reviews (
    review_id              NVARCHAR(50),
    order_id               NVARCHAR(50),
    review_score           NVARCHAR(5),
    review_comment_title   NVARCHAR(200),
    review_comment_message NVARCHAR(MAX),
    review_creation_date   NVARCHAR(30),
    review_answer_timestamp NVARCHAR(30)
);


/*
===============================================================================
2. ERP SOURCE TABLES
===============================================================================
*/

IF OBJECT_ID('bronze.erp_products', 'U') IS NOT NULL
    DROP TABLE bronze.erp_products;

CREATE TABLE bronze.erp_products (
    product_id                  NVARCHAR(50),
    product_category_name       NVARCHAR(100),
    product_name_length         NVARCHAR(10),
    product_description_length  NVARCHAR(10),
    product_photos_qty          NVARCHAR(10),
    product_weight_g            NVARCHAR(10),
    product_length_cm           NVARCHAR(10),
    product_height_cm           NVARCHAR(10),
    product_width_cm            NVARCHAR(10)
);


IF OBJECT_ID('bronze.erp_sellers', 'U') IS NOT NULL
    DROP TABLE bronze.erp_sellers;

CREATE TABLE bronze.erp_sellers (
    seller_id              NVARCHAR(50),
    seller_zip_code_prefix NVARCHAR(10),
    seller_city            NVARCHAR(100),
    seller_state           NVARCHAR(5)
);


IF OBJECT_ID('bronze.erp_geolocation', 'U') IS NOT NULL
    DROP TABLE bronze.erp_geolocation;

CREATE TABLE bronze.erp_geolocation (
    geolocation_zip_code_prefix NVARCHAR(10),
    geolocation_lat             NVARCHAR(30),
    geolocation_lng             NVARCHAR(30),
    geolocation_city            NVARCHAR(100),
    geolocation_state           NVARCHAR(5)
);


IF OBJECT_ID('bronze.erp_category_translation', 'U') IS NOT NULL
    DROP TABLE bronze.erp_category_translation;

CREATE TABLE bronze.erp_category_translation (
    product_category_name          NVARCHAR(100),
    product_category_name_english  NVARCHAR(100)
);

GO

PRINT '>>> Bronze Layer DDL Executed Successfully (9 Tables Created) <<<';
