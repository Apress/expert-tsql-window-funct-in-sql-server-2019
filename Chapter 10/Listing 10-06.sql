--10.6 Handling gaps in dates, Month level: not handling gaps
SELECT ROW_NUMBER() 
       OVER(ORDER BY f.ProductKey, YEAR(f.OrderDate), MONTH(f.OrderDate)) 
      AS [RowID],
    f.ProductKey,
    YEAR(f.OrderDate) AS OrderYear,
    MONTH(f.OrderDate) AS OrderMonth,
    ROUND(SUM(f.SalesAmount), 2) AS [Sales], -- month level
    ROUND(SUM(SUM(f.SalesAmount))
        OVER(PARTITION BY f.ProductKey, YEAR(f.OrderDate)
            ORDER BY f.ProductKey, YEAR(f.OrderDate), MONTH(f.OrderDate)
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ), 2) AS [Sales YTD],
    ROUND(AVG(SUM(f.SalesAmount)) 
        OVER(PARTITION BY f.ProductKey 
            ORDER BY f.ProductKey, YEAR(f.OrderDate), MONTH(f.OrderDate)  
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW 
            ),2) AS [3 Month Moving Avg]
FROM [dbo].[FactInternetSales] AS f
WHERE ProductKey = 332
AND f.OrderDate BETWEEN '2010-12-01' AND '2011-12-31'
GROUP BY f.ProductKey, YEAR(f.OrderDate), MONTH(f.OrderDate) 
ORDER BY f.ProductKey ,YEAR(f.OrderDate), MONTH(f.OrderDate)
