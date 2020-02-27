--5-1.1 A theoretical query 
SELECT SUM(TotalDue) OVER(ORDER BY OrderDate
RANGE BETWEEN INTERVAL 5 MONTH PRECEDING and 1 MONTH FOLLOWING
) SixMonthTotal
FROM Sales.SalesOrderHeader;

--5-2.1 Running and reverse running totals
SELECT CustomerID, CAST(OrderDate AS DATE) AS OrderDate, SalesOrderID, TotalDue,
    SUM(TotalDue) OVER(PARTITION BY CustomerID ORDER BY SalesOrderID 
    ROWS UNBOUNDED PRECEDING) AS RunningTotal,
    SUM(TotalDue) OVER(PARTITION BY CustomerID ORDER BY SalesOrderID 
    ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS ReverseTotal
FROM Sales.SalesOrderHeader
ORDER BY CustomerID, SalesOrderID;

--5-2.2 Moving sum and average
SELECT YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth,
    COUNT(*) AS OrderCount,
    SUM(COUNT(*)) OVER(ORDER BY YEAR(OrderDate), MONTH(OrderDate) 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthCount,
    AVG(COUNT(*)) OVER(ORDER BY YEAR(OrderDate), MONTH(OrderDate) 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthAvg
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2012-01-01' AND OrderDate < '2013-01-01'
GROUP BY YEAR(OrderDate), MONTH(OrderDate);

--5-3.1 Filter rows with less than 2 preceding rows
WITH Sales AS (
    SELECT YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth,
        COUNT(*) AS OrderCount,
        SUM(COUNT(*)) OVER(ORDER BY YEAR(OrderDate), MONTH(OrderDate) 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthCount,
        AVG(COUNT(*)) OVER(ORDER BY YEAR(OrderDate), MONTH(OrderDate) 
             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthAvg,
        ROW_NUMBER() OVER(PARTITION BY YEAR(OrderDate) 
            ORDER BY MONTH(OrderDate)) AS RowNum
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT OrderYear, OrderMonth, OrderCount, ThreeMonthCount, ThreeMonthAvg 
FROM Sales
WHERE RowNum >= 3;

--5-4.1 Running and reverse running totals
SELECT CustomerID, CAST(OrderDate AS DATE) AS OrderDate, SalesOrderID, TotalDue,
    SUM(TotalDue) OVER(PARTITION BY CustomerID ORDER BY SalesOrderID) AS RunningTotal,
    SUM(TotalDue) OVER(PARTITION BY CustomerID ORDER BY SalesOrderID DESC
    ) AS ReverseTotal
FROM Sales.SalesOrderHeader
ORDER BY CustomerID, SalesOrderID;

--5-5.1 Compare the logical difference between ROWS and RANGE
SELECT CustomerID, CAST(OrderDate AS DATE) AS OrderDate, SalesOrderID, TotalDue, 
    SUM(TotalDue) OVER(ORDER BY OrderDate
        ROWS UNBOUNDED PRECEDING) AS RunningTotalRows,
    SUM(TotalDue) OVER(ORDER BY OrderDate
        RANGE UNBOUNDED PRECEDING) AS RunningTotalRange	
FROM Sales.SalesOrderHeader 
WHERE CustomerID =11300
ORDER BY SalesOrderID;

--5-6.1 Look at the older technique
SELECT CustomerID, CAST(OrderDate AS DATE) AS OrderDate, 
    SalesOrderID, TotalDue,
    (SELECT SUM(TotalDue) 
    FROM Sales.SalesOrderHeader AS IQ
    WHERE IQ.CustomerID = OQ.CustomerID 
        AND IQ.OrderDate <= OQ.OrderDate) AS RunningTotal
FROM Sales.SalesOrderHeader AS OQ
WHERE CustomerID =11300
ORDER BY SalesOrderID;



