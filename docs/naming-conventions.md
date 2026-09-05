# Naming Conventions

This document defines the naming conventions used across schemas, tables, columns, and scripts in this project.

---

## General Principles

- Use **snake_case** for all schema, table, and column names (lowercase, underscores between words).
- Names should be descriptive in English, even though some source category values (product categories) originate in Portuguese.
- Avoid abbreviations unless they are widely understood (`id`, `qty`, `dt` are acceptable; avoid inventing new ones).

---

## Schemas

Each layer of the Medallion Architecture lives in its own schema:

| Schema | Purpose |
|---|---|
| `bronze` | Raw, unmodified data as loaded from source CSV files. |
| `silver` | Cleaned, validated, standardized data. |
| `gold` | Business-ready views modeled as a star schema. |

---

## Tables (Bronze & Silver)

Tables are prefixed by their **source system**, followed by the entity name:

- `crm_<entity>` — tables originating from the order/customer transactional system (customers, orders, order items, payments).
- `erp_<entity>` — tables originating from the product/seller/geolocation reference data.

Examples: `crm_customers`, `crm_orders`, `erp_products`, `erp_sellers`.

Silver tables keep the **same name** as their Bronze counterpart — only the contents are cleaned, not the table name.

---

## Columns

- Primary keys use the entity name + `_id` (e.g. `customer_id`, `order_id`, `product_id`, `seller_id`).
- Foreign keys use the **same column name** as the primary key they reference, for clarity (e.g. `crm_orders.customer_id` references `crm_customers.customer_id`).
- Boolean-like or categorical columns are standardized to lowercase (e.g. `order_status`, `payment_type`) unless the source values are proper nouns (e.g. city/state names, standardized to uppercase).
- Metadata columns added by the ETL process are prefixed with `dwh_` (e.g. `dwh_create_date`), to distinguish them clearly from source data.
- Misspelled source column names (e.g. `product_name_lenght`) are corrected in the Silver layer (`product_name_length`) and documented as such in the data catalog.

---

## Gold Layer (Star Schema)

- Dimension views are prefixed `dim_` (e.g. `dim_customers`, `dim_products`).
- Fact views are prefixed `fact_` (e.g. `fact_sales`, `fact_payments`).
- Surrogate keys generated for dimensions are named `<entity>_key` (e.g. `customer_key`, `product_key`) and are separate from the natural key (`customer_id`, `product_id`), which is also kept for traceability.
- Column aliases in the Gold Layer favor **business-friendly names** over raw source names (e.g. `item_price` instead of `price`, `shipping_cost` instead of `freight_value`), since this layer is meant to be consumed directly by reporting tools.

---

## Scripts

- One script per layer per responsibility, organized under `scripts/bronze/`, `scripts/silver/`, `scripts/gold/`.
- Stored procedures follow the pattern `<schema>.load_<layer>` (e.g. `silver.load_silver`).
- Data quality scripts live under `tests/` and are named descriptively (e.g. `quality_checks.sql`).

---

## Dates & Timestamps

- Raw date/time columns keep their original source name and meaning (e.g. `order_purchase_timestamp`).
- Computed date/time metadata (ETL load timestamps) always use the `dwh_` prefix.
