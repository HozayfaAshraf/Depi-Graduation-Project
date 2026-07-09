# End-to-End Azure E-Commerce Data Engineering Pipeline
### DEPI Graduation Project | Medallion Architecture & Star Schema

---

## 📌 Project Overview
This project establishes a robust, enterprise-grade cloud data pipeline leveraging the **Medallion Architecture (Bronze ➡️ Silver ➡️ Gold)**. Using the Brazilian E-Commerce (Olist) dataset, the pipeline automatically ingests data from multiple sources, builds a cleaned dimensional data model (Star Schema), and persists high-performance business aggregations. The final architecture serves structured data directly into **Power BI** for strategic decision-making.

---

## 🏗️ Technical Architecture & Tech Stack

The architecture is built entirely within the Microsoft Azure ecosystem, focusing on automating ingestion, decoupling storage from compute, optimizing data scanning costs, and enforcing strict data security:

* **Data Sources:** HTTP (via GitHub) & SQL Server
* **Data Ingestion & Orchestration:** Azure Data Factory (ADF)
* **Cloud Storage / Data Lake:** Azure Data Lake Storage Gen2 (ADLS Gen2)
* **Data Transformation:** Azure Databricks (PySpark / Spark SQL)
* **Data Warehousing & Serving:** Azure Synapse Analytics (Serverless SQL Pools)
* **BI & Analytics:** Power BI Desktop

### 🔄 Pipeline Flow
```text
[Data Sources: GitHub (HTTP) & SQL Server]
                   ⬇️
         [Azure Data Factory]
                   ⬇️
   [ADLS Gen2: Raw/Bronze Layer] ➡️ [Databricks: PySpark Cleaning] ➡️ [ADLS Gen2: Silver Layer]
                                                                               ⬇️
      [Power BI Dashboards] ⬅️ [Synapse: External Tables (CETAS)] ⬅️ [ADLS Gen2: Gold Layer]


Here is a comprehensive, production-grade `README.md` for your graduation project portfolio. It is structurally designed to showcase your technical decisions, data modeling skills, and architectural knowledge directly to recruiters and hiring managers.

You can copy and paste this entire block directly into your `README.md` file on GitHub.

---

```markdown
# End-to-End Azure E-Commerce Data Engineering Pipeline
### DEPI Graduation Project | Medallion Architecture & Star Schema

---

## 📌 Project Overview
This project establishes a robust, enterprise-grade cloud data pipeline leveraging the **Medallion Architecture (Bronze ➡️ Silver ➡️ Gold)**. Using the Brazilian E-Commerce (Olist) public dataset, the pipeline ingests raw transactional logs, builds a cleaned dimensional data model (Star Schema), and persists high-performance business aggregations. The final architecture serves structured data directly into **Power BI** for strategic decision-making.

---

## 🏗️ Technical Architecture & Tech Stack

The architecture is built entirely within the Microsoft Azure ecosystem, focusing on decoupling storage from compute, optimizing data scanning costs, and enforcing strict data security:

* **Cloud Storage:** Azure Data Lake Storage Gen2 (ADLS Gen2)
* **Data Processing & Orchestration:** Azure Databricks (PySpark / Spark SQL)
* **Data Warehousing & Serving:** Azure Synapse Analytics (Serverless SQL Pools)
* **BI & Analytics:** Power BI Desktop (Import Mode)


```

[Raw Data] ➡️ [ADLS Gen2: Bronze] ➡️ [Databricks: PySpark Cleaning] ➡️ [ADLS Gen2: Silver]
⬇️
[Power BI Dashboards] ⬅️ [Synapse: External Tables (CETAS)] ⬅️ [ADLS Gen2: Gold (Parquet)]

```

---

## 🗄️ Data Modeling (Silver Layer Star Schema)

To maximize analytical performance, the raw e-commerce data was refactored from flat files into a highly optimized **Star Schema**. This optimizes reporting by isolating descriptive context into Dimension tables and numeric metrics into Fact tables.

