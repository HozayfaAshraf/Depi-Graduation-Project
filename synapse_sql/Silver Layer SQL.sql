CREATE SCHEMA silver

CREATE SCHEMA gold

CREATE OR ALTER VIEW silver.dim_customers AS
SELECT * FROM OPENROWSET(
    BULK 'https://depiecommds.dfs.core.windows.net/ecommdata/silver/dim_customers/*.parquet',
    FORMAT = 'PARQUET'
) AS dim_customers;
GO

CREATE OR ALTER VIEW silver.dim_products AS
SELECT * FROM OPENROWSET(
    BULK 'https://depiecommds.dfs.core.windows.net/ecommdata/silver/dim_products/*.parquet',
    FORMAT = 'PARQUET'
) AS dim_products;
GO

CREATE OR ALTER VIEW silver.dim_sellers AS
SELECT * FROM OPENROWSET(
    BULK 'https://depiecommds.dfs.core.windows.net/ecommdata/silver/dim_sellers/*.parquet',
    FORMAT = 'PARQUET'
) AS dim_sellers;
GO

CREATE OR ALTER VIEW silver.dim_locations AS
SELECT * FROM OPENROWSET(
    BULK 'https://depiecommds.dfs.core.windows.net/ecommdata/silver/dim_locations/*.parquet',
    FORMAT = 'PARQUET'
) AS dim_locations;
GO

CREATE OR ALTER VIEW silver.fact_sales AS
SELECT * FROM OPENROWSET(
    BULK 'https://depiecommds.dfs.core.windows.net/ecommdata/silver/fact_sales/*.parquet',
    FORMAT = 'PARQUET'
) AS fact_sales;
GO

CREATE OR ALTER VIEW silver.fact_payments AS
SELECT * FROM OPENROWSET(
    BULK 'https://depiecommds.dfs.core.windows.net/ecommdata/silver/fact_payments/*.parquet',
    FORMAT = 'PARQUET'
) AS fact_payments;
GO

CREATE OR ALTER VIEW silver.fact_reviews AS
SELECT * FROM OPENROWSET(
    BULK 'https://depiecommds.dfs.core.windows.net/ecommdata/silver/fact_reviews/*.parquet',
    FORMAT = 'PARQUET'
) AS fact_reviews;
GO