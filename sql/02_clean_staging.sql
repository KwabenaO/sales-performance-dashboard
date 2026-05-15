S-- ============================================
-- 02_clean_staging.sql
-- Clean the staging data and create a typed clean table
-- Handles: cancellations, missing customer IDs, bad prices,
-- duplicate descriptions, and data type casting
-- ============================================

USE OnlineRetailDB;
GO

-- Drop clean table if it exists
IF OBJECT_ID('dbo.clean_transactions', 'U') IS NOT NULL
    DROP TABLE dbo.clean_transactions;
GO

-- Create clean table with proper data types
-- Exclude rows that cannot be used for analysis
SELECT
    CAST(Invoice AS VARCHAR(10)) AS invoice_no,
    CAST(StockCode AS VARCHAR(20)) AS stock_code,
    CAST(Description AS VARCHAR(255)) AS description,
    CAST(Quantity AS INT) AS quantity,
    CAST(InvoiceDate AS DATETIME) AS invoice_date,
    CAST(Price AS DECIMAL(10,2)) AS unit_price,
    CAST([Customer ID] AS VARCHAR(10)) AS customer_id,
    CAST(Country AS VARCHAR(50)) AS country,
    -- Derived columns
    CAST(Quantity AS INT) * CAST(Price AS DECIMAL(10,2)) AS line_total,
    CASE WHEN Invoice LIKE 'C%' THEN 1 ELSE 0 END AS is_cancellation
INTO dbo.clean_transactions
FROM dbo.stg_online_retail
WHERE 1=1
    -- Remove rows where quantity or price cannot be parsed
    AND TRY_CAST(Quantity AS INT) IS NOT NULL
    AND TRY_CAST(Price AS DECIMAL(10,2)) IS NOT NULL
    -- Remove rows with zero price (adjustments, not real sales)
    AND TRY_CAST(Price AS DECIMAL(10,2)) > 0
    -- Remove rows with missing customer ID (cannot be used for RFM or cohort)
    AND [Customer ID] IS NOT NULL
    AND [Customer ID] <> ''
    -- Remove rows where invoice date cannot be parsed
    AND TRY_CAST(InvoiceDate AS DATETIME) IS NOT NULL;
GO

-- Summary of what was kept vs removed
SELECT
    (SELECT COUNT(*) FROM dbo.stg_online_retail) AS original_rows,
    (SELECT COUNT(*) FROM dbo.clean_transactions) AS clean_rows,
    (SELECT COUNT(*) FROM dbo.stg_online_retail) - (SELECT COUNT(*) FROM dbo.clean_transactions) AS removed_rows;
GO

-- Cancellation summary (keep these for cancellation analysis but exclude from revenue)
SELECT
    is_cancellation,
    COUNT(*) AS row_count,
    SUM(line_total) AS total_value
FROM dbo.clean_transactions
GROUP BY is_cancellation;
GO

-- Date range
SELECT
    MIN(invoice_date) AS earliest_date,
    MAX(invoice_date) AS latest_date
FROM dbo.clean_transactions;
GO

PRINT 'Staging data cleaned. Review summaries above.';
