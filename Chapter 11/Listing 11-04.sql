/*
Calculate parts needed for a Pareto analysis/chart:
1. Overall Total
2. Per 'bucket' Total, for ordering
3. Cumulative Total, ordered by 'bucket' Totals
4. % of Overall Total for each 'bucket'

[All Sales] = SUM([SalesAmount])
[Cumulative Sales] = cumulative SUM( [SalesAmount])
[PARETO] = [Cumulative Sales] / [All Sales]


No need to use a CTE to pre-aggregate the sub category amounts. Just use SUM() with the ORDER BY 
*/
SET STATISTICS IO ON;
go

SELECT ps.EnglishProductSubcategoryName AS [Sub Category],
	SUM(f.SalesAmount) AS [Sub Category Sales],
	SUM(SUM(f.SalesAmount)) OVER () 		AS [All Sales],
	SUM(SUM(f.SalesAmount)) OVER (ORDER BY SUM(f.SalesAmount) DESC)	AS [Cumulative Sales],
	SUM(SUM(f.SalesAmount)) OVER (ORDER BY SUM(f.SalesAmount) DESC)
		/ SUM(SUM(f.SalesAmount)) OVER () AS [Sales Pareto]
FROM dbo.FactInternetSales AS f
INNER JOIN dbo.DimProduct AS p
	ON f.ProductKey = p.ProductKey
	INNER JOIN dbo.DimProductSubcategory AS ps
		ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
WHERE OrderDate BETWEEN '2011-01-01' AND '2012-12-31'
GROUP BY ps.ProductSubCategoryKey,
	ps.EnglishProductSubcategoryName
order by [Sales Pareto]

go
