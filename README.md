# End-to-End Azure E-Commerce Data Engineering Pipeline
### DEPI Graduation Project | Medallion Architecture & Star Schema

---

## 📌 Project Overview
This project establishes a robust, enterprise-grade cloud data pipeline leveraging the **Medallion Architecture (Bronze ➡️ Silver ➡️ Gold)**. Using the Brazilian E-Commerce (Olist) dataset, the pipeline automatically ingests data from multiple sources, builds a cleaned dimensional data model (Star Schema), and persists high-performance business aggregations. The final architecture serves structured data directly into **Power BI** for strategic decision-making.
<img width="1057" height="380" alt="image" src="https://github.com/user-attachments/assets/1510c3dd-4dba-4c2f-9275-0dd2e31e7407" />

---

## 🏗️ Technical Architecture & Tech Stack
The architecture is built entirely within the Microsoft Azure ecosystem, focusing on automating ingestion, decoupling storage from compute, optimizing data scanning costs, and enforcing strict data security:

* **Data Sources:** HTTP (via GitHub) & SQL Server
* **Data Ingestion & Orchestration:** Azure Data Factory (ADF)
* **Cloud Storage / Data Lake:** Azure Data Lake Storage Gen2 (ADLS Gen2)
* **Data Transformation:** Azure Databricks (PySpark / Spark SQL)
* **Data Warehousing & Serving:** Azure Synapse Analytics (Serverless SQL Pools)
* **BI & Analytics:** Power BI Desktop

## 🔄 Pipeline Flow
```text
[Data Sources: GitHub (HTTP) & SQL Server]
                   ⬇️
         [Azure Data Factory]
                   ⬇️
   [ADLS Gen2: Raw/Bronze Layer] ➡️ [Databricks: PySpark Cleaning] ➡️ [ADLS Gen2: Silver Layer]
                                                                               ⬇️
      [Power BI Dashboards] ⬅️ [Synapse: External Tables (CETAS)] ⬅️ [ADLS Gen2: Gold Layer]
```
---

## ⚙️ Orchestration & Orchestrated Workflow (Azure Data Factory)

The entire end-to-end lifecycle is fully automated and orchestrated using **Azure Data Factory (ADF)**. The workflow is split into two distinct, decoupled pipelines to enforce modular design principles: an Ingestion Pipeline and an Orchestrator (Master) Pipeline.

### 1. Ingestion Pipeline (`PL_Ingest_ECommerce`)
This pipeline handles the heavy lifting of moving raw transactional files from external endpoints into the **Bronze Layer** of our Azure Data Lake (ADLS Gen2). 
* **HTTP Connector:** Ingests e-commerce datasets directly from public source repositories via REST endpoints.
* **SQL Server Connector:** Establishes a hybrid integration runtime to securely pull relational transactional data.
* **Parallel Execution:** Data copying tasks run in parallel to maximize throughput and drastically reduce ingestion window times.

<img width="920" height="287" alt="image" src="https://github.com/user-attachments/assets/bf1d1300-5acc-4138-9072-5548f28ae994" />

### 2. Master Orchestrator Pipeline (`PL_Master_Orchestrator`)
To guarantee strict sequence dependencies (preventing downstream tables from refreshing if upstream processing fails), a Master Orchestration pipeline acts as the "Single Pane of Glass" controller for the entire project.

* **Execute Pipeline Activity:** First, it invokes `PL_Ingest_ECommerce` to bring in the latest daily raw data.
* **Databricks Notebook Activity:** Upon successful ingestion, it sends a payload token to spin up an ephemeral cluster and run the **Silver Layer** PySpark cleaning scripts.
* **Synapse Script Activity:** Once data is cleaned and saved, it triggers **Serverless SQL** queries to execute the Gold Layer CETAS transformations.
* **Web Activity Alerting:** Hooks into an external **Azure Logic App** webhook. If the pipeline succeeds, it pushes a localized JSON metadata payload containing the pipeline metrics to automatically send a **Success Email Alert**.

<img width="1020" height="282" alt="image" src="https://github.com/user-attachments/assets/f67e56bf-176d-42a5-9407-4f591ecc47e7" />

### 📅 Pipeline Scheduling & Automation
The master orchestrator is tied to a **Schedule Trigger** configured to execute on a recurring daily cron window. Because the system utilizes Azure **System-Assigned Managed Identity (SAMI)**, the pipelines securely authenticate across Databricks and Synapse without storing static passwords or connection strings in the configuration code.

## 🗄️ Data Modeling (Silver Layer Star Schema)

To maximize analytical performance, the raw e-commerce data was refactored from flat files into a highly optimized **Star Schema**. This optimizes reporting by isolating descriptive context into Dimension tables and numeric metrics into Fact tables.

### 📐 Dimension Tables (The Context)
* **`silver.dim_customers`**: Unique buyer directory containing `customer_id`, `customer_unique_id` (for tracking repeat customers), and conformed geographic fields (`customer_city`, `customer_state`).
* **`silver.dim_products`**: Product catalog with cleansed category translations (Portuguese to English) and safely casted numerical product specifications. Missing fields default safely to `"Unknown"`.
* **`silver.dim_sellers`**: Merchant registry mapping `seller_id` to operational storefront origins (`seller_city`, `seller_state`).
* **`silver.dim_locations`**: Geo-spatial reference table mapping truncated postal `zip_code` prefixes to literal geographic coordinates (`lat`, `lng`).

### 📊 Fact Tables (The Metrics)
* **`silver.fact_sales`**: The core transactional table containing monetary granular data (`price`, `freight_value`) and temporal metrics. **Degenerate Dimension:** `order_id` is kept directly inside the fact table to optimize dashboard joins and execution time. **Engineered Features:** Includes `delivery_variance_days` (`actual_delivery - estimated_delivery`) to calculate logistic SLA accuracy, alongside a boolean `is_delayed` flag.
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
Instead of executing resource-intensive real-time joins during BI refreshes, the business logic is persisted physically using Azure Synapse Serverless SQL. Using **CETAS** (`CREATE EXTERNAL TABLE AS SELECT`) backed by a secure Database Scoped Credential (Managed Identity), Synapse materializes pre-aggregated data models into the `gold/` directory as physical Snappy-compressed Parquet files:
* **`gold.ext_sales_overview`**: Executive revenue performance and geographic trends.
* **`gold.ext_product_performance`**: Sales volume and velocity metrics aggregated across categories.
* **`gold.ext_logistics_efficiency`**: High-impact delivery fulfillment timelines and SLA breach analysis.
* **`gold.ext_payment_behavior`**: Installment trends and payment preferences over time.

> **Note:** This physical materialization approach heavily optimizes reporting performance and cuts Synapse Serverless data-scanning costs significantly.

---

## 🔐 Security Standards & Best Practices
* **Secret Management:** Production credentials and Azure Active Directory service principal secrets are strictly parameterized or isolated out of codebase commits using environmental variables/placeholders.
* **Access Control:** Data interactions use Azure RBAC (`Storage Blob Data Contributor`) and Database Scoped Credentials mapping Synapse's native Managed Identity securely to Azure Lakehouse storage endpoints.

---

## 📈 Power BI Integration
The final reporting layer hooks directly into the Synapse Serverless SQL Endpoint, pulling data from the **Gold External Tables (`gold.ext_...`)** via **Import Mode**. Because the heavy compute (joins, mathematical derivations, windowing) was handled upstream in the Gold layer, the resulting dashboards feature sub-second loading states and highly responsive interactions for cross-filtering.
