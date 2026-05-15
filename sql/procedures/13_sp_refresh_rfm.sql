S-- ============================================
-- 13_sp_refresh_rfm.sql
-- Stored procedure to recalculate RFM scores
-- In production this would run on a schedule
-- For the portfolio it demonstrates stored procedure skills
-- ============================================

USE OnlineRetailDB;
GO

IF OBJECT_ID('dbo.sp_refresh_rfm', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_refresh_rfm;
GO

CREATE PROCEDURE dbo.sp_refresh_rfm
AS
BEGIN
    SET NOCOUNT ON;

    -- Log start
    PRINT 'RFM refresh started at ' + CONVERT(VARCHAR, GETDATE(), 120);

    -- Materialize RFM scores into a table for faster Power BI queries
    IF OBJECT_ID('dbo.rfm_scores', 'U') IS NOT NULL
        DROP TABLE dbo.rfm_scores;

    SELECT *
    INTO dbo.rfm_scores
    FROM dbo.vw_rfm_scores;

    -- Add index for Power BI performance
    CREATE NONCLUSTERED INDEX IX_rfm_segment
    ON dbo.rfm_scores (rfm_segment);

    -- Summary
    SELECT
        rfm_segment,
        COUNT(*) AS customer_count,
        AVG(recency_days) AS avg_recency,
        AVG(frequency) AS avg_frequency,
        AVG(CAST(monetary AS DECIMAL(12,2))) AS avg_monetary
    FROM dbo.rfm_scores
    GROUP BY rfm_segment
    ORDER BY avg_monetary DESC;

    PRINT 'RFM refresh completed at ' + CONVERT(VARCHAR, GETDATE(), 120);
END
GO

-- Run it
EXEC dbo.sp_refresh_rfm;
GO

PRINT 'sp_refresh_rfm created and executed.';
