# Data Catalog

This catalog documents all tables and columns across the Bronze, Silver, and Gold layers of the Olist Data Warehouse.

---

## 🥉 Bronze / 🥈 Silver Layer

The Silver Layer mirrors the Bronze Layer's structure, applying type casting, trimming, standardization, and deduplication on top of it. Column names and types below reflect the **Silver Layer** (the layer used for reporting-ready analysis and as the source for the Gold Layer).

### `silver.crm_customers`
One row per customer record (note: `customer_unique_id` may repeat — the same person can place multiple orders under different `customer_id` values).

| Column | Type | Description |
|---|---|---|
| `customer_id` | VARCHAR | Primary key. Unique identifier for a customer order-record. |
| `customer_unique_id` | VARCHAR | Unique identifier for the actual person; repeats across multiple orders by design. |
| `customer_zip_code_prefix` | VARCHAR | First digits of the customer's zip code. |
| `customer_city` | VARCHAR | Customer's city, standardized to uppercase. |
| `customer_state` | VARCHAR | Customer's state (Brazilian state code), standardized to uppercase. |
| `dwh_create_date` | DATETIME | Timestamp when the row was loaded into Silver. |

### `silver.crm_orders`
One row per order.

| Column | Type | Description |
|---|---|---|
| `order_id` | VARCHAR | Primary key. Unique identifier for an order. |
| `customer_id` | VARCHAR | Foreign key → `crm_customers.customer_id`. |
| `order_status` | VARCHAR | Order status (e.g. delivered, shipped, canceled), lowercase standardized. |
| `order_purchase_timestamp` | DATETIME2 | When the order was placed. |
| `order_approved_at` | DATETIME2 | When the payment was approved. |
| `order_delivered_carrier_date` | DATETIME2 | When the order was handed to the logistics carrier. |
| `order_delivered_customer_date` | DATETIME2 | When the order was actually delivered to the customer. |
| `order_estimated_delivery_date` | DATETIME2 | Estimated delivery date shown to the customer at purchase time. |
| `dwh_create_date` | DATETIME | Timestamp when the row was loaded into Silver. |

### `silver.crm_order_items`
One row per item within an order (composite primary key).

| Column | Type | Description |
|---|---|---|
| `order_id` | VARCHAR | Composite primary key (part 1). Foreign key → `crm_orders.order_id`. |
| `order_item_id` | SMALLINT | Composite primary key (part 2). Sequential item number within the order. |
| `product_id` | VARCHAR | Foreign key → `erp_products.product_id`. |
| `seller_id` | VARCHAR | Foreign key → `erp_sellers.seller_id`. |
| `shipping_limit_date` | DATETIME2 | Seller's shipping deadline for this item. |
| `price` | DECIMAL(10,2) | Item price. |
| `freight_value` | DECIMAL(10,2) | Shipping cost for this item. |
| `dwh_create_date` | DATETIME | Timestamp when the row was loaded into Silver. |

### `silver.crm_order_payments`
One row per payment installment (composite primary key).

| Column | Type | Description |
|---|---|---|
| `order_id` | VARCHAR | Composite primary key (part 1). Foreign key → `crm_orders.order_id`. |
| `payment_sequential` | SMALLINT | Composite primary key (part 2). Sequence number of this payment for the order. |
| `payment_type` | VARCHAR | Payment method (credit_card, boleto, voucher, etc.), lowercase standardized. |
| `payment_installments` | SMALLINT | Number of installments chosen. |
| `payment_value` | DECIMAL(10,2) | Amount paid in this installment. |
| `dwh_create_date` | DATETIME | Timestamp when the row was loaded into Silver. |

### `silver.erp_products`
One row per product.

| Column | Type | Description |
|---|---|---|
| `product_id` | VARCHAR | Primary key. Unique identifier for a product. |
| `product_category_name` | VARCHAR | Product category name (Portuguese, original source language). |
| `product_name_length` | INT | Character length of the product name. |
| `product_description_length` | INT | Character length of the product description. |
| `product_photos_qty` | SMALLINT | Number of photos listed for the product. |
| `product_weight_g` | INT | Product weight in grams. |
| `product_length_cm` | DECIMAL(8,2) | Product length in centimeters. |
| `product_height_cm` | DECIMAL(8,2) | Product height in centimeters. |
| `product_width_cm` | DECIMAL(8,2) | Product width in centimeters. |
| `dwh_create_date` | DATETIME | Timestamp when the row was loaded into Silver. |

### `silver.erp_sellers`
One row per seller.

