S-- ============================================
-- 08_vw_revenue_summary.sql
-- Revenue aggregated by various time periods
-- Includes period-over-period growth rates
-- ============================================

USE OnlineRetailDB;
GO

IF OBJECT_ID('dbo.vw_revenue_monthly', 'V') IS NOT NULL
    DROP VIEW dbo.vw_revenue_monthly;
GO

CREATE VIEW dbo.vw_revenue_monthly AS
WITH MonthlyRevenue AS (
    SELECT
        d.year,
        d.month_num,
        d.year_month,
        COUNT(DISTINCT f.invoice_no) AS total_orders,
        COUNT(DISTINCT f.customer_key) AS unique_customers,
        SUM(f.line_total) AS revenue,
        SUM(f.quantity) AS units_sold
    FROM dbo.FactSales f
    INNER JOIN dbo.DimDate d ON f.date_key = d.date_key
    GROUP BY d.year, d.month_num, d.year_month
)
SELECT
    m.*,
    LAG(m.revenue) OVER (ORDER BY m.year, m.month_num) AS prev_month_revenue,
    CASE
        WHEN LAG(m.revenue) OVER (ORDER BY m.year, m.month_num) > 0
        THEN (m.revenue - LAG(m.revenue) OVER (ORDER BY m.year, m.month_num))
             / LAG(m.revenue) OVER (ORDER BY m.year, m.month_num) * 100
        ELSE NULL
    END AS mom_growth_pct
FROM MonthlyRevenue m;
GO

PRINT 'vw_revenue_monthly created.';
