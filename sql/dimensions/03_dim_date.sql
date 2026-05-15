S-- ============================================
-- 03_dim_date.sql
-- Create and populate the date dimension table
-- Covers the full range of dates in the dataset
-- ============================================

USE OnlineRetailDB;
GO

IF OBJECT_ID('dbo.DimDate', 'U') IS NOT NULL
    DROP TABLE dbo.DimDate;
GO

CREATE TABLE dbo.DimDate (
    date_key        INT PRIMARY KEY,        -- YYYYMMDD format
    full_date       DATE NOT NULL,
    day_of_month    INT NOT NULL,
    day_of_week     VARCHAR(10) NOT NULL,
    day_of_week_num INT NOT NULL,           -- 1=Monday, 7=Sunday
    week_of_year    INT NOT NULL,
    month_name      VARCHAR(10) NOT NULL,
    month_num       INT NOT NULL,
    quarter         INT NOT NULL,
    year            INT NOT NULL,
    year_month      VARCHAR(7) NOT NULL,    -- YYYY-MM for trend charts
    year_quarter    VARCHAR(7) NOT NULL,    -- YYYY-Q# for quarterly view
    is_weekend      BIT NOT NULL
);
GO

-- Populate with a date range covering the dataset (2009-01-01 to 2012-12-31)
-- Using a recursive CTE to generate all dates
;WITH DateSeries AS (
    SELECT CAST('2009-01-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt)
    FROM DateSeries
    WHERE dt < '2012-12-31'
)
INSERT INTO dbo.DimDate (
    date_key, full_date, day_of_month, day_of_week, day_of_week_num,
    week_of_year, month_name, month_num, quarter, year,
    year_month, year_quarter, is_weekend
)
SELECT
    CAST(FORMAT(dt, 'yyyyMMdd') AS INT) AS date_key,
    dt AS full_date,
    DAY(dt) AS day_of_month,
    DATENAME(WEEKDAY, dt) AS day_of_week,
    DATEPART(WEEKDAY, dt) AS day_of_week_num,
    DATEPART(WEEK, dt) AS week_of_year,
    DATENAME(MONTH, dt) AS month_name,
    MONTH(dt) AS month_num,
    DATEPART(QUARTER, dt) AS quarter,
    YEAR(dt) AS year,
    FORMAT(dt, 'yyyy-MM') AS year_month,
    CONCAT(YEAR(dt), '-Q', DATEPART(QUARTER, dt)) AS year_quarter,
    CASE WHEN DATEPART(WEEKDAY, dt) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend
FROM DateSeries
OPTION (MAXRECURSION 2000);
GO

SELECT COUNT(*) AS date_rows FROM dbo.DimDate;
GO

PRINT 'DimDate created and populated.';