| Column | Type | Description |
|---|---|---|
| `seller_id` | VARCHAR | Primary key. Unique identifier for a seller. |
| `seller_zip_code_prefix` | VARCHAR | First digits of the seller's zip code. |
| `seller_city` | VARCHAR | Seller's city, standardized to uppercase. |
| `seller_state` | VARCHAR | Seller's state (Brazilian state code), standardized to uppercase. |
| `dwh_create_date` | DATETIME | Timestamp when the row was loaded into Silver. |

### `silver.erp_geolocation`
One row per geolocation coordinate point. **Note**: multiple rows share the same `geolocation_zip_code_prefix` by design (multiple lat/lng points per zip area) — this is not a data quality issue.

| Column | Type | Description |
|---|---|---|
| `geolocation_zip_code_prefix` | VARCHAR | Zip code prefix (not unique — see note above). |
| `geolocation_lat` | DECIMAL(10,8) | Latitude. |
| `geolocation_lng` | DECIMAL(11,8) | Longitude. |
| `geolocation_city` | VARCHAR | City name, standardized to uppercase. |
| `geolocation_state` | VARCHAR | State code, standardized to uppercase. |
| `dwh_create_date` | DATETIME | Timestamp when the row was loaded into Silver. |

### `silver.erp_category_translation`
One row per product category.

| Column | Type | Description |
|---|---|---|
| `product_category_name` | VARCHAR | Primary key. Category name in Portuguese. |
| `product_category_name_english` | VARCHAR | Category name translated to English. |
| `dwh_create_date` | DATETIME | Timestamp when the row was loaded into Silver. |

---

## 🥇 Gold Layer (Star Schema)

Business-friendly views built on top of the Silver Layer. Column names are aliased for direct use in reporting tools.

### `gold.dim_customers`
Grain: one row per `customer_id`.

| Column | Description |
|---|---|
| `customer_key` | Surrogate key (generated). |
| `customer_id` | Natural key. |
| `customer_unique_id` | Unique person identifier. |
| `city` | Customer's city. |
| `state` | Customer's state. |
| `zip_code` | Customer's zip code prefix. |
| `latitude` / `longitude` | Approximate coordinates, averaged from `erp_geolocation` per zip code. |

### `gold.dim_sellers`
Grain: one row per `seller_id`.

| Column | Description |
|---|---|
| `seller_key` | Surrogate key (generated). |
| `seller_id` | Natural key. |
| `city` | Seller's city. |
| `state` | Seller's state. |
| `zip_code` | Seller's zip code prefix. |
| `latitude` / `longitude` | Approximate coordinates, averaged from `erp_geolocation` per zip code. |

### `gold.dim_products`
Grain: one row per `product_id`.

| Column | Description |
|---|---|
| `product_key` | Surrogate key (generated). |
| `product_id` | Natural key. |
| `category_name` | Category name (Portuguese). |
| `category_name_english` | Category name (English). |
| `name_length` | Character length of the product name. |
| `description_length` | Character length of the product description. |
| `photos_count` | Number of photos. |
| `weight_grams` | Product weight in grams. |
| `length_cm` / `height_cm` / `width_cm` | Product dimensions. |

### `gold.dim_date`
Grain: one row per distinct calendar date found in `order_purchase_timestamp`.

| Column | Description |
|---|---|
| `date_key` | Calendar date (join key to fact tables). |
| `year` | Calendar year. |
| `month_number` / `month_name` | Month number and name. |
| `day_number` / `day_name` | Day of month and weekday name. |
| `quarter` | Calendar quarter. |

### `gold.fact_sales`
Grain: one row per order item (`order_id` + `order_item_id`).

| Column | Description |
|---|---|
| `order_id` / `order_item_id` | Order and item identifiers. |
| `customer_key` | FK → `dim_customers`. |
| `seller_key` | FK → `dim_sellers`. |
| `product_key` | FK → `dim_products`. |
| `date_key` | FK → `dim_date`. |
| `order_status` | Order status. |
| `item_price` | Price of the item. |
| `shipping_cost` | Freight value for the item. |
| `total_item_value` | Computed: `item_price + shipping_cost`. |
| `purchased_at` | Purchase timestamp. |
| `delivered_at` | Actual delivery timestamp. |
| `estimated_delivery_at` | Estimated delivery date. |
| `delivery_days` | Computed: days between purchase and actual delivery. |

### `gold.fact_payments`
Grain: one row per payment installment (`order_id` + `payment_sequential`).

| Column | Description |
|---|---|
| `order_id` | Order identifier. |
| `payment_sequence` | Installment sequence number. |
| `payment_method` | Payment type. |
| `installments_count` | Number of installments chosen. |
| `payment_amount` | Amount paid in this installment. |
| `date_key` | FK → `dim_date`. |
