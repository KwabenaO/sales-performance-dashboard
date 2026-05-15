-- ============================================
-- 05_dim_product.sql
-- Create product dimension from clean transactions
-- Handles description inconsistencies by taking the most frequent description per StockCode
-- ============================================

USE OnlineRetailDB;
GO

IF OBJECT_ID('dbo.DimProduct', 'U') IS NOT NULL
    DROP TABLE dbo.DimProduct;
GO

-- Get the most common description for each StockCode
;WITH RankedDescriptions AS (
    SELECT
        stock_code,
        description,
        AVG(unit_price) AS avg_unit_price,
        COUNT(*) AS usage_count,
        ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY COUNT(*) DESC) AS rn
    FROM dbo.clean_transactions
    WHERE is_cancellation = 0
        AND description IS NOT NULL
        AND description <> ''
    GROUP BY stock_code, description
)
SELECT
    ROW_NUMBER() OVER (ORDER BY stock_code) AS product_key,
    stock_code,
    description,
    CAST(avg_unit_price AS DECIMAL(10,2)) AS avg_unit_price
INTO dbo.DimProduct
FROM RankedDescriptions
WHERE rn = 1;
GO

ALTER TABLE dbo.DimProduct
ALTER COLUMN product_key BIGINT NOT NULL;
GOS

ALTER TABLE dbo.DimProduct
ADD CONSTRAINT PK_DimProduct PRIMARY KEY (product_key);
GO

SELECT COUNT(*) AS unique_products FROM dbo.DimProduct;
GO

PRINT 'DimProduct created.';
