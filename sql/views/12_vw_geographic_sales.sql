S-- ============================================
-- 12_vw_geographic_sales.sql
-- Revenue, orders, and customers by country and region
-- ============================================

USE OnlineRetailDB;
GO

IF OBJECT_ID('dbo.vw_geographic_sales', 'V') IS NOT NULL
    DROP VIEW dbo.vw_geographic_sales;
GO

CREATE VIEW dbo.vw_geographic_sales AS
SELECT
    g.geography_key,
    g.country,
    g.region,
    COUNT(DISTINCT f.invoice_no) AS total_orders,
    COUNT(DISTINCT f.customer_key) AS unique_customers,
    SUM(f.line_total) AS total_revenue,
    SUM(f.quantity) AS total_units,
    AVG(f.line_total) AS avg_line_value,
    CAST(SUM(f.line_total) / NULLIF(SUM(SUM(f.line_total)) OVER (), 0) * 100 AS DECIMAL(5,2)) AS revenue_share_pct
FROM dbo.FactSales f
INNER JOIN dbo.DimGeography g ON f.geography_key = g.geography_key
GROUP BY g.geography_key, g.country, g.region;
GO

PRINT 'vw_geographic_sales created.';
