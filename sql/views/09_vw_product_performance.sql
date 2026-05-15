S-- ============================================
-- 09_vw_product_performance.sql
-- Product rankings by revenue and quantity
-- Includes Pareto (80/20) cumulative analysis
-- ============================================

USE OnlineRetailDB;
GO

IF OBJECT_ID('dbo.vw_product_performance', 'V') IS NOT NULL
    DROP VIEW dbo.vw_product_performance;
GO

CREATE VIEW dbo.vw_product_performance AS
WITH ProductMetrics AS (
    SELECT
        p.product_key,
        p.stock_code,
        p.description,
        SUM(f.line_total) AS total_revenue,
        SUM(f.quantity) AS total_quantity,
        COUNT(DISTINCT f.invoice_no) AS order_count,
        COUNT(DISTINCT f.customer_key) AS customer_count,
        AVG(f.unit_price) AS avg_price
    FROM dbo.FactSales f
    INNER JOIN dbo.DimProduct p ON f.product_key = p.product_key
    GROUP BY p.product_key, p.stock_code, p.description
),
RankedProducts AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue,
        SUM(total_revenue) OVER () AS grand_total_revenue
    FROM ProductMetrics
)
SELECT
    *,
    CAST(cumulative_revenue / grand_total_revenue * 100 AS DECIMAL(5,2)) AS cumulative_revenue_pct,
    CAST(total_revenue / grand_total_revenue * 100 AS DECIMAL(5,2)) AS revenue_share_pct
FROM RankedProducts;
GO

PRINT 'vw_product_performance created.';
