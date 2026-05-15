# Sales Performance and Revenue Analytics Dashboard

An end-to-end sales analytics pipeline that transforms raw transaction data into an interactive Power BI dashboard. Covers revenue trends, product performance, customer segmentation (RFM), geographic analysis, cohort retention, and revenue forecasting.

## Background and Overview

Sales Analysts spend most of their time answering recurring questions: how is revenue trending, which products are driving growth, which customers are at risk of lapsing, and where should the team focus. This project builds the infrastructure to answer all of those questions from a single dashboard.

The pipeline starts with raw transaction data from a UK-based online retailer (UCI Online Retail II dataset from Kaggle). The data is imported into SQL Server Express, cleaned, and transformed into a star schema with four dimension tables and one fact table. SQL views handle the heavy aggregation work including RFM customer segmentation and cohort retention analysis. Power BI connects to SQL Server, adds DAX measures for KPIs and growth calculations, and presents everything in a six-page interactive dashboard.

## Architecture

```
Kaggle CSV
    |
    v
SQL Server Express
    |
    ├── Staging table (raw import)
    ├── Clean transactions (data quality fixes)
    ├── Star schema:
    │   ├── DimDate
    │   ├── DimCustomer
    │   ├── DimProduct
    │   ├── DimGeography
    │   └── FactSales
    └── Views:
        ├── vw_revenue_monthly
        ├── vw_product_performance
        ├── vw_rfm_scores
        ├── vw_cohort_retention
        └── vw_geographic_sales
    |
    v
Power BI Desktop
    |
    ├── Data model (star schema relationships)
    ├── DAX measures (KPIs, growth, RFM, CLV)
    └── 6 dashboard pages
    |
    v
Power BI Service (Publish to Web)
```

## Live Dashboard

View the live dashboard on Power BI Service: [link](https://app.powerbi.com/reportEmbed?reportId=98f95570-32a6-47ae-8a02-e73035d26133&autoAuth=true&ctid=a8eec281-aaa3-4dae-ac9b-9a398b9215e7)

## Dashboard Pages

**Executive Overview:** Total revenue, orders, unique customers, and average order value. Monthly revenue trend with year-over-year comparison. Revenue by quarter and top 5 countries.

**Product Performance:** Top 10 products by revenue. Pareto chart showing that roughly 20% of products drive 80% of revenue. Revenue share by product.

**Customer Segmentation (RFM):** Customers scored on Recency, Frequency, and Monetary value, then classified into segments (Champions, Loyal, At Risk, Lost, etc). Segment distribution, profiles, and recommended actions.

**Geographic Analysis:** Revenue by country on a bubble map sized by revenue. Customer count by country. Revenue concentration analysis showing UK dominance vs rest of world.

**Cohort Analysis:** Customers grouped by first purchase month. Retention heatmap tracking repeat purchase rates over subsequent months. Cohort size trends and lifetime value by cohort.

**Forecasting:** Revenue forecast using Power BI's built-in forecasting. Seasonality decomposition and monthly growth rate trend.

## Dataset

**Source:** UCI Online Retail II from Kaggle
**URL:** https://www.kaggle.com/datasets/mashlyn/online-retail-ii-uci
**Records:** ~500,000+ transactions from a UK-based online retailer
**Period:** December 2009 to December 2011
**Columns:** Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer ID, Country

**Data quality issues handled in SQL:**
- Cancellations identified by invoice numbers starting with "C" (separated from revenue calculations)
- Missing Customer IDs removed (approximately 25% of records, cannot be used for RFM or cohort analysis)
- Zero and negative prices excluded (adjustments, not real sales)
- Product description inconsistencies resolved by taking the most frequent description per StockCode

## Design Decisions

- **SQL Server over flat CSV import**: connecting Power BI to a database mirrors how real BI environments work. It also demonstrates SQL data cleaning, star schema design, and view creation as separate skills.
- **Star schema over flat table**: dimension tables reduce data redundancy and improve Power BI query performance. The date dimension enables time intelligence DAX functions. Surrogate keys prevent issues with missing or changing natural keys.
- **RFM in SQL views**: computing RFM scores in SQL keeps the heavy calculation out of Power BI. The stored procedure can be scheduled in production to refresh scores regularly.
- **Cohort retention in SQL**: the retention matrix query is complex. Keeping it in a view makes the Power BI side simpler and the SQL is visible in the GitHub repo for interviewers to review.
- **Import mode over DirectQuery**: for a dataset this size, Import mode gives faster dashboard performance. DirectQuery would make sense for larger, frequently updated datasets.
- **Pareto analysis on products**: the 80/20 analysis immediately answers "which products matter?" and shows commercial thinking beyond just listing top sellers.

## Screenshots

Dashboard screenshots are available in the [screenshots/](screenshots/) folder.

## Tech Stack

SQL Server Express, SSMS, Power BI Desktop, Power BI Service, DAX

## Setup

```
1. Install SQL Server Express and SSMS
2. Download dataset from Kaggle into data/raw/
3. Run SQL scripts in order (00 through 13) in SSMS
4. Open Power BI Desktop and connect to SQL Server
5. Build data model, DAX measures, and dashboard pages
6. Publish to Power BI Service
```
