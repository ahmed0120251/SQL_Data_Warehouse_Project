# Data Catalog for Gold Layer

## Overview
The Gold Layer is the business-level data representation, structured to support analytical and reporting use cases. It consists of dimension tables and fact tables for specific business metrics.

---

### 1. gold.dim_customers
**Purpose:** Stores customer details enriched with geographic and location data.

**Columns:**

| Column Name | Data Type | Description |
|---|---|---|
| customer_key | INT | Surrogate key uniquely identifying each customer record in the dimension table. |
| customer_id | NVARCHAR(50) | Unique identifier assigned to each customer order-record in the source system. |
| customer_unique_id | NVARCHAR(50) | Unique identifier for the actual person; may repeat across multiple orders by the same customer. |
| city | NVARCHAR(50) | The city of residence for the customer. |
| state | NVARCHAR(50) | The Brazilian state code of residence for the customer (e.g., 'SP', 'RJ'). |
| zip_code | NVARCHAR(50) | The zip code prefix of the customer's location. |
| latitude | DECIMAL(10,8) | Approximate latitude for the customer's zip code area, averaged from geolocation data. |
| longitude | DECIMAL(11,8) | Approximate longitude for the customer's zip code area, averaged from geolocation data. |

---

### 2. gold.dim_sellers
**Purpose:** Provides information about sellers and their location.

**Columns:**

| Column Name | Data Type | Description |
|---|---|---|
| seller_key | INT | Surrogate key uniquely identifying each seller record in the dimension table. |
| seller_id | NVARCHAR(50) | Unique identifier assigned to each seller in the source system. |
| city | NVARCHAR(50) | The city where the seller is located. |
| state | NVARCHAR(50) | The Brazilian state code where the seller is located (e.g., 'SP', 'MG'). |
| zip_code | NVARCHAR(50) | The zip code prefix of the seller's location. |
| latitude | DECIMAL(10,8) | Approximate latitude for the seller's zip code area, averaged from geolocation data. |
| longitude | DECIMAL(11,8) | Approximate longitude for the seller's zip code area, averaged from geolocation data. |

---

### 3. gold.dim_products
**Purpose:** Provides information about the products and their physical attributes.

**Columns:**

| Column Name | Data Type | Description |
|---|---|---|
| product_key | INT | Surrogate key uniquely identifying each product record in the dimension table. |
| product_id | NVARCHAR(50) | A unique identifier assigned to the product for internal tracking and referencing. |
| category_name | NVARCHAR(50) | The product's category name, in the original source language (Portuguese). |
| category_name_english | NVARCHAR(50) | The product's category name, translated to English. |
| name_length | INT | Character length of the product's listed name. |
| description_length | INT | Character length of the product's listed description. |
| photos_count | SMALLINT | Number of photos listed for the product. |
| weight_grams | INT | The product's weight, measured in grams. |
| length_cm | DECIMAL(8,2) | The product's length, measured in centimeters. |
| height_cm | DECIMAL(8,2) | The product's height, measured in centimeters. |
| width_cm | DECIMAL(8,2) | The product's width, measured in centimeters. |

---

### 4. gold.dim_date
**Purpose:** Provides a calendar reference for time-based analysis across the fact tables.

**Columns:**

| Column Name | Data Type | Description |
|---|---|---|
| date_key | DATE | The calendar date, used as the join key to fact tables (e.g., '2017-05-14'). |
| year | INT | The calendar year of the date (e.g., 2017). |
| month_number | INT | The numeric month of the date (1-12). |
| month_name | NVARCHAR(50) | The name of the month (e.g., 'May'). |
| day_number | INT | The day of the month (1-31). |
| day_name | NVARCHAR(50) | The name of the weekday (e.g., 'Sunday'). |
| quarter | INT | The calendar quarter of the date (1-4). |

---

### 5. gold.fact_sales
**Purpose:** Stores transactional order-item-level sales data for analytical purposes.

**Columns:**

| Column Name | Data Type | Description |
|---|---|---|
| order_id | NVARCHAR(50) | A unique identifier for each sales order (e.g., 'e481f51cbdc54678b7cc49136f2d6af7'). |
| order_item_id | SMALLINT | Sequential identifier of the item within the order (e.g., 1, 2, 3). |
| customer_key | INT | Surrogate key linking the order to the customer dimension table. |
| seller_key | INT | Surrogate key linking the order item to the seller dimension table. |
| product_key | INT | Surrogate key linking the order item to the product dimension table. |
| date_key | DATE | Surrogate key linking the order to the date dimension table. |
| order_status | NVARCHAR(50) | The status of the order (e.g., 'delivered', 'shipped', 'canceled'). |
| item_price | DECIMAL(10,2) | The price of the product for this line item, in monetary units (e.g., 89.90). |
| shipping_cost | DECIMAL(10,2) | The freight/shipping cost for this line item, in monetary units (e.g., 15.50). |
| total_item_value | DECIMAL(10,2) | The total monetary value of the line item (item_price + shipping_cost). |
| purchased_at | DATETIME2 | The date and time when the order was placed. |
| delivered_at | DATETIME2 | The date and time when the order was actually delivered to the customer. |
| estimated_delivery_at | DATETIME2 | The estimated delivery date shown to the customer at purchase time. |
| delivery_days | INT | The number of days between the purchase date and the actual delivery date. |

---

### 6. gold.fact_payments
**Purpose:** Stores transactional payment data for analytical purposes.

**Columns:**

| Column Name | Data Type | Description |
|---|---|---|
| order_id | NVARCHAR(50) | A unique identifier for the order this payment belongs to. |
| payment_sequence | SMALLINT | The sequence number of this payment installment for the order (e.g., 1, 2). |
| payment_method | NVARCHAR(50) | The payment method used (e.g., 'credit_card', 'boleto', 'voucher'). |
| installments_count | SMALLINT | The number of installments chosen for this payment. |
| payment_amount | DECIMAL(10,2) | The monetary amount paid in this installment, in monetary units (e.g., 120.50). |
| date_key | DATE | Surrogate key linking the payment to the date dimension table. |
