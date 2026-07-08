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
