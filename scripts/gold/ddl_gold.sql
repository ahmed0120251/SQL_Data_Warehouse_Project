/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold layer represents the final business-ready dimension and fact views
    following a Star Schema design.

    Each view combines and transforms data from the Silver layer to provide
    clean, enriched, and business-friendly datasets for analytics and reporting.

Design Notes:
    - Dimension and fact views are built directly on top of the Silver layer.
    - Business-friendly column names are used to simplify reporting and analysis.
    - Geolocation data is incorporated into customer and seller dimensions using
      the zip code prefix.
    - Multiple geolocation records for the same zip code prefix are aggregated
      when required.

Usage:
    - These views can be queried directly for analytics and reporting.
    - The Gold layer is designed to be consumed by tools such as Power BI.
===============================================================================
*/
-- =============================================================================
-- Dimension: gold.dim_customers
-- Grain: one row per customer_id
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY c.customer_id) AS customer_key,  -- Surrogate key
    c.customer_id                              AS customer_id,  -- Natural key
    c.customer_unique_id                       AS customer_unique_id, -- Repeats across orders by design (same person, multiple orders)
    c.customer_city                             AS city,
    c.customer_state                            AS state,
    c.customer_zip_code_prefix                  AS zip_code,
    g.avg_lat                                   AS latitude,     -- Approximate coordinates for the customer's zip area
    g.avg_lng                                   AS longitude
FROM silver.crm_customers c
LEFT JOIN (
    -- Geolocation has multiple lat/lng points per zip prefix; average them
    -- to get one representative coordinate pair per zip code
    SELECT
        geolocation_zip_code_prefix,
        AVG(geolocation_lat) AS avg_lat,
        AVG(geolocation_lng) AS avg_lng
    FROM silver.erp_geolocation
    GROUP BY geolocation_zip_code_prefix
) g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix;
GO


-- =============================================================================
-- Dimension: gold.dim_sellers
-- Grain: one row per seller_id
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_sellers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY s.seller_id) AS seller_key,  -- Surrogate key
    s.seller_id                              AS seller_id,   -- Natural key
    s.seller_city                             AS city,
    s.seller_state                            AS state,
    s.seller_zip_code_prefix                  AS zip_code,
    g.avg_lat                                 AS latitude,   -- Approximate coordinates for the seller's zip area
    g.avg_lng                                 AS longitude
FROM silver.erp_sellers s
LEFT JOIN (
    SELECT
        geolocation_zip_code_prefix,
        AVG(geolocation_lat) AS avg_lat,
        AVG(geolocation_lng) AS avg_lng
    FROM silver.erp_geolocation
    GROUP BY geolocation_zip_code_prefix
) g ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix;
GO


-- =============================================================================
-- Dimension: gold.dim_products
-- Grain: one row per product_id
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY p.product_id) AS product_key,  -- Surrogate key
    p.product_id                              AS product_id,  -- Natural key
    p.product_category_name                    AS category_name,          -- Original category name (Portuguese)
    t.product_category_name_english             AS category_name_english, -- Translated category name (English)
    p.product_name_length                       AS name_length,
    p.product_description_length                AS description_length,
    p.product_photos_qty                        AS photos_count,
    p.product_weight_g                          AS weight_grams,
    p.product_length_cm                         AS length_cm,
    p.product_height_cm                         AS height_cm,
    p.product_width_cm                          AS width_cm
FROM silver.erp_products p
LEFT JOIN silver.erp_category_translation t
    ON p.product_category_name = t.product_category_name;
GO


-- =============================================================================
-- Dimension: gold.dim_date
-- Grain: one row per distinct calendar date found in order_purchase_timestamp
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_date AS
SELECT DISTINCT
    CAST(order_purchase_timestamp AS DATE)      AS date_key,      -- Join key to fact tables
    YEAR(order_purchase_timestamp)              AS year,
    MONTH(order_purchase_timestamp)             AS month_number,
    DATENAME(MONTH, order_purchase_timestamp)   AS month_name,
    DAY(order_purchase_timestamp)               AS day_number,
    DATENAME(WEEKDAY, order_purchase_timestamp) AS day_name,
    DATEPART(QUARTER, order_purchase_timestamp) AS quarter
FROM silver.crm_orders
WHERE order_purchase_timestamp IS NOT NULL;
GO


-- =============================================================================
-- Fact: gold.fact_sales
-- Grain: one row per order item (order_id + order_item_id)
-- =============================================================================
CREATE OR ALTER VIEW gold.fact_sales AS
SELECT
    oi.order_id                              AS order_id,
    oi.order_item_id                         AS order_item_id,
    cu.customer_key                          AS customer_key,       -- FK to dim_customers
    se.seller_key                            AS seller_key,         -- FK to dim_sellers
    pr.product_key                           AS product_key,        -- FK to dim_products
    CAST(o.order_purchase_timestamp AS DATE) AS date_key,           -- FK to dim_date
    o.order_status                           AS order_status,
    oi.price                                 AS item_price,
    oi.freight_value                         AS shipping_cost,
    oi.price + oi.freight_value              AS total_item_value,   -- Computed measure
    o.order_purchase_timestamp               AS purchased_at,
    o.order_delivered_customer_date          AS delivered_at,
    o.order_estimated_delivery_date          AS estimated_delivery_at,
    DATEDIFF(
        DAY,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date
    )                                        AS delivery_days       -- Computed measure: actual delivery time in days
FROM silver.crm_order_items oi
JOIN silver.crm_orders o        ON oi.order_id = o.order_id
LEFT JOIN gold.dim_customers cu ON o.customer_id = cu.customer_id
LEFT JOIN gold.dim_sellers se   ON oi.seller_id = se.seller_id
LEFT JOIN gold.dim_products pr  ON oi.product_id = pr.product_id;
GO


-- =============================================================================
-- Fact: gold.fact_payments
-- Grain: one row per payment installment (order_id + payment_sequential)
-- =============================================================================
CREATE OR ALTER VIEW gold.fact_payments AS
SELECT
    p.order_id                               AS order_id,
    p.payment_sequential                     AS payment_sequence,
    p.payment_type                           AS payment_method,
    p.payment_installments                   AS installments_count,
    p.payment_value                          AS payment_amount,
    CAST(o.order_purchase_timestamp AS DATE) AS date_key            -- FK to dim_date
FROM silver.crm_order_payments p
JOIN silver.crm_orders o ON p.order_id = o.order_id;
GO
