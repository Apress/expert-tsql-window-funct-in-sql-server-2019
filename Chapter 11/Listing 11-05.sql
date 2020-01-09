--Rework example for just the bikes subcategory

SELECT p.EnglishProductName as [Product],
	SUM(f.SalesAmount) AS [Sub Category Sales],
	SUM(f.OrderQuantity) AS [Sub Category Qty],
	SUM(SUM(f.SalesAmount)) OVER (ORDER BY SUM(f.SalesAmount) DESC)
		/ SUM(SUM(f.SalesAmount)) OVER () AS [Sales Pareto]
FROM dbo.FactInternetSales AS f
INNER JOIN dbo.DimProduct AS p
	ON f.ProductKey = p.ProductKey
	INNER JOIN dbo.DimProductSubcategory AS ps
		ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
WHERE OrderDate BETWEEN '2011-01-01' AND '2012-12-31'
and ps.EnglishProductSubcategoryName = 'Road Bikes'
GROUP BY P.EnglishProductName
,ps.ProductSubCategoryKey,
	ps.EnglishProductSubcategoryName
order by [Sales Pareto]


