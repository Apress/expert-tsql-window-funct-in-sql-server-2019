--10.2 All Sales, % of All sales
SELECT f.ProductKey, 
    YEAR(f.orderdate) AS OrderYear, 
    MONTH(f.orderdate) AS OrderMonth, 
    SUM(f.SalesAmount) AS [Sales],
        SUM(SUM(f.SalesAmount)) OVER () AS [All Sales],
    SUM(SUM(f.SalesAmount)) OVER (PARTITION BY f.productkey)
        AS [Product All Sales],
    SUM(SUM(f.SalesAmount)) OVER (PARTITION BY f.productkey) 
        / SUM(SUM(f.SalesAmount)) OVER()
        AS [Ratio to All Sales]
FROM dbo.FactInternetSales AS f
WHERE OrderDate BETWEEN '2011-01-01' AND '2012-12-31'
GROUP BY f.ProductKey, 
    YEAR(f.orderdate), 
    MONTH(f.orderdate)
ORDER BY 2, 3, f.ProductKey;