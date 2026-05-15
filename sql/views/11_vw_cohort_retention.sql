S-- ============================================
-- 11_vw_cohort_retention.sql
-- Cohort analysis: group customers by first purchase month
-- Track repeat purchase rates over subsequent months
-- ============================================

USE OnlineRetailDB;
GO

IF OBJECT_ID('dbo.vw_cohort_retention', 'V') IS NOT NULL
    DROP VIEW dbo.vw_cohort_retention;
GO

CREATE VIEW dbo.vw_cohort_retention AS
WITH CustomerCohort AS (
    -- Assign each customer to their first purchase month
    SELECT
        c.customer_key,
        FORMAT(c.first_purchase_date, 'yyyy-MM') AS cohort_month,
        c.first_purchase_date
    FROM dbo.DimCustomer c
),
CustomerActivity AS (
    -- Get each customer's activity months
    SELECT DISTINCT
        f.customer_key,
        d.year_month AS activity_month,
        d.full_date
    FROM dbo.FactSales f
    INNER JOIN dbo.DimDate d ON f.date_key = d.date_key
),
CohortActivity AS (
    -- Join cohort assignment to activity and compute months since signup
    SELECT
        cc.cohort_month,
        ca.activity_month,
        cc.customer_key,
        DATEDIFF(MONTH, cc.first_purchase_date, ca.full_date) AS months_since_signup
    FROM CustomerCohort cc
    INNER JOIN CustomerActivity ca ON cc.customer_key = ca.customer_key
)
SELECT
    cohort_month,
    months_since_signup,
    COUNT(DISTINCT customer_key) AS active_customers,
    -- Cohort starting size for retention rate calculation
    FIRST_VALUE(COUNT(DISTINCT customer_key)) OVER (
        PARTITION BY cohort_month ORDER BY months_since_signup
    ) AS cohort_size,
    -- Retention rate
    CAST(COUNT(DISTINCT customer_key) AS FLOAT) /
        NULLIF(FIRST_VALUE(COUNT(DISTINCT customer_key)) OVER (
            PARTITION BY cohort_month ORDER BY months_since_signup
        ), 0) AS retention_rate
FROM CohortActivity
WHERE months_since_signup >= 0
GROUP BY cohort_month, months_since_signup;
GO

PRINT 'vw_cohort_retention created.';
