
/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' layer. It includes checks for:
    - NULL or duplicate values in primary and composite keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid or inconsistent date values.
    - Invalid or negative numeric values.
    - Missing or unrealistic values.
    - Referential integrity between related tables.
    - Row count reconciliation between Bronze and Silver layers.

Usage Notes:
    - Run these checks after loading data into the Silver Layer.
    - Review the results of each check and investigate any unexpected records.
    - Checks marked with "Expectation: No Results" should return no records.
===============================================================================
*/

-- ====================================================================
-- Checking 'silver.crm_customers'
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results


SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_customers
GROUP BY customer_id
HAVING COUNT(*) > 1 OR customer_id IS NULL;

-- Check for leading or trailing spaces in text columns
-- Expectation: No Results
SELECT customer_id      FROM silver.crm_customers WHERE customer_id      != TRIM(customer_id);
SELECT customer_city    FROM silver.crm_customers WHERE customer_city    != TRIM(customer_city);
SELECT customer_state   FROM silver.crm_customers WHERE customer_state   != TRIM(customer_state);

-- Check distinct values for data consistency
SELECT DISTINCT customer_state FROM silver.crm_customers ORDER BY customer_state;
SELECT DISTINCT customer_city  FROM silver.crm_customers ORDER BY customer_city;

-- Check zip code prefix format
-- Olist zip code prefixes are numeric and should not exceed 5 digits
-- Expectation: No Results
SELECT customer_zip_code_prefix
FROM silver.crm_customers
WHERE customer_zip_code_prefix IS NULL
   OR LEN(customer_zip_code_prefix) > 5;

-- customer_unique_id can appear multiple times because the same customer
-- may have more than one customer_id in the source data.
-- This check is informational and does not indicate a data quality issue.
SELECT customer_unique_id, COUNT(*) AS orders_count
FROM silver.crm_customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
ORDER BY orders_count DESC;


-- #############################################################################
-- # Checking 'silver.crm_orders'
-- #############################################################################

-- Check for NULLs or duplicate values in the primary key (order_id)
-- Expectation: No Results
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_orders
GROUP BY order_id
HAVING COUNT(*) > 1 OR order_id IS NULL;

-- Check for leading or trailing spaces in text columns
-- Expectation: No Results
SELECT order_id      FROM silver.crm_orders WHERE order_id      != TRIM(order_id);
SELECT order_status  FROM silver.crm_orders WHERE order_status  != TRIM(order_status);

-- Check distinct order status values for consistency
SELECT DISTINCT order_status FROM silver.crm_orders ORDER BY order_status;

-- Check the logical sequence of order-related dates
-- Expectation: No Results
SELECT *
FROM silver.crm_orders
WHERE order_approved_at < order_purchase_timestamp
   OR order_delivered_carrier_date < order_approved_at
   OR order_delivered_customer_date < order_delivered_carrier_date;

-- Identify delivered orders that were completed after the estimated
-- delivery date. This is informational and may require further analysis.
SELECT *
FROM silver.crm_orders
WHERE order_delivered_customer_date > order_estimated_delivery_date
  AND order_status = 'delivered';

-- Check for missing dates on orders marked as delivered
-- Expectation: No Results
SELECT *
FROM silver.crm_orders
WHERE order_status = 'delivered'
  AND (order_delivered_customer_date IS NULL OR order_approved_at IS NULL);

-- Check for purchase dates outside the expected dataset time range
-- Expectation: No Results
SELECT order_purchase_timestamp
FROM silver.crm_orders
WHERE order_purchase_timestamp < '2016-01-01'
   OR order_purchase_timestamp > GETDATE();


-- #############################################################################
-- # Checking 'silver.crm_order_items'
-- #############################################################################

-- Check for NULLs or duplicate values in the composite primary key
-- (order_id + order_item_id)
-- Expectation: No Results
SELECT
    order_id,
    order_item_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1 OR order_id IS NULL OR order_item_id IS NULL;

-- Check for leading or trailing spaces in key text columns
-- Expectation: No Results
SELECT order_id  FROM silver.crm_order_items WHERE order_id  != TRIM(order_id);
SELECT product_id FROM silver.crm_order_items WHERE product_id != TRIM(product_id);
SELECT seller_id  FROM silver.crm_order_items WHERE seller_id  != TRIM(seller_id);

-- Check for NULL, zero, or negative values in price and freight_value
-- Expectation: No Results
SELECT price FROM silver.crm_order_items WHERE price IS NULL OR price <= 0;
SELECT freight_value FROM silver.crm_order_items WHERE freight_value IS NULL OR freight_value < 0;

