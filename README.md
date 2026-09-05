# 📦 SQL_Data_Warehouse_Project
This project builds a data warehouse based on the **Olist Brazilian E-Commerce** public dataset. The goal is to unify, clean, and model raw e-commerce data (customers, orders, order items, payments, products, sellers, and geolocation) into a business-ready analytical model that supports reporting on sales performance, delivery, and customer behavior.

This project was built to demonstrate practical Data Engineering / BI skills: SQL Server T-SQL, ETL scripting, data quality validation, and dimensional (star schema) modeling — as part of a Data Analyst & BI portfolio.

---

## 🏗️ Data Architecture

The project follows the **Medallion Architecture** (Bronze → Silver → Gold):

- **Bronze Layer**: Raw data as-is, loaded from CSV source files into SQL Server with minimal to no transformation.
- **Silver Layer**: Cleaned, standardized, and validated data — type casting, trimming, deduplication on primary keys, and standardized categorical values.
- **Gold Layer**: Business-ready data modeled as a **Star Schema** (fact and dimension views), optimized for reporting and analytics tools such as Power BI.

```
Bronze (raw)  →  Silver (cleaned & validated)  →  Gold (star schema, business-ready)
```

---

## 📖 Project Overview

This project includes:

- **Data Architecture**: A modern data warehouse design using the Bronze/Silver/Gold layers described above.
- **ETL Pipelines**: Stored procedures that extract, transform (clean, cast, deduplicate), and load data between layers.
- **Data Quality Checks**: A dedicated set of validation scripts run after each Silver Layer load (null/duplicate primary keys, unwanted spaces, standardization, invalid dates, referential integrity, row count reconciliation).
- **Data Modeling**: Fact and dimension views in the Gold Layer, designed around a Star Schema optimized for analytical queries.

---

## 🚀 Project Requirements

### Objective

Develop a data warehouse using SQL Server to consolidate Olist's e-commerce data, enabling analytical reporting on sales, delivery performance, and payments.

### Specifications

- **Data Source**: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle), provided as CSV files.
- **Data Quality**: All source data is validated and cleansed before being modeled for analysis.
- **Integration**: All source tables are combined into a single, user-friendly star schema data model.
- **Scope**: Focused on the latest available snapshot of the dataset; historical change tracking (SCD) is not implemented.
- **Documentation**: The data model, column definitions, and naming conventions are documented under `docs/` to support both business stakeholders and technical reviewers.

---

## ⚙️ Tools & Technologies

- **SQL Server (T-SQL)** — data warehouse implementation (stored procedures, views)
- **Kaggle CSV files** — raw data source

---

## 📂 Repository Structure

```
SQL_Data_Warehouse_Project/
│
├── docs/                                # Project documentation and architecture details
│   ├── data_catalog.md                  # Catalog of all tables/columns across Bronze, Silver, and Gold layers
│   ├── naming-conventions.md            # Naming guidelines for schemas, tables, columns, and scripts
│
├── scripts/                             # SQL scripts for ETL and transformations
│   ├── bronze/                          # Scripts for creating & loading raw Bronze tables
│   ├── silver/                          # Scripts for cleaning, casting, and deduplicating into Silver
│   ├── gold/                            # DDL scripts creating the Gold Layer star schema (views)
│
├── tests/                               # Data quality validation scripts
│   └── quality_checks.sql               # Null/duplicate key checks, standardization, referential integrity, etc.
│
├── LICENSE                              # License information for the repository
└── README.md                            # Project overview and instructions
```

---

## ⭐ Gold Layer — Star Schema

| Table | Type | Grain |
|---|---|---|
| `gold.dim_customers` | Dimension | One row per customer |
| `gold.dim_sellers` | Dimension | One row per seller |
| `gold.dim_products` | Dimension | One row per product |
| `gold.dim_date` | Dimension | One row per calendar date |
| `gold.fact_sales` | Fact | One row per order item |
| `gold.fact_payments` | Fact | One row per payment installment |

Full column-level documentation is available in [`docs/data_catalog.md`](docs/data_catalog.md).

---

## 🛡️ License

This project is licensed under the MIT License.

