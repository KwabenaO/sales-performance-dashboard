-- ============================================
-- summary_statistics.sql
-- Run this after all tables and views are built
-- Copy the results into your docs/architecture.md
-- ============================================

USE OnlineRetailDB;
GO

-- ============================================
-- 1. DATA CLEANING SUMMARY
-- Answers: How many rows were in the raw data?
-- How many survived cleaning? What was removed?
-- ============================================

PRINT '=== DATA CLEANING SUMMARY ===';

SELECT 'Raw staging rows' AS metric,
    COUNT(*) AS value
FROM dbo.stg_online_retail

UNION ALL

SELECT 'Clean rows kept',
    COUNT(*)
FROM dbo.clean_transactions

UNION ALL

SELECT 'Rows removed',
    (SELECT COUNT(*) FROM dbo.stg_online_retail) - (SELECT COUNT(*) FROM dbo.clean_transactions);
GO

-- Why rows were removed (breakdown)
SELECT
    'Missing Customer ID' AS removal_reason,
    SUM(CASE WHEN [Customer ID] IS NULL OR [Customer ID] = '' THEN 1 ELSE 0 END) AS row_count
FROM dbo.stg_online_retail

UNION ALL

SELECT 'Zero or negative price',
    SUM(CASE WHEN TRY_CAST(Price AS DECIMAL(10,2)) <= 0 THEN 1 ELSE 0 END)
FROM dbo.stg_online_retail

UNION ALL

SELECT 'Unparseable quantity',
    SUM(CASE WHEN TRY_CAST(Quantity AS INT) IS NULL THEN 1 ELSE 0 END)
FROM dbo.stg_online_retail

UNION ALL

SELECT 'Unparseable date',
    SUM(CASE WHEN TRY_CAST(InvoiceDate AS DATETIME) IS NULL THEN 1 ELSE 0 END)
FROM dbo.stg_online_retail;
GO

-- ============================================
-- 2. OVERALL DATASET STATS
-- Answers: What does the data look like after cleaning?
-- ============================================

PRINT '=== OVERALL STATS (clean, excluding cancellations) ===';

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT stock_code) AS unique_products,
    COUNT(DISTINCT country) AS unique_countries,
    MIN(invoice_date) AS earliest_date,
    MAX(invoice_date) AS latest_date,
    SUM(line_total) AS total_revenue,
    AVG(line_total) AS avg_line_total,
    SUM(CASE WHEN is_cancellation = 1 THEN 1 ELSE 0 END) AS cancellation_rows,
    SUM(CASE WHEN is_cancellation = 0 THEN 1 ELSE 0 END) AS valid_sale_rows
FROM dbo.clean_transactions;
GO

-- ============================================
-- 3. CANCELLATION ANALYSIS
-- Answers: How many cancellations? What's their value?
-- ============================================

PRINT '=== CANCELLATION SUMMARY ===';

SELECT
    is_cancellation,
    COUNT(*) AS row_count,
    COUNT(DISTINCT invoice_no) AS order_count,
    SUM(line_total) AS total_value,
    AVG(line_total) AS avg_value
FROM dbo.clean_transactions
GROUP BY is_cancellation;
GO

-- ============================================
-- 4. DIMENSION TABLE SIZES
-- Answers: How many rows in each dimension?
-- ============================================

PRINT '=== DIMENSION TABLE SIZES ===';

SELECT 'DimDate' AS table_name, COUNT(*) AS rows FROM dbo.DimDate
UNION ALL
SELECT 'DimCustomer', COUNT(*) FROM dbo.DimCustomer
UNION ALL
SELECT 'DimProduct', COUNT(*) FROM dbo.DimProduct
UNION ALL
SELECT 'DimGeography', COUNT(*) FROM dbo.DimGeography
UNION ALL
SELECT 'FactSales', COUNT(*) FROM dbo.FactSales;
GO

-- ============================================
-- 5. REVENUE BREAKDOWN
-- Answers: Where does the revenue come from?
-- ============================================

PRINT '=== REVENUE BY YEAR ===';

SELECT
    d.year,
    COUNT(DISTINCT f.invoice_no) AS orders,
    COUNT(DISTINCT f.customer_key) AS customers,
    SUM(f.line_total) AS revenue
FROM dbo.FactSales f
INNER JOIN dbo.DimDate d ON f.date_key = d.date_key
GROUP BY d.year
ORDER BY d.year;
GO

PRINT '=== TOP 10 COUNTRIES BY REVENUE ===';

SELECT TOP 10
    country,
    revenue_share_pct,
    total_revenue,
    total_orders,
    unique_customers
FROM dbo.vw_geographic_sales
ORDER BY total_revenue DESC;
GO

-- ============================================
-- 6. PRODUCT PARETO
-- Answers: How many products drive 80% of revenue?
-- ============================================

PRINT '=== PARETO ANALYSIS ===';

-- Total products
SELECT COUNT(*) AS total_products FROM dbo.vw_product_performance;

-- Products needed for 80% of revenue
SELECT
    COUNT(*) AS products_for_80pct,
    (SELECT COUNT(*) FROM dbo.vw_product_performance) AS total_products,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dbo.vw_product_performance) AS DECIMAL(5,1)) AS pct_of_products
FROM dbo.vw_product_performance
WHERE cumulative_revenue_pct <= 80;
GO

-- Top 5 products
SELECT TOP 5
    revenue_rank,
    stock_code,
    description,
    total_revenue,
    revenue_share_pct,
    cumulative_revenue_pct
FROM dbo.vw_product_performance
ORDER BY revenue_rank;
GO

-- ============================================
-- 7. RFM SEGMENT DISTRIBUTION
-- Answers: How are customers distributed across segments?
-- ============================================

PRINT '=== RFM SEGMENTS ===';

SELECT
    rfm_segment,
    COUNT(*) AS customer_count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,1)) AS pct_of_customers,
    AVG(recency_days) AS avg_recency_days,
    AVG(frequency) AS avg_frequency,
    CAST(AVG(monetary) AS DECIMAL(12,2)) AS avg_monetary
FROM dbo.vw_rfm_scores
GROUP BY rfm_segment
ORDER BY avg_monetary DESC;
GO

-- ============================================
-- 8. COHORT RETENTION SNAPSHOT
-- Answers: What does retention look like?
-- ============================================

PRINT '=== COHORT SIZES (top 10 cohorts) ===';

SELECT TOP 10
    cohort_month,
    MAX(CASE WHEN months_since_signup = 0 THEN active_customers END) AS starting_size,
    MAX(CASE WHEN months_since_signup = 1 THEN retention_rate END) AS month_1_retention,
    MAX(CASE WHEN months_since_signup = 3 THEN retention_rate END) AS month_3_retention,
    MAX(CASE WHEN months_since_signup = 6 THEN retention_rate END) AS month_6_retention
FROM dbo.vw_cohort_retention
GROUP BY cohort_month
ORDER BY cohort_month;
GO

-- ============================================
-- 9. MONTHLY REVENUE TREND
-- Answers: What does the growth trend look like?
-- ============================================

PRINT '=== MONTHLY REVENUE TREND ===';

SELECT
    year_month,
    revenue,
    total_orders,
    unique_customers,
    mom_growth_pct
FROM dbo.vw_revenue_monthly
ORDER BY year, month_num;
GO

PRINT 'Done. Use these numbers to fill in docs/architecture.md.';