-- Check shipping_limit_date for missing or unrealistic values
-- Expectation: No Results
SELECT shipping_limit_date
FROM silver.crm_order_items
WHERE shipping_limit_date IS NULL
   OR shipping_limit_date < '2016-01-01'
   OR shipping_limit_date > '2050-01-01';


-- #############################################################################
-- # Checking 'silver.crm_order_payments'
-- #############################################################################

-- Check for NULLs or duplicate values in the composite primary key
-- (order_id + payment_sequential)
-- Expectation: No Results
SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS duplicate_count
FROM silver.crm_order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1 OR order_id IS NULL OR payment_sequential IS NULL;

-- Check for leading or trailing spaces in text columns
-- Expectation: No Results
SELECT order_id      FROM silver.crm_order_payments WHERE order_id      != TRIM(order_id);
SELECT payment_type  FROM silver.crm_order_payments WHERE payment_type  != TRIM(payment_type);

-- Check distinct payment types for consistency
SELECT DISTINCT payment_type FROM silver.crm_order_payments ORDER BY payment_type;

-- Check for NULL or negative values in payment_value and installments
-- Expectation: No Results
SELECT payment_value FROM silver.crm_order_payments WHERE payment_value IS NULL OR payment_value < 0;
SELECT payment_installments FROM silver.crm_order_payments WHERE payment_installments IS NULL OR payment_installments < 0;


-- #############################################################################
-- # Checking 'silver.erp_products'
-- #############################################################################

-- Check for NULLs or duplicate values in the primary key (product_id)
-- Expectation: No Results
SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM silver.erp_products
GROUP BY product_id
HAVING COUNT(*) > 1 OR product_id IS NULL;

-- Check for leading or trailing spaces in text columns
-- Expectation: No Results
SELECT product_id             FROM silver.erp_products WHERE product_id             != TRIM(product_id);
SELECT product_category_name  FROM silver.erp_products WHERE product_category_name  != TRIM(product_category_name);

-- Check distinct product categories for consistency
SELECT DISTINCT product_category_name FROM silver.erp_products ORDER BY product_category_name;

-- Check for NULL or negative values in product attributes
-- Expectation: No Results
SELECT product_weight_g   FROM silver.erp_products WHERE product_weight_g   IS NULL OR product_weight_g   < 0;
SELECT product_length_cm  FROM silver.erp_products WHERE product_length_cm  IS NULL OR product_length_cm  <= 0;
SELECT product_height_cm  FROM silver.erp_products WHERE product_height_cm  IS NULL OR product_height_cm  <= 0;
SELECT product_width_cm   FROM silver.erp_products WHERE product_width_cm   IS NULL OR product_width_cm  <= 0;
SELECT product_photos_qty FROM silver.erp_products WHERE product_photos_qty IS NULL OR product_photos_qty < 0;

-- Check for unusually high product weights
-- Threshold can be adjusted based on business requirements
SELECT product_weight_g FROM silver.erp_products WHERE product_weight_g > 40000;


-- #############################################################################
-- # Checking 'silver.erp_sellers'
-- #############################################################################

-- Check for NULLs or duplicate values in the primary key (seller_id)
-- Expectation: No Results
SELECT
    seller_id,
    COUNT(*) AS duplicate_count
FROM silver.erp_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1 OR seller_id IS NULL;

-- Check for leading or trailing spaces in text columns
-- Expectation: No Results
SELECT seller_id    FROM silver.erp_sellers WHERE seller_id    != TRIM(seller_id);
SELECT seller_city  FROM silver.erp_sellers WHERE seller_city  != TRIM(seller_city);
SELECT seller_state FROM silver.erp_sellers WHERE seller_state != TRIM(seller_state);

-- Check distinct seller states for consistency
SELECT DISTINCT seller_state FROM silver.erp_sellers ORDER BY seller_state;


-- #############################################################################
-- # Checking 'silver.erp_geolocation'
-- #############################################################################

-- Note: This table naturally contains multiple records for the same
-- zip_code_prefix because a zip code area may contain multiple locations.
-- This is expected behavior and should not be treated as a duplicate issue.

-- Check for NULL values in key columns
-- Expectation: No Results
SELECT * FROM silver.erp_geolocation WHERE geolocation_zip_code_prefix IS NULL;

-- Check for leading or trailing spaces in text columns
-- Expectation: No Results
SELECT geolocation_city  FROM silver.erp_geolocation WHERE geolocation_city  != TRIM(geolocation_city);
SELECT geolocation_state FROM silver.erp_geolocation WHERE geolocation_state != TRIM(geolocation_state);

