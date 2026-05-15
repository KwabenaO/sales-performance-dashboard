Total # DAX Measures

All DAX measures used in the Power BI dashboard. Create these in Power BI Desktop
after connecting to SQL Server and building the data model.

## Core KPIs

```dax
Total Revenue = SUM(FactSales[line_total])

Total Orders = DISTINCTCOUNT(FactSales[invoice_no])

Unique Customers = DISTINCTCOUNT(FactSales[customer_key])

Total Units Sold = SUM(FactSales[quantity])

Average Order Value =
    DIVIDE(
        [Total Revenue],
        [Total Orders],
        0
    )

Average Unit Price =
    DIVIDE(
        [Total Revenue],
        [Total Units Sold],
        0
    )
```

## Growth Measures

```dax
Revenue Previous Month =
    CALCULATE(
        [Total Revenue],
        DATEADD(DimDate[full_date], -1, MONTH)
    )

Revenue MoM Growth % =
    VAR CurrentMonth = [Total Revenue]
    VAR PreviousMonth = [Revenue Previous Month]
    RETURN
        DIVIDE(
            CurrentMonth - PreviousMonth,
            PreviousMonth,
            0
        )

Revenue Previous Year =
    CALCULATE(
        [Total Revenue],
        DATEADD(DimDate[full_date], -1, YEAR)
    )

Revenue YoY Growth % =
    VAR CurrentYear = [Total Revenue]
    VAR PreviousYear = [Revenue Previous Year]
    RETURN
        DIVIDE(
            CurrentYear - PreviousYear,
            PreviousYear,
            0
        )
```

## Running Totals and Shares

```dax
Revenue Running Total =
    CALCULATE(
        [Total Revenue],
        FILTER(
            ALLSELECTED(DimDate[full_date]),
            DimDate[full_date] <= MAX(DimDate[full_date])
        )
    )

Revenue % of Grand Total =
    DIVIDE(
        [Total Revenue],
        CALCULATE([Total Revenue], ALL(FactSales)),
        0
    )
```

## Customer Measures

```dax
New Customers =
    VAR CurrentPeriodCustomers =
        CALCULATETABLE(
            VALUES(FactSales[customer_key]),
            DATESINPERIOD(DimDate[full_date], MAX(DimDate[full_date]), -1, MONTH)
        )
    VAR PriorCustomers =
        CALCULATETABLE(
            VALUES(FactSales[customer_key]),
            DATESINPERIOD(DimDate[full_date], MIN(DimDate[full_date]) - 1, -12, MONTH)
        )
    RETURN
        COUNTROWS(EXCEPT(CurrentPeriodCustomers, PriorCustomers))

Repeat Purchase Rate =
    VAR CustomersWithMultipleOrders =
        COUNTROWS(
            FILTER(
                ADDCOLUMNS(
                    VALUES(FactSales[customer_key]),
                    "OrderCount", [Total Orders]
                ),
                [OrderCount] > 1
            )
        )
    RETURN
        DIVIDE(
            CustomersWithMultipleOrders,
            [Unique Customers],
            0
        )

Customer Lifetime Value =
    DIVIDE(
        [Total Revenue],
        [Unique Customers],
        0
    )
```

## RFM Segment Measures

```dax
Customers in Segment =
    COUNTROWS(rfm_scores)

Segment Revenue Share =
    VAR SegmentCustomers = VALUES(rfm_scores[customer_key])
    VAR SegmentRevenue =
        CALCULATE(
            [Total Revenue],
            FILTER(FactSales, FactSales[customer_key] IN SegmentCustomers)
        )
    RETURN
        DIVIDE(
            SegmentRevenue,
            CALCULATE([Total Revenue], ALL(rfm_scores)),
            0
        )
```

## Formatting Notes
- Currency measures: format as $#,##0.00
- Percentage measures: format as 0.0%
- Count measures: format as #,##0
- Use conditional formatting on growth measures (green for positive, red for negative)
