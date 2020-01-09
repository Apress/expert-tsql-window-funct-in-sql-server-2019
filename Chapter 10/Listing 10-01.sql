--10.1 Base query. Just your average GROUP BY.
SELECT f.ProductKey, 
    YEAR(f.orderdate) AS OrderYear, 
    MONTH(f.orderdate) AS OrderMonth, 
    SUM(f.SalesAmount) AS [Sales]
FROM dbo.FactInternetSales AS f
WHERE OrderDate BETWEEN '2011-01-01' AND '2012-12-31'
GROUP BY f.ProductKey, 
    YEAR(f.orderdate), 
    MONTH(f.orderdate)
ORDER BY 2, 3, f.ProductKey;
