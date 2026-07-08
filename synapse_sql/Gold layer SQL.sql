-- KPI 1: Executive Sales & Revenue Performance (Main Dashboard Tab)
CREATE OR ALTER VIEW gold.vw_sales_overview AS
SELECT 
    CAST(f.order_date AS DATE) AS order_date,
    YEAR(f.order_date) AS order_year,
    MONTH(f.order_date) AS order_month,
    CONCAT(YEAR(f.order_date), '-', RIGHT('0' + CAST(MONTH(f.order_date) AS VARCHAR(2)), 2)) AS year_month,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(DISTINCT f.customer_id) AS unique_customers,
    ROUND(SUM(f.price), 2) AS total_revenue,
    ROUND(SUM(f.freight_value), 2) AS total_freight_cost,
    ROUND(SUM(f.price) / COUNT(DISTINCT f.order_id), 2) AS avg_order_value
FROM silver.fact_sales f
GROUP BY 
    CAST(f.order_date AS DATE), 
    YEAR(f.order_date), 
    MONTH(f.order_date);
GO

-- KPI 2: Product Performance & Customer Sentiment (Inventory/Product Tab)
CREATE OR ALTER VIEW gold.vw_product_performance AS
SELECT 
    p.category_name,
    COUNT(f.product_id) AS units_sold,
    ROUND(SUM(f.price), 2) AS total_sales,
    ROUND(AVG(f.price), 2) AS avg_unit_price,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM silver.fact_sales f
INNER JOIN silver.dim_products p ON f.product_id = p.product_id
LEFT JOIN silver.fact_reviews r ON f.order_id = r.order_id
WHERE p.category_name IS NOT NULL
GROUP BY p.category_name;
GO

-- KPI 3: Supply Chain & Logistics Efficiency (Operations/Map Tab)
CREATE OR ALTER VIEW gold.vw_logistics_efficiency AS
SELECT 
    c.customer_state AS destination_state,
    s.seller_state AS origin_state,
    COUNT(DISTINCT f.order_id) AS total_shipments,
    ROUND(AVG(f.freight_value), 2) AS avg_freight_cost,
    ROUND(AVG(DATEDIFF(day, f.order_date, f.actual_delivery)), 1) AS avg_actual_delivery_days,
    ROUND(AVG(f.delivery_variance_days), 1) AS avg_days_hidden_or_late,
    ROUND(SUM(CASE WHEN f.is_delayed = 1 THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(f.order_id), 2) AS late_delivery_rate
FROM silver.fact_sales f
INNER JOIN silver.dim_customers c ON f.customer_id = c.customer_id
INNER JOIN silver.dim_sellers s ON f.seller_id = s.seller_id
WHERE f.actual_delivery IS NOT NULL
GROUP BY c.customer_state, s.seller_state;
GO
-- KPI 4: Customer Financial Behavior (Finance Tab)
CREATE OR ALTER VIEW gold.vw_payment_behavior AS
SELECT 
    p.payment_type,
    COUNT(DISTINCT p.order_id) AS transaction_count,
    ROUND(SUM(p.payment_value), 2) AS total_payment_volume,
    ROUND(AVG(p.payment_installments), 1) AS avg_selected_installments
FROM silver.fact_payments p
GROUP BY p.payment_type;
GO

SELECT TOP 10 * FROM gold.vw_payment_behavior