S-- ============================================
-- 10_vw_rfm_scores.sql
-- RFM customer segmentation
-- Recency: days since last purchase
-- Frequency: number of distinct orders
-- Monetary: total spend
-- Each scored 1-5 using NTILE, combined into segments
-- ============================================

USE OnlineRetailDB;
GO

IF OBJECT_ID('dbo.vw_rfm_scores', 'V') IS NOT NULL
    DROP VIEW dbo.vw_rfm_scores;
GO

CREATE VIEW dbo.vw_rfm_scores AS
WITH CustomerRFM AS (
    SELECT
        c.customer_key,
        c.customer_id,
        c.country,
        -- Recency: days since last purchase relative to max date in dataset
        DATEDIFF(DAY, MAX(d.full_date),
            (SELECT MAX(full_date) FROM dbo.DimDate dd
             INNER JOIN dbo.FactSales ff ON dd.date_key = ff.date_key)) AS recency_days,
        -- Frequency: number of distinct orders
        COUNT(DISTINCT f.invoice_no) AS frequency,
        -- Monetary: total spend
        SUM(f.line_total) AS monetary
    FROM dbo.FactSales f
    INNER JOIN dbo.DimCustomer c ON f.customer_key = c.customer_key
    INNER JOIN dbo.DimDate d ON f.date_key = d.date_key
    GROUP BY c.customer_key, c.customer_id, c.country
),
ScoredRFM AS (
    SELECT
        *,
        -- Score each dimension 1-5 (5 is best)
        -- For recency, lower days = better, so reverse the NTILE
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM CustomerRFM
)
SELECT
    *,
    -- Combined RFM score (concatenated)
    CONCAT(r_score, f_score, m_score) AS rfm_combined,
    -- Average score for simple ranking
    CAST((r_score + f_score + m_score) / 3.0 AS DECIMAL(3,1)) AS rfm_avg,
    -- Segment labels based on score patterns
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score >= 3 AND f_score >= 1 AND m_score >= 2 THEN 'Potential Loyalists'
        WHEN r_score >= 2 AND r_score <= 3 AND f_score >= 2 AND m_score >= 2 THEN 'Needs Attention'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'Cant Lose Them'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Other'
    END AS rfm_segment
FROM ScoredRFM;
GO

PRINT 'vw_rfm_scores created.';
