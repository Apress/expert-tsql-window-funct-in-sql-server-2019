--10.3 Annual and monthly Percentage of Parent 
/*
[Sales Amt] = SUM of SalesAmount by Product, Year and Month
[All Sales] = SUM of SalesAmount for all Products and all dates
[Annual Sales] = SUM of SalesAmount for all Products, by Year
[Month All Sales] = SUM of SalesAmount for all Product by Year and Month
[Product All Sales] = SUM of SalesAmount by Product, for all dates
[Product Annual Sales] = SUM of SalesAmount by Product, by Year
[Ratio to of All Sales] = [Product All Sales] / [All Sales]
[Ratio to Annual Sales] = [Product Annual Sales] / [Annual Sales] 
[Ratio to Month Sales] = [Sales Amt] / [Month All Sales]
*/
SET STATISTICS IO ON;
go
SELECT f.ProductKey, 
    YEAR(f.orderdate) AS OrderYear, 
    MONTH(f.orderdate) AS OrderMonth, 
    SUM(f.SalesAmount) AS [Sales],
        SUM(SUM(f.SalesAmount)) OVER () 
		AS [All Sales],
    SUM(SUM(f.SalesAmount)) 
        OVER (PARTITION BY YEAR(f.OrderDate)) 
		AS [Annual Sales],
	SUM(SUM(f.SalesAmount)) 
        OVER (PARTITION BY YEAR(f.OrderDate), MONTH(f.OrderDate)) 
        AS [Month All Sales],
    SUM(SUM(f.SalesAmount)) OVER (PARTITION BY f.productkey)
        AS [Product All Sales],
    SUM(SUM(f.SalesAmount)) 
        OVER (PARTITION BY f.productkey, YEAR(f.OrderDate))	
        AS [Product Annual Sales],
--Combine above calculations to derive ratios:
    SUM(SUM(f.SalesAmount)) OVER (PARTITION BY f.productkey) 
        / SUM(SUM(f.SalesAmount)) OVER()
        AS [Ratio to All Sales],
    SUM(SUM(f.SalesAmount)) 
        OVER (PARTITION BY f.productkey, YEAR(f.OrderDate))
        / NULLIF(SUM(SUM(f.SalesAmount)) 
                 OVER (PARTITION BY YEAR(f.OrderDate))
                , 0) AS [Ratio to Annual Sales],
    SUM(SUM(f.SalesAmount)) 
        OVER (PARTITION BY f.productkey, YEAR(f.OrderDate),
                MONTH(f.OrderDate))
	/ NULLIF(SUM(SUM(f.SalesAmount)) 
                 OVER (PARTITION BY YEAR(f.OrderDate), MONTH(f.OrderDate))
                , 0) AS [Ratio to Month Sales]
FROM dbo.FactInternetSales AS f
WHERE OrderDate BETWEEN '2011-01-01' AND '2012-12-31'
GROUP BY f.ProductKey, 
    YEAR(f.orderdate), 
    MONTH(f.orderdate)
ORDER BY 2, 3, f.ProductKey;
go
