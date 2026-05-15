-- ============================================
-- 00_create_database.sql
-- Create the OnlineRetailDB database and staging table
-- Run this in SSMS connected to your SQL Server Express instance
-- ============================================

-- Create database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'OnlineRetailDB')
BEGIN
    CREATE DATABASE OnlineRetailDB;
END
GO

USE OnlineRetailDB;
GO

-- Drop staging table if it exists (for re-runs)
IF OBJECT_ID('dbo.stg_online_retail', 'U') IS NOT NULL
    DROP TABLE dbo.stg_online_retail;
GO

-- Create staging table matching the Kaggle CSV structure
-- All columns are VARCHAR at this stage to avoid import errors
-- Data type enforcement happens in the cleaning step
CREATE TABLE dbo.stg_online_retail (
    Invoice         VARCHAR(10),
    StockCode       VARCHAR(20),
    Description     VARCHAR(255),
    Quantity        VARCHAR(20),
    InvoiceDate     VARCHAR(50),
    Price           VARCHAR(20),
    [Customer ID]   VARCHAR(20),
    Country         VARCHAR(50)
);
GO

PRINT 'Database and staging table created successfully.';
