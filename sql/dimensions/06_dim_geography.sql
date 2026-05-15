-- ============================================
-- 06_dim_geography.sql
-- Create geography dimension from distinct countries
-- Adds region grouping for higher-level analysis
-- ============================================

USE OnlineRetailDB;
GO

IF OBJECT_ID('dbo.DimGeography', 'U') IS NOT NULL
    DROP TABLE dbo.DimGeography;
GO

SELECT
    ROW_NUMBER() OVER (ORDER BY country) AS geography_key,
    country,
    CASE
        WHEN country = 'United Kingdom' THEN 'United Kingdom'
        WHEN country IN ('Germany', 'France', 'Spain', 'Italy', 'Netherlands',
                         'Belgium', 'Switzerland', 'Austria', 'Portugal',
                         'Finland', 'Denmark', 'Sweden', 'Norway', 'Iceland',
                         'Greece', 'Poland', 'Czech Republic', 'Lithuania',
                         'Malta', 'Cyprus', 'EIRE', 'Channel Islands') THEN 'Europe'
        WHEN country IN ('USA', 'Canada', 'Brazil') THEN 'Americas'
        WHEN country IN ('Japan', 'Singapore', 'Hong Kong', 'Israel',
                         'United Arab Emirates', 'Saudi Arabia', 'Bahrain',
                         'Lebanon', 'RSA') THEN 'Rest of World'
        ELSE 'Other'
    END AS region
INTO dbo.DimGeography
FROM (
    SELECT DISTINCT country
    FROM dbo.clean_transactions
    WHERE country IS NOT NULL AND country <> ''
) AS countries;
GO

ALTER TABLE dbo.DimGeography
ALTER COLUMN geographyS_key BIGINT NOT NULL;
GO

ALTER TABLE dbo.DimGeography
ADD CONSTRAINT PK_DimGeography PRIMARY KEY (geography_key);
GO

SELECT * FROM dbo.DimGeography ORDER BY region, country;
GO

PRINT 'DimGeography created.';
