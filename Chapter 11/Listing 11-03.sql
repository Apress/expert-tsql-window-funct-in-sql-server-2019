/* 11.3 Month level, no product. Handling gaps, All products, 3 operation query
   Add Rate of Change calculations */
WITH CTE_ProductPeriod	/* Operation #1 Generate the product period framework */
AS  (
    SELECT p.ProductKey, Datekey, 
           CalendarYear, CalendarQuarter, 
           MonthNumberOfYear AS CalendarMonth
    FROM DimDate AS d
    CROSS JOIN DimProduct p
    WHERE d.FullDateAlternateKey BETWEEN '2011-01-01' AND GETDATE()
    AND EXISTS(SELECT * FROM FactInternetSales f 
                WHERE f.ProductKey = p.ProductKey 
                AND f.OrderDate BETWEEN '2011-01-01' AND GETDATE())
	),
CTE_MonthlySummary		/* Operation #2 Calculate the base statistics for the next operation */
AS (
    SELECT ROW_NUMBER() 
            OVER(ORDER BY p.CalendarYear, p.CalendarMonth) AS [RowID],
        p.CalendarYear AS OrderYear,
        p.CalendarMonth AS OrderMonth,
        COUNT(distinct f.SalesOrderNumber) AS [Order Count],
        COUNT(distinct f.CustomerKey) AS [Customer Count],
        ROUND(SUM(COALESCE(f.SalesAmount,0)), 2) AS [Sales],
        ROUND(SUM(SUM(COALESCE(f.SalesAmount, 0)))
                OVER(PARTITION BY p.CalendarYear
                    ORDER BY p.CalendarYear, p.CalendarMonth
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                    ), 2) 
            AS [Sales YTD],
    	ROUND(LAG(SUM(f.SalesAmount), 11, 0 ) 
                    OVER(ORDER BY p.CalendarYear, p.CalendarMonth), 2) 
            AS [Sales SP PY],
        ROUND(LAG(SUM(f.SalesAmount), 1, 0)
                    OVER(ORDER BY p.CalendarYear, p.CalendarMonth), 2) 
            AS [Sales PM],
		/* Validate COUNT logic */
		COUNT(*) OVER(ORDER BY p.CalendarYear, p.CalendarMonth  
                          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) 
			AS [Count Preceding03],
		COUNT(*) OVER(ORDER BY p.CalendarYear, p.CalendarMonth  
                          ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) 
			AS [Count Preceding12],
		CASE WHEN COUNT(*) 
                    OVER(ORDER BY p.CalendarYear, p.CalendarMonth  
                          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) = 3
             THEN AVG(SUM(f.SalesAmount)) 
                    OVER(ORDER BY p.CalendarYear, p.CalendarMonth 
                         ROWS BETWEEN 2 PRECEDING AND current row) 
             ELSE null
			END AS [Sales 3 MMA],  /* 3 Month Moving Average */
        CASE WHEN count(*) 
                    OVER(ORDER BY p.CalendarYear, p.CalendarMonth 
                         ROWS BETWEEN 2 PRECEDING AND current row) = 3
             THEN SUM(SUM(f.SalesAmount))
                    OVER(ORDER BY p.CalendarYear, p.CalendarMonth   
                         ROWS BETWEEN 2 PRECEDING AND current row) 
			 ELSE null
			END AS [Sales 3 MMT],   /* 3 month Moving Total */
        CASE WHEN COUNT(*) 
                    OVER (ORDER BY p.CalendarYear, p.CalendarMonth  
                         ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) = 12
             THEN AVG(SUM(f.SalesAmount)) 
                    OVER(ORDER BY p.CalendarYear, p.CalendarMonth 
                         ROWS BETWEEN 11 PRECEDING AND current row) 
             ELSE null
           END AS [Sales 12 MMA], /* 12 Month Moving Average */
        CASE WHEN count(*) 
                    OVER(ORDER BY p.CalendarYear, p.CalendarMonth 
			 ROWS BETWEEN 11 PRECEDING AND current row) = 12
        THEN SUM(SUM(f.SalesAmount)) 
                OVER (ORDER BY p.CalendarYear, p.CalendarMonth   
                        ROWS BETWEEN 11 PRECEDING AND current row) 
        ELSE null
      END AS [Sales 12 MMT]   /* 12 month Moving Total */
FROM CTE_ProductPeriod AS p
LEFT OUTER JOIN [dbo].[FactInternetSales] AS f
    ON p.ProductKey = f.ProductKey
    AND p.DateKey = f.OrderDateKey
GROUP BY p.CalendarYear, p.CalendarMonth
)
/* Operation #3 Return the final calculations */
SELECT [RowID],
    [OrderYear],
    [OrderMonth],	
    [Order Count],
    [Customer Count],
    [Sales],
    [Sales SP PY],	
    [Sales PM],
    [Sales YTD],
    [Sales 3 MMA],
    [Sales 3 MMT],
    [Sales 12 MMA],
    [Sales 12 MMT],
    [Sales] - [Sales SP PY] AS [Sales SP PY Growth],
    ([Sales] - [Sales SP PY]) 
        / NULLIF([Sales SP PY], 0) AS [Sales SP PY Growth %],
    [Sales] - [Sales SP PY] AS [Sales PM MOM Growth],
    ([Sales] - [Sales PM]) 
        / NULLIF([Sales PM], 0) AS [Sales PM MOM Growth %],
/* PY YTD calculations */
    LAG([Sales YTD], 11,0)
		OVER(ORDER BY [OrderYear], [OrderMonth]) 
        AS [Sales PY YTD],
    [Sales YTD] - LAG([Sales YTD], 11,0)
                          OVER(ORDER BY [OrderYear], [OrderMonth]) 
        AS [Sales PY YTD Growth],
    ([Sales YTD] - LAG([Sales YTD], 11,0) 
                          OVER(ORDER BY [OrderYear], [OrderMonth])) 
            /NULLIF(LAG([Sales YTD], 11, 0) 
                          OVER(ORDER BY [OrderYear], [OrderMonth]), 0) 
        AS [Sales PY YTD Growth %],
	/* [3/12 RoC] = [3 MMT]/([3 MMT].LAG( 11 months)) */
    [Sales 3 MMT] 
        / LAG(NULLIF([Sales 3 MMT], 0), 11, null) 
              OVER(ORDER BY [OrderYear], [OrderMonth]) as [3/12 RoC],
    /* [12/12 RoC] = [12 MMT] /([12 MMT].LAG( 11 months)) */
    [Sales 12 MMT] 
        / LAG(NULLIF([Sales 12 MMT],0), 11, null)
              OVER(ORDER BY [OrderYear], [OrderMonth]) as [12/12 RoC],
	/* [3/12 RoC2] =  ([3 MMT]/([3 MMT].LAG( 11 months))* 100) -100 */
    ([Sales 3 MMT] / LAG(NULLIF([Sales 3 MMT], 0), 11, null) 
		OVER(ORDER BY [OrderYear], [OrderMonth]) *100) - 100 as [3/12 RoC2],
    /* [12/12 RoC2] = ([12 MMT] /([12 MMT].LAG( 11 months))* 100) -100 */
	([Sales 12 MMT] / LAG(NULLIF([Sales 12 MMT],0), 11, null)
		OVER(ORDER BY [OrderYear], [OrderMonth]) *100) - 100 as [12/12 RoC2],
	[Count Preceding03],
	[Count Preceding12]
FROM CTE_MonthlySummary
where OrderYear < 2014 --filter out the empty trailing months
ORDER BY [OrderYear], [OrderMonth]

