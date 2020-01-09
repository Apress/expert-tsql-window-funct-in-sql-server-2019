--10.10 Comparing the current month to the prior month
WITH CTE_ProductPeriod 
AS (
    SELECT p.ProductKey, --p.ProductAlternateKey as [ProductID],
           Datekey, CalendarYear, CalendarQuarter, 
           MonthNumberOfYear AS CalendarMonth
    FROM DimDate AS d
    CROSS JOIN DimProduct p
	WHERE d.FullDateAlternateKey BETWEEN '2011-01-01' AND '2013-12-31'
        AND EXISTS(SELECT * FROM FactInternetSales f 
                    WHERE f.ProductKey = p.ProductKey 
                    AND f.OrderDate BETWEEN '2011-01-01' AND '2013-12-31')
    )
 SELECT		
        ROW_NUMBER() 
           OVER(ORDER BY p.CalendarYear, p.CalendarMonth) as [RowID],
        p.CalendarYear AS OrderYear,
        p.CalendarMonth AS OrderMonth,
        ROUND(SUM(COALESCE(f.SalesAmount,0)), 2) AS [Sales Amt],
	   ROUND(SUM(SUM(COALESCE(f.SalesAmount, 0)))
                    OVER(PARTITION BY p.CalendarYear
                        ORDER BY p.CalendarYear, p.CalendarMonth
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                        ), 2) AS [Sales Amt YTD],
 /*   	   ROUND(LAG(SUM(f.SalesAmount), 12 , 0) 
                OVER(ORDER BY p.CalendarYear, p.CalendarMonth), 2) 
            as [Sales Amt Same Month PY],
     -- [Diff] = [CY] - [PY]
        ROUND(SUM(COALESCE(f.SalesAmount,0)) 
	  - LAG(SUM(f.SalesAmount), 12, 0) 
                OVER(ORDER BY p.CalendarYear, p.CalendarMonth), 2) 
        as [PY MOM Diff],  
     -- [Pct Diff] = ([CY] - [PY]) / [PY]
        (SUM(COALESCE(f.SalesAmount,0)) 
           - LAG(SUM(f.SalesAmount), 12, 0) 
                OVER(ORDER BY p.CalendarYear, p.CalendarMonth)
           ) / nullif(LAG(SUM(f.SalesAmount), 12, 0 ) 
                OVER(ORDER BY p.CalendarYear, p.CalendarMonth), 0) 
           as [PY MOM Diff %],
*/
	   LAG(SUM(f.SalesAmount), 1, 0)
           OVER(ORDER BY p.CalendarYear, p.CalendarMonth) as [Sales Amt PM],
     -- [Growth] = [CM] - [PM]
	   SUM(COALESCE(f.SalesAmount,0)) 
	     - LAG(SUM(f.SalesAmount), 1, 0)
                OVER(ORDER BY p.CalendarYear, p.CalendarMonth) 
           AS [PM MOM Growth],
     -- [Pct Growth] = ([CM] - [PM]) / [PM]
        (SUM(COALESCE(f.SalesAmount,0)) 
           - LAG(SUM(f.SalesAmount), 1, 0) 
               OVER(ORDER BY p.CalendarYear, p.CalendarMonth))
            / NULLIF(LAG(SUM(f.SalesAmount), 1, 0 ) 
                    OVER(ORDER BY p.CalendarYear, p.CalendarMonth),0) 
           AS [PM MOM Growth %]
FROM CTE_ProductPeriod AS p
LEFT OUTER JOIN [dbo].[FactInternetSales] AS f
    ON p.ProductKey = f.ProductKey
    AND p.DateKey = f.OrderDateKey
GROUP BY p.CalendarYear, p.CalendarMonth
ORDER BY p.CalendarYear, p.CalendarMonth

