--10.7 month level. Now handling gaps in transaction dates
WITH CTE_ProductPeriod  
AS (
    SELECT p.ProductKey, p.ProductAlternateKey as [ProductID],
        Datekey, CalendarYear, 
        CalendarQuarter, MonthNumberOfYear AS CalendarMonth
    FROM DimDate AS d
    CROSS JOIN DimProduct p
    WHERE d.FullDateAlternateKey BETWEEN '2011-01-01' AND '2013-12-31'
    AND EXISTS(SELECT * FROM FactInternetSales f 
               WHERE f.ProductKey = p.ProductKey 
               AND f.OrderDate BETWEEN '2011-01-01' AND '2013-12-31')
   )
 SELECT	ROW_NUMBER() 
        OVER(ORDER BY p.[ProductID], 
                    p.CalendarYear, 
                    p.CalendarMonth
                ) as [RowID],
        p.[ProductID],
        p.CalendarYear  AS OrderYear,
        p.CalendarMonth AS OrderMonth,
        ROUND(SUM(COALESCE(f.SalesAmount,0)), 2) AS [Sales], 
        ROUND(SUM(SUM(f.SalesAmount))
                  OVER(PARTITION BY p.[ProductID], p.CalendarYear
                    ORDER BY P.[ProductID], p.CalendarYear, p.CalendarMonth
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                  ), 2) AS [Sales YTD],
        ROUND(SUM(SUM(COALESCE(f.SalesAmount, 0))) 
                  OVER(PARTITION BY p.[ProductID] 
                    ORDER BY p.[ProductID], p.CalendarYear, p.CalendarMonth
                    ROWS BETWEEN 3 PRECEDING AND CURRENT ROW 
		   ) / 3, 2) AS [3 Month Moving Avg]
FROM CTE_ProductPeriod AS p
LEFT OUTER JOIN [dbo].[FactInternetSales]  AS f
    ON p.ProductKey = f.ProductKey
    AND p.DateKey = f.OrderDateKey
WHERE p.ProductKey = 332
AND p.CalendarYear =  2011
GROUP BY p.[ProductID], p.CalendarYear, p.CalendarMonth
ORDER BY p.[ProductID], p.CalendarYear, p.CalendarMonth
