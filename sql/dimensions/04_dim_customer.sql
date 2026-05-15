-- ============================================
-- 04_dim_customer.sql
-- Create customer dimension from clean transactions
-- One row per unique customer with first purchase date
-- ============================================

USE OnlineRetailDB;
GO

IF OBJECT_ID('dbo.DimCustomer', 'U') IS NOT NULL
    DROP TABLE dbo.DimCustomer;
GO

SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id) AS customer_key,
    customer_id,
    MIN(invoice_date) AS first_purchase_date,
    MAX(invoice_date) AS last_purchase_date,
    MIN(country) AS country  -- Use most common country if customer has multiple
INTO dbo.DimCustomer
FROM dbo.clean_transactions
WHERE is_cancellation = 0
GROUP BY customer_id;
GO

-- Add primary key
ALTER TABLE dbo.DimCustomer
ALTER COLUMN customer_key BIGINT NOT NULL;
GO
S
ALTER TABLE dbo.DimCustomer
ADD CONSTRAINT PK_DimCustomer PRIMARY KEY (customer_key);
GO

SELECT COUNT(*) AS unique_customers FROM dbo.DimCustomer;
GO

PRINT 'DimCustomer created.';
