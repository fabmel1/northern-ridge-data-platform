# Northern Ridge – Sales Operations Analytics (Medallion Architecture & dbt)

An end-to-end cloud data warehouse and business intelligence pipeline built with **Snowflake**, **dbt (data build tool)**, and **Power BI**. 

This project transforms raw transactional e-commerce sales records into a production-ready, star-schema Gold analytics layer tailored for executive sales operations tracking.

---

## 🛠️ Tech Stack & Architecture Overview

* **Data Warehouse:** Snowflake (Medallion Architecture: Bronze --> Silver --> Gold)
* **Transformation & Modeling:** dbt (Data Build Tool)
* **BI & Data Visualization:** Power BI Desktop
* **Source Data Types:** Transactional CSV export (`sales_orders.csv`), JSON metadata (`products.json`)

```
   +-----------------------+              +-----------------------+
   |   INPUT (SILVER)      |              |  PROCESS (dbt / DW)   |              |     OUTPUT (GOLD)     |              |   VISUALIZATION       |
   |                       |              |                       |              |                       |              |                       |
   |  silver.fct_sales_    | -----------> | - Deduplicate Stores  | -----------> |  gold.fct_sales       | -----------> |  Power BI Dashboard   |
   |        orders         |    (dbt)     |   (`ROW_NUMBER()`)    |              |                       |              |                       |
   |                       |              | - Extract Dimensions  |              |  gold.dim_stores      |              |  - Monthly Trends     |
   |  silver.dim_products  | -----------> | - Derive FK / Keys    | -----------> |  gold.dim_products    |              |  - Category Revenue   |
   +-----------------------+              +-----------------------+              +-----------------------+              |  - City Breakdown     |
                                                                                                                        +-----------------------+
```

---

## 🏗️ Medallion Pipeline Design

### 1. Bronze Layer (Raw Ingestion)
* Ingestion of unstructured/semi-structured files (`products.json`) and raw tabular transaction logs (`sales_orders.csv`).
* Preserves raw file structures with minimal transformation.

### 2. Silver Layer (Cleansing & Conformance)
* Casts data types (timestamps, monetary decimals).
* Standardizes field names (`TOTAL_AMOUNT_CAD`, `ORDER_STATUS`, `STORE_ID`).
* Contains primary tables: `silver.fct_sales_orders` and `silver.dim_products`.

### 3. Gold Layer (Business Star Schema)
* **`gold.fct_sales`**: Central fact table storing sales transactions, line quantities, monetary totals, and foreign key references.
* **`gold.dim_stores`**: Derived directly from transaction logs via `dbt` using window functions to deduplicate store entities down to unique grain ($1:N$).
* **`gold.dim_products`**: Cleaned dimension table sourced from product catalog data.
* **Degenerate Dimensions**: Customer shipping location (`CITY`) retained on the fact grain for regional sales analysis without bloating dimension models.

---

## 💡 Key Engineering Challenges & Solutions

### 1. Fixing M:N Relationship Bloat in Dimension Modeling
* **Issue:** Extracting `dim_stores` directly from transactional order lines with `GROUP BY store_id, city` resulted in 35 rows for 7 physical stores (7 * 5 = 35), causing many-to-many relationship explosions in Power BI and static $984.49K revenue across all cities.
* **Root Cause Analysis:** Transaction logs recorded shipping/destination cities per order, not fixed physical store locations.
* **Fix:** Enforced strict $1:1$ store uniqueness in dbt using `ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY ingested_at DESC)` and re-classified delivery `CITY` as a degenerate dimension on `fct_sales`.

### 2. Chronological Sorting in Power BI Visuals
* **Issue:** Power BI sorted month-level trends alphabetically (Apr, Aug, Feb, Jan, Jun, Mar, May).
* **Fix:** Configured explicit `Sort by Column` settings in the Date Dimension using integer key attributes (`MONTH_NUM`), re-aligning visual axes from January through August.

---

## 📊 Executive Dashboard Features (Power BI)

* **Key Performance Indicators (KPIs):** Total Revenue ($984.49K), Total Orders (1.205K), Average Order Value ($817.01), Total Units Sold (2.348K).
* **Revenue Trend Over Time:** Line chart displaying monthly revenue trajectory across 2026.
* **Revenue by Product Category:** Horizontal bar breakdown comparing performance across Home & Furniture, Outdoor Gear, Apparel, Footwear, Cookware, and Electronics.
* **Regional Breakdown:** Column chart visualizing revenue distribution across Alberta cities (Calgary, Lethbridge, Medicine Hat, Red Deer).

---

## 🚀 How to Run

1. **dbt Transformations:**
   ```bash
   dbt deps
   dbt run --select gold
   dbt test
   ```
2. **Power BI Refresh:**
   * Open `Northern_Ridge_Sales_Ops.pbix`.
   * Click **Refresh** to sync directly with Gold layer views in Snowflake.
