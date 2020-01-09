--10.5 day level aggregates, with rolling totals for MTD, QTD, YTD
SELECT f.OrderDate, 
		f.ProductKey, 
        YEAR(f.orderdate) AS OrderYear, 
        MONTH(f.orderdate) AS OrderMonth, 
        SUM(f.SalesAmount) AS [Sales], 
        SUM(SUM(f.SalesAmount))
            OVER(PARTITION BY f.productkey, YEAR(f.orderdate), 
                 MONTH(f.orderdate)
                 ORDER BY f.productkey, f.orderdate 
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) AS [Sales MTD], 
        SUM(SUM(f.SalesAmount))
        OVER(PARTITION BY f.productkey, YEAR(f.orderdate),
             DATEPART(QUARTER, f.OrderDate)
             ORDER BY f.productkey, YEAR(f.orderdate), MONTH(f.orderdate)
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS [Sales QTD], 
        SUM(SUM(f.SalesAmount))
            OVER(PARTITION BY f.productkey, YEAR(f.orderdate)
            ORDER BY f.productkey, f.orderdate 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS [Sales YTD], 
        SUM(SUM(f.SalesAmount))
            OVER(PARTITION BY f.productkey 
            ORDER BY f.productkey, f.orderdate 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS [Sales Running Total] 
FROM dbo.FactInternetSales AS f
GROUP BY f.orderdate, f.ProductKey, YEAR(f.orderdate), MONTH(f.orderdate)
ORDER BY f.OrderDate, f.ProductKey;
