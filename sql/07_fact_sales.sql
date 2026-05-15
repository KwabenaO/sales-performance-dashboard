-- ============================================
-- 07_fact_sales.sql
-- Create the fact table by joining clean transactions to dimension keys
-- Excludes cancellations from the main fact table
-- Cancellations stored separately for cancellation analysis
-- ============================================

USE OnlineRetailDB;
GO

IF OBJECT_ID('dbo.FactSales', 'U') IS NOT NULL
    DROP TABLE dbo.FactSales;
GO

SELECT
    ROW_NUMBER() OVER (ORDER BY ct.invoice_date, ct.invoice_no) AS sales_key,
    CAST(FORMAT(ct.invoice_date, 'yyyyMMdd') AS INT) AS date_key,
    dc.customer_key,
    dp.product_key,
    dg.geography_key,
    ct.invoice_no,
    ct.quantity,
    ct.unit_price,
    ct.line_total,
    ct.is_cancellation
INTO dbo.FactSales
FROM dbo.clean_transactions ct
LEFT JOIN dbo.DimCustomer dc ON ct.customer_id = dc.customer_id
LEFT JOIN dbo.DimProduct dp ON ct.stock_code = dp.stock_code
LEFT JOIN dbo.DimGeography dg ON ct.country = dg.country
WHERE ct.is_cancellation = 0;  -- Exclude cancellations from main fact table
GO

-- Add primary key
ALTER TABLE dbo.FactSales
ALTER COLUMN sales_key BISGINT NOT NULL;
GO

ALTER TABLE dbo.FactSales
ADD CONSTRAINT PK_FactSales PRIMARY KEY (sales_key);
GO

-- Add foreign key indexes for Power BI performance
CREATE NONCLUSTERED INDEX IX_FactSales_DateKey ON dbo.FactSales (date_key);
CREATE NONCLUSTERED INDEX IX_FactSales_CustomerKey ON dbo.FactSales (customer_key);
CREATE NONCLUSTERED INDEX IX_FactSales_ProductKey ON dbo.FactSales (product_key);
CREATE NONCLUSTERED INDEX IX_FactSales_GeographyKey ON dbo.FactSales (geography_key);
GO

-- Summary
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(line_total) AS total_revenue,
    MIN(date_key) AS min_date,
    MAX(date_key) AS max_date
FROM dbo.FactSales;
GO

PRINT 'FactSales created with indexes.';
