
/*
===============================================================================
01 - Business Overview
===============================================================================

Business Question:
    How is the business performing overall?

This analysis provides the main business KPIs:
    - Total Revenue
    - Total Orders
    - Unique Customers
    - Products Sold
    - Active Sellers
    - Average Order Value
    - Average Delivery Time
    - Late Delivery Rate
    - Delivered Orders Rate
    - Cancelled / Unavailable Orders Rate
    - Dataset Date Range

Note:
    fact_sales is at order-item level, so order-level metrics are calculated
    at order level first to avoid double counting orders.

Revenue:
    Revenue includes items from orders that were not cancelled or unavailable.

Customer:
    customer_unique_id is used to identify unique customers across orders.
===============================================================================
*/


-- =============================================================================
-- 1. Business Overview
-- =============================================================================

WITH order_level AS
(
    SELECT
        fs.order_id,

        -- Revenue per order
        SUM(
            CASE
                WHEN fs.order_status NOT IN ('canceled', 'unavailable')
                THEN fs.total_item_value
                ELSE 0
            END
        ) AS order_revenue,

        MAX(fs.order_status) AS order_status,

        MAX(fs.purchased_at) AS purchased_at,
        MAX(fs.delivered_at) AS delivered_at,
        MAX(fs.estimated_delivery_at) AS estimated_delivery_at,

        MAX(fs.delivery_days) AS delivery_days

    FROM gold.fact_sales fs
    GROUP BY
        fs.order_id
),

customer_count AS
(
    SELECT
        COUNT(DISTINCT customer_unique_id) AS unique_customers
    FROM gold.dim_customers
),

seller_count AS
(
    SELECT
        COUNT(DISTINCT seller_key) AS active_sellers
    FROM gold.fact_sales
    WHERE seller_key IS NOT NULL
),

product_count AS
(
    SELECT
        COUNT(*) AS products_sold
    FROM gold.fact_sales
),

date_range AS
(
    SELECT
        CAST(MIN(purchased_at) AS DATE) AS first_order_date,
        CAST(MAX(purchased_at) AS DATE) AS last_order_date
    FROM order_level
),

overview AS
(
    SELECT

        -- Total Revenue
        SUM(order_revenue) AS total_revenue,

        -- Total Orders
        COUNT(DISTINCT order_id) AS total_orders,

        -- Average Order Value
        SUM(order_revenue)
            / NULLIF(
                COUNT(
                    CASE
                        WHEN order_revenue > 0 THEN order_id
                    END
                ),
                0
            ) AS average_order_value,

        -- Average Delivery Time
        AVG(
            CASE
                WHEN delivered_at IS NOT NULL
                THEN delivery_days
            END
        ) AS average_delivery_days,

        -- Late Delivery Rate
        CAST(
            SUM(
                CASE
                    WHEN delivered_at IS NOT NULL
                     AND estimated_delivery_at IS NOT NULL
                     AND delivered_at > estimated_delivery_at
                    THEN 1
                    ELSE 0
                END
            ) AS DECIMAL(18,4)
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN delivered_at IS NOT NULL
                     AND estimated_delivery_at IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ) AS late_delivery_rate,

        -- Delivered Orders Rate
        CAST(
            SUM(
                CASE
                    WHEN order_status = 'delivered'
                    THEN 1
                    ELSE 0
                END
            ) AS DECIMAL(18,4)
        )
        / NULLIF(COUNT(*), 0) AS delivered_order_rate,

        -- Cancelled / Unavailable Orders Rate
        CAST(
            SUM(
                CASE
                    WHEN order_status IN ('canceled', 'unavailable')
                    THEN 1
                    ELSE 0
                END
            ) AS DECIMAL(18,4)
        )
        / NULLIF(COUNT(*), 0) AS cancelled_unavailable_rate

    FROM order_level
)


SELECT
    o.total_orders,
    o.total_revenue,
    c.unique_customers,
    p.products_sold,
    s.active_sellers,
    o.average_order_value,
    o.average_delivery_days,
    o.late_delivery_rate,
    o.delivered_order_rate,
    o.cancelled_unavailable_rate,
    d.first_order_date,
    d.last_order_date

FROM overview o
CROSS JOIN customer_count c
CROSS JOIN seller_count s
CROSS JOIN product_count p
CROSS JOIN date_range d;

GO
