USE [ecomm-depi];
GO

-- KPI 5: Customer Segmentation
CREATE OR ALTER VIEW gold.vw_customer_segmentation AS
SELECT
    f.customer_id,
    c.customer_state,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.price), 2) AS total_spent,
    ROUND(SUM(f.price) / COUNT(DISTINCT f.order_id), 2) AS avg_order_value,
    CASE 
        WHEN SUM(f.price) >= 1000 THEN 'VIP Customer'
        WHEN SUM(f.price) >= 500 THEN 'Regular Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM silver.fact_sales f
INNER JOIN silver.dim_customers c 
    ON f.customer_id = c.customer_id
GROUP BY 
    f.customer_id,
    c.customer_state;
GO


-- KPI 6: Seller Performance
CREATE OR ALTER VIEW gold.vw_seller_performance AS
SELECT
    f.seller_id,
    s.seller_state,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.price), 2) AS total_revenue,
    ROUND(AVG(f.freight_value), 2) AS avg_freight_cost,
    ROUND(AVG(DATEDIFF(day, f.order_date, f.actual_delivery)), 1) AS avg_delivery_days,
    ROUND(SUM(CASE WHEN f.is_delayed = 1 THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(f.order_id), 2) AS late_delivery_rate,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM silver.fact_sales f
INNER JOIN silver.dim_sellers s 
    ON f.seller_id = s.seller_id
LEFT JOIN silver.fact_reviews r 
    ON f.order_id = r.order_id
GROUP BY 
    f.seller_id,
    s.seller_state;
GO


-- KPI 7: Regional Sales Analysis
CREATE OR ALTER VIEW gold.vw_regional_sales AS
SELECT
    c.customer_state,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(DISTINCT f.customer_id) AS unique_customers,
    ROUND(SUM(f.price), 2) AS total_revenue,
    ROUND(AVG(f.price), 2) AS avg_item_price,
    ROUND(SUM(f.freight_value), 2) AS total_freight_cost
FROM silver.fact_sales f
INNER JOIN silver.dim_customers c 
    ON f.customer_id = c.customer_id
GROUP BY 
    c.customer_state;
GO


-- KPI 8: Review & Satisfaction Analysis
CREATE OR ALTER VIEW gold.vw_review_satisfaction AS
SELECT
    r.review_score,
    COUNT(DISTINCT r.order_id) AS total_reviews,
    ROUND(AVG(f.price), 2) AS avg_order_price,
    ROUND(AVG(f.delivery_variance_days), 1) AS avg_delivery_variance_days,
    ROUND(
        SUM(CASE WHEN f.is_delayed = 1 THEN 1.0 ELSE 0.0 END) 
        * 100.0 / NULLIF(COUNT(f.order_id), 0), 
    2) AS late_delivery_rate
FROM silver.fact_reviews r
LEFT JOIN silver.fact_sales f
    ON r.order_id = f.order_id
GROUP BY 
    r.review_score;
GO
SELECT TOP 10 * FROM gold.vw_review_satisfaction;
GO