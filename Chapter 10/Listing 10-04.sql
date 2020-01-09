--10.4 Percent of Parent, Annual and Monthly sales
--Refactored to use a CTE, making the final SELECT readable by mere mortals.
/*
[Sales] = SUM of SalesAmount by Product, Year and Month
[All Sales] = SUM of SalesAmount for all Products and all dates
[Annual Sales] = SUM of SalesAmount for all Products, by Year
[Month All Sales] = SUM of SalesAmount for all Product by Year and Month
[Product All Sales] = SUM of SalesAmount by Product, for all dates
[Product Annual Sales] = SUM of SalesAmount by Product, by Year
[Ratio to All Sales] = [Product All Sales] / [All Sales]
[Ratio to Annual Sales] = [Product Annual Sales] / [Annual Sales] 
[Ratio to Month Sales] = [Sales] / [Month All Sales]
*/
WITH CTE_Base
AS ( SELECT f.ProductKey, 
	YEAR(f.orderdate) AS OrderYear, 
	MONTH(f.orderdate) AS OrderMonth, 
	SUM(f.SalesAmount) AS [Sales],
		SUM(SUM(f.SalesAmount)) OVER () AS [All Sales],
	SUM(SUM(f.SalesAmount)) OVER (PARTITION BY f.productkey)
		AS [Product All Sales],
	SUM(SUM(f.SalesAmount)) 
		OVER (PARTITION BY YEAR(f.OrderDate)) AS [Annual Sales],
	SUM(SUM(f.SalesAmount)) 
		OVER (PARTITION BY YEAR(f.OrderDate), MONTH(f.OrderDate)) 
		AS [Month All Sales],
	SUM(SUM(f.SalesAmount)) 
		OVER (PARTITION BY f.productkey, YEAR(f.OrderDate))	
		AS [Product Annual Sales]
	FROM dbo.FactInternetSales AS f
WHERE OrderDate BETWEEN '2011-01-01' AND '2012-12-31'
GROUP BY f.ProductKey, 
	YEAR(f.orderdate), 
	MONTH(f.orderdate)
	)
SELECT ProductKey, 
		OrderYear, 
		OrderMonth, 
		[Sales],
		[Product All Sales] / [All Sales] AS [Ratio to All Sales],
	    [Product Annual Sales] / NULLIF([Annual Sales], 0) AS [Ratio to Annual Sales],
		[Sales] / NULLIF([Month All Sales], 0) AS [Ratio to Month Sales]
FROM CTE_Base
ORDER BY OrderYear, 
		OrderMonth, 
		ProductKey;