### 📐 Dimension Tables (The Context)
* **`silver.dim_customers`**: Unique buyer directory containing `customer_id`, `customer_unique_id` (for tracking repeat customers), and conformed geographic fields (`customer_city`, `customer_state`).
* **`silver.dim_products`**: Product catalog with cleansed category translations (Portuguese to English) and safely casted numerical product specifications. Missing fields default safely to `"Unknown"`.
* **`silver.dim_sellers`**: Merchant registry mapping `seller_id` to operational storefront origins (`seller_city`, `seller_state`).
* **`silver.dim_locations`**: Geo-spatial reference table mapping truncated postal `zip_code` prefixes to literal geographic coordinates (`lat`, `lng`).

### 📊 Fact Tables (The Metrics)
* **`silver.fact_sales`**: The core transactional table containing monetary granular data (`price`, `freight_value`) and temporal metrics.
    * *Degenerate Dimension:* `order_id` is kept directly inside the fact table to optimize dashboard joins and execution time.
    * *Engineered Features:* Includes `delivery_variance_days` (`actual_delivery - estimated_delivery`) to calculate logistic SLA accuracy, alongside a boolean `is_delayed` flag.
* **`silver.fact_payments`**: Captures financial settlement breakdown. Tracks multi-payment methods (`payment_type`), installment counts, and segmented values per order.
* **`silver.fact_reviews`**: Contains customer satisfaction metrics (`review_score`) tied to unique transaction windows.

---

## ⚡ Data Pipeline Phases

### 1. Bronze Layer (Ingestion)
Raw structured datasets (CSVs/JSONs) are landed natively into the `bronze/` container inside ADLS Gen2. Files are kept in their original state to maintain a historical record of untransformed data.

### 2. Silver Layer (Transformation & Enrichment)
Using **Azure Databricks (PySpark)**, the notebook processes raw bronze data through rigorous data-quality transformations:
* Enforces schema validation and handles corrupted records cleanly using safe `try_cast` evaluations.
* Deduplicates customer records to guarantee primary key integrity.
* Performs string normalization and column-level dictionary translations.
* Writes optimized, compressed **Parquet format** partitions into the `silver/` ADLS directory.

### 3. Gold Layer (Aggregation & Persistence)
Instead of executing resource-intensive real-time joins during BI refreshes, the business logic is persisted physically using Azure Synapse Serverless SQL. 
Using **CETAS** (`CREATE EXTERNAL TABLE AS SELECT`) backed by a secure Database Scoped Credential (Managed Identity), Synapse materializes pre-aggregated data models into the `gold/` directory as physical Snappy-compressed Parquet files:
* `gold.ext_sales_overview`: Executive revenue performance and geographic trends.
* `gold.ext_product_performance`: Sales volume and velocity metrics aggregated across categories.
* `gold.ext_logistics_efficiency`: High-impact delivery fulfillment timelines and SLA breach analysis.
* `gold.ext_payment_behavior`: Installment trends and payment preferences over time.

This approach optimizes reporting performance and cuts Synapse Serverless data-scanning costs significantly.

---

## 🔐 Security Standards & Best Practices
* **Secret Management:** Production credentials and Azure Active Directory service principal secrets are strictly parameterized or isolated out of codebase commits using environmental variables/placeholders.
* **Access Control:** Data interactions use Azure RBAC (`Storage Blob Data Contributor`) and Database Scoped Credentials mapping Synapse's native Managed Identity securely to Azure Lakehouse storage endpoints.

---

## 📈 Power BI Integration
The final reporting layer hooks directly into the Synapse Serverless SQL Endpoint, pulling data from the **Gold External Tables (`gold.ext_...`)** via **Import Mode**. Because the heavy compute (joins, mathematical derivations, windowing) was handled upstream in the Gold layer, the resulting dashboards feature sub-second loading states and highly responsive interactions for cross-filtering.

```
