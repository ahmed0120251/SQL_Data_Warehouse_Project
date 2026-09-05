/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency, 
    and accuracy of the Gold Layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.
Usage Notes:
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'gold.dim_customers'
-- ====================================================================
-- Check for Uniqueness of Customer Key in gold.dim_customers
-- Expectation: No results 
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.dim_sellers'
-- ====================================================================
-- Check for Uniqueness of Seller Key in gold.dim_sellers
-- Expectation: No results 
SELECT 
    seller_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_sellers
GROUP BY seller_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.dim_products'
-- ====================================================================
-- Check for Uniqueness of Product Key in gold.dim_products
-- Expectation: No results 
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.dim_date'
-- ====================================================================
-- Check for Uniqueness of Date Key in gold.dim_date
-- Expectation: No results 
SELECT 
    date_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_date
GROUP BY date_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.fact_sales'
-- ====================================================================
-- Check the data model connectivity between fact_sales and its dimensions
-- Expectation: No results 
SELECT * 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_sellers s
    ON s.seller_key = f.seller_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
LEFT JOIN gold.dim_date d
    ON d.date_key = f.date_key
WHERE c.customer_key IS NULL 
   OR s.seller_key IS NULL 
   OR p.product_key IS NULL 
   OR d.date_key IS NULL;

-- ====================================================================
-- Checking 'gold.fact_payments'
-- ====================================================================
-- Check the data model connectivity between fact_payments and gold.dim_date
-- Expectation: No results 
SELECT * 
FROM gold.fact_payments f
LEFT JOIN gold.dim_date d
    ON d.date_key = f.date_key
WHERE d.date_key IS NULL;
