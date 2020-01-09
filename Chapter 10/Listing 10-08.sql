--10.8 Same Month, Prior Year
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
        ROUND(SUM(COALESCE(f.SalesAmount,0)), 2) AS [Sales],
	ROUND(SUM(SUM(COALESCE(f.SalesAmount, 0)))
                    OVER(PARTITION BY p.CalendarYear
                        ORDER BY p.CalendarYear, p.CalendarMonth
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                        ), 2) AS [Sales YTD],
    	ROUND(LAG(SUM(f.SalesAmount), 12 , 0) 
                OVER(ORDER BY p.CalendarYear, p.CalendarMonth),2) 
            as [Sales Same Month PY]
FROM CTE_ProductPeriod AS p
LEFT OUTER JOIN [dbo].[FactInternetSales] AS f
    ON p.ProductKey = f.ProductKey
    AND p.DateKey = f.OrderDateKey
GROUP BY p.CalendarYear, p.CalendarMonth
ORDER BY p.CalendarYear, p.CalendarMonth
