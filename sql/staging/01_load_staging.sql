-- ============================================
-- 01_load_staging.sql
-- Import the Kaggle CSV into the staging table
-- Update the file path to match your local download location
-- ============================================

USE OnlineRetailDB;
GO

-- Clear staging table for fresh load
TRUNCATE TABLE dbo.stg_online_retail;
GO

-- Option 1: BULK INSERT (update the file path)
-- The Kaggle download may contain two sheets (Year 2009-2010 and Year 2010-2011)
-- Export each sheet as a separate CSV if needed, or use the combined version

BULK INSERT dbo.stg_online_retail
FROM 'C:\path\to\your\online_retail_II.csv'  -- UPDATE THIS PATH
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,          -- Skip header row
    CODEPAGE = '65001',    -- UTF-8 encoding
    TABLOCK
);
GO

-- Verify row count
SELECT COUNT(*) AS total_rows FROM dbo.stg_online_retail;
GO

-- Preview first 10 rows
SELECT TOP 10 * FROM dbo.stg_online_retail;
GO

-- Check for common issues
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN [Customer ID] = '' OR [Customer ID] IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN Invoice LIKE 'C%' THEN 1 ELSE 0 END) AS cancellations,
    SUM(CASE WHEN TRY_CAST(Price AS DECIMAL(10,2)) <= 0 THEN 1 ELSE 0 END) AS zero_or_negative_price,
    SUM(CASE WHEN TRY_CAST(Quantity AS INT) < 0 THEN 1 ELSE 0 END) AS negative_quantity
FROM dbo.stg_online_retail;
GO

PRINT 'Staging data loaded. Review the data quality summary above.';
