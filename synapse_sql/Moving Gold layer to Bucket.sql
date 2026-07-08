USE [ecomm-depi];
GO

-- =========================================================================
-- STEP 1: SECURITY & CREDENTIALS (From Docs)
-- =========================================================================

-- 1. Create a Master Key to encrypt the credentials
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'DepiPassword123!';
GO

-- 2. Create the Credential telling Synapse to use its Managed Identity
CREATE DATABASE SCOPED CREDENTIAL [WorkspaceIdentity] 
WITH IDENTITY = 'Managed Identity';
GO

-- =========================================================================
-- STEP 2: FILE FORMAT & DATA SOURCE (From Docs)
-- =========================================================================

-- 3. Define the Parquet File Format
CREATE EXTERNAL FILE FORMAT [ParquetFF] 
WITH (
    FORMAT_TYPE = PARQUET,
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
);
GO

-- 4. Define the Data Source pointing to your Gold folder AND attach the Credential
CREATE EXTERNAL DATA SOURCE [SynapseSQLwriteable] 
WITH (
    LOCATION = 'https://depiecommds.dfs.core.windows.net/ecommdata/gold/',
    CREDENTIAL = [WorkspaceIdentity]
);
GO

-- =========================================================================
-- STEP 3: CREATE THE EXTERNAL TABLES (CETAS)
-- =========================================================================

-- 1. Export Executive Sales Overview
CREATE EXTERNAL TABLE gold.ext_sales_overview 
WITH (
    LOCATION = 'sales_overview/',
    DATA_SOURCE = [SynapseSQLwriteable],
    FILE_FORMAT = [ParquetFF]
) AS 
SELECT * FROM gold.vw_sales_overview;
GO

-- 2. Export Product Performance
CREATE EXTERNAL TABLE gold.ext_product_performance 
WITH (
    LOCATION = 'product_performance/',
    DATA_SOURCE = [SynapseSQLwriteable],
    FILE_FORMAT = [ParquetFF]
) AS 
SELECT * FROM gold.vw_product_performance;
GO

-- 3. Export Logistics Efficiency
CREATE EXTERNAL TABLE gold.ext_logistics_efficiency 
WITH (
    LOCATION = 'logistics_efficiency/',
    DATA_SOURCE = [SynapseSQLwriteable],
    FILE_FORMAT = [ParquetFF]
) AS 
SELECT * FROM gold.vw_logistics_efficiency;
GO

-- 4. Export Payment Behavior
CREATE EXTERNAL TABLE gold.ext_payment_behavior 
WITH (
    LOCATION = 'payment_behavior/',
    DATA_SOURCE = [SynapseSQLwriteable],
    FILE_FORMAT = [ParquetFF]
) AS 
SELECT * FROM gold.vw_payment_behavior;
GO