-- Check distinct states for consistency
SELECT DISTINCT geolocation_state FROM silver.erp_geolocation ORDER BY geolocation_state;

-- Check latitude and longitude values against the approximate geographic
-- boundaries of Brazil
-- Expectation: No Results
SELECT geolocation_lat, geolocation_lng
FROM silver.erp_geolocation
WHERE geolocation_lat  NOT BETWEEN -35 AND 6
   OR geolocation_lng  NOT BETWEEN -75 AND -30;


-- #############################################################################
-- # Checking 'silver.erp_category_translation'
-- #############################################################################

-- Check for NULLs or duplicate values in the primary key
-- (product_category_name)
-- Expectation: No Results
SELECT
    product_category_name,
    COUNT(*) AS duplicate_count
FROM silver.erp_category_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1 OR product_category_name IS NULL;

-- Check for leading or trailing spaces in text columns
-- Expectation: No Results
SELECT product_category_name          FROM silver.erp_category_translation WHERE product_category_name          != TRIM(product_category_name);
SELECT product_category_name_english  FROM silver.erp_category_translation WHERE product_category_name_english  != TRIM(product_category_name_english);

-- Check for missing English translations
-- Expectation: No Results
SELECT * FROM silver.erp_category_translation WHERE product_category_name_english IS NULL;


-- #############################################################################
-- # Referential Integrity Checks (Orphan Records Across Tables)
-- #############################################################################

-- Check that every customer referenced by an order exists in crm_customers
-- Expectation: No Results
SELECT o.customer_id
FROM silver.crm_orders o
LEFT JOIN silver.crm_customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL AND o.customer_id IS NOT NULL;

-- Check that every order referenced by an order item exists in crm_orders
-- Expectation: No Results
SELECT oi.order_id
FROM silver.crm_order_items oi
LEFT JOIN silver.crm_orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL AND oi.order_id IS NOT NULL;

-- Check that every product referenced by an order item exists in erp_products
-- Expectation: No Results
SELECT oi.product_id
FROM silver.crm_order_items oi
LEFT JOIN silver.erp_products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL AND oi.product_id IS NOT NULL;

-- Check that every seller referenced by an order item exists in erp_sellers
-- Expectation: No Results
SELECT oi.seller_id
FROM silver.crm_order_items oi
LEFT JOIN silver.erp_sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL AND oi.seller_id IS NOT NULL;

-- Check that every payment record is linked to an existing order
-- Expectation: No Results
SELECT pay.order_id
FROM silver.crm_order_payments pay
LEFT JOIN silver.crm_orders o ON pay.order_id = o.order_id
WHERE o.order_id IS NULL AND pay.order_id IS NOT NULL;

-- Check that every product category has a corresponding English translation
-- Expectation: No Results or a small known set of untranslated categories
SELECT p.product_category_name
FROM silver.erp_products p
LEFT JOIN silver.erp_category_translation t ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL AND p.product_category_name IS NOT NULL;


-- #############################################################################
-- # Row Count Reconciliation (Bronze vs Silver)
-- #############################################################################

SELECT 'crm_customers'      AS table_name, (SELECT COUNT(*) FROM bronze.crm_customers)      AS bronze_count, (SELECT COUNT(*) FROM silver.crm_customers)      AS silver_count
UNION ALL
SELECT 'crm_orders',                       (SELECT COUNT(*) FROM bronze.crm_orders),                        (SELECT COUNT(*) FROM silver.crm_orders)
UNION ALL
SELECT 'crm_order_items',                  (SELECT COUNT(*) FROM bronze.crm_order_items),                   (SELECT COUNT(*) FROM silver.crm_order_items)
UNION ALL
SELECT 'crm_order_payments',               (SELECT COUNT(*) FROM bronze.crm_order_payments),                (SELECT COUNT(*) FROM silver.crm_order_payments)
UNION ALL
SELECT 'erp_products',                     (SELECT COUNT(*) FROM bronze.erp_products),                      (SELECT COUNT(*) FROM silver.erp_products)
UNION ALL
SELECT 'erp_sellers',                      (SELECT COUNT(*) FROM bronze.erp_sellers),                       (SELECT COUNT(*) FROM silver.erp_sellers)
UNION ALL
SELECT 'erp_geolocation',                  (SELECT COUNT(*) FROM bronze.erp_geolocation),                   (SELECT COUNT(*) FROM silver.erp_geolocation)
UNION ALL
SELECT 'erp_category_translation',         (SELECT COUNT(*) FROM bronze.erp_category_translation),         (SELECT COUNT(*) FROM silver.erp_category_translation);
