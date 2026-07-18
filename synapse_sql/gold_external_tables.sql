USE [ecomm-depi];
GO

CREATE EXTERNAL TABLE gold.ext_customer_segmentation
WITH (
    LOCATION = 'customer_segmentation/',
    DATA_SOURCE = [SynapseSQLwriteable],
    FILE_FORMAT = [ParquetFF]
) AS
SELECT * FROM gold.vw_customer_segmentation;
GO

CREATE EXTERNAL TABLE gold.ext_seller_performance
WITH (
    LOCATION = 'seller_performance/',
    DATA_SOURCE = [SynapseSQLwriteable],
    FILE_FORMAT = [ParquetFF]
) AS
SELECT * FROM gold.vw_seller_performance;
GO

CREATE EXTERNAL TABLE gold.ext_regional_sales
WITH (
    LOCATION = 'regional_sales/',
    DATA_SOURCE = [SynapseSQLwriteable],
    FILE_FORMAT = [ParquetFF]
) AS
SELECT * FROM gold.vw_regional_sales;
GO