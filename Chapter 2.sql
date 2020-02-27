--2-1.1 Using ROW_NUMBER with and without a PARTITION BY
SELECT CustomerID, CAST(OrderDate AS DATE)
    AS OrderDate, SalesOrderID, 
    ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY SalesOrderID) 
        AS WithPart, 
    ROW_NUMBER() OVER(ORDER BY CustomerID) AS WithoutPart
FROM Sales.SalesOrderHeader;

--2-2.1 Query ORDER BY ascending
SELECT CustomerID, 
    CAST(OrderDate AS DATE) AS OrderDate, 
    SalesOrderID, 
    ROW_NUMBER() OVER(ORDER BY CustomerID) AS RowNumber
FROM Sales.SalesOrderHeader
ORDER BY CustomerID, SalesOrderID;

--2-2.2 Query ORDER BY descending
SELECT CustomerID, 
    CAST(OrderDate AS DATE) AS OrderDate, 
    SalesOrderID, 
    ROW_NUMBER() OVER(ORDER BY CustomerID) AS RowNumber
FROM Sales.SalesOrderHeader
ORDER BY CustomerID, SalesOrderID DESC;


--2-3.1 Using ROW_NUMBER a unique ORDER BY
SELECT CustomerID, 
	CAST(OrderDate AS DATE) AS OrderDate, 
	SalesOrderID, 
    ROW_NUMBER() OVER(ORDER BY CustomerID, SalesOrderID) AS RowNum
FROM Sales.SalesOrderHeader
ORDER BY CustomerID, SalesOrderID;

--2-3.2 Change to descending
SELECT CustomerID, 
	CAST(OrderDate AS Date) AS OrderDate, 
	SalesOrderID, 
    ROW_NUMBER() OVER(ORDER BY CustomerID, SalesOrderID) AS RowNum
FROM Sales.SalesOrderHeader
ORDER BY CustomerID, SalesOrderID DESC;

--2-4.1 Using RANK and DENSE_RANK
SELECT CustomerID, CAST(OrderDate AS DATE) AS OrderDate, 
    ROW_NUMBER() OVER(ORDER BY OrderDate) AS RowNumber, 
    RANK() OVER(ORDER BY OrderDate) AS [Rank],
    DENSE_RANK() OVER(ORDER BY OrderDate) AS DenseRank
FROM Sales.SalesOrderHeader
WHERE CustomerID IN (11330, 29676);

--2.5.1 Using NTILE
WITH Orders AS (
    SELECT MONTH(OrderDate) AS OrderMonth, 
        FORMAT(SUM(TotalDue),'C') AS Sales
    FROM Sales.SalesOrderHeader 
    WHERE OrderDate >= '2013/01/01' and OrderDate < '2014/01/01'
	GROUP BY MONTH(OrderDate))
SELECT OrderMonth, Sales, NTILE(4) OVER(ORDER BY Sales) AS Bucket
FROM Orders;

--2.6.1 Using NTILE with uneven buckets
WITH Orders AS (
    SELECT MONTH(OrderDate) AS OrderMonth, FORMAT(SUM(TotalDue),'C') 
        AS Sales
    FROM Sales.SalesOrderHeader 
    WHERE OrderDate >= '2013/01/01' and OrderDate < '2014/01/01'
    GROUP BY MONTH(OrderDate))
SELECT OrderMonth, Sales, NTILE(5) OVER(ORDER BY Sales) AS Bucket
FROM Orders;

--2-7.1 Create a table that will hold duplicate rows
CREATE TABLE #dupes(Col1 INT, Col2 CHAR(1));

--2-7.2 Insert some rows
INSERT INTO #dupes(Col1, Col2) 
VALUES (1,'a'),(1,'a'),(2,'b'),
    (3,'c'),(4,'d'),(4,'d'),(5,'e');

--2-7.3
SELECT Col1, Col2 
FROM #dupes; 

--2-8.1 Add ROW_NUMBER and Partition by all of the columns
SELECT Col1, Col2, 
    ROW_NUMBER() OVER(PARTITION BY Col1, Col2 ORDER BY Col1) AS RowNumber
FROM #dupes;

--2-8.2 Delete the rows with RowNumber > 1
WITH Dupes AS (
    SELECT Col1, Col2, 
        ROW_NUMBER() OVER(PARTITION BY Col1, Col2 ORDER BY Col1)
            AS RowNumber
    FROM #dupes)
DELETE Dupes WHERE RowNumber > 1;

--2-8.3 The results
SELECT Col1, Col2 
FROM #dupes;

--2-9.1 Using CROSS APPLY to find the first four orders
WITH Months AS (
    SELECT MONTH(OrderDate) AS OrderMonth
    FROM Sales.SalesOrderHeader 
    WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01'
    GROUP BY MONTH(OrderDate))
SELECT OrderMonth, CAST(CA.OrderDate AS DATE) AS OrderDate, 
    CA.SalesOrderID, CA.TotalDue
FROM Months
CROSS APPLY (
    SELECT TOP(4) SalesOrderID, OrderDate, TotalDue
    FROM Sales.SalesOrderHeader AS IQ
    WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01'
        AND MONTH(IQ.OrderDate) =MONTHS.OrderMonth 
    ORDER BY SalesOrderID) AS CA
ORDER BY OrderMonth, SalesOrderID;

--2-9.2 Use ROW_NUMBER to find the first four orders
WITH Orders AS (	
    SELECT  MONTH(OrderDate) AS OrderMonth, OrderDate,
        SalesOrderID, TotalDue, 
        ROW_NUMBER() OVER(PARTITION BY MONTH(OrderDate)
            ORDER BY SalesOrderID) AS RowNumber
    FROM Sales.SalesOrderHeader
    WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01')
SELECT OrderMonth, CAST(OrderDate AS DATE) AS OrderDate, 
    SalesOrderID, TotalDue 
FROM Orders 
WHERE RowNumber <= 4
ORDER BY OrderMonth, SalesOrderID;

--2-10.1 Use ROW_NUMBER to find the first four orders
WITH Orders AS (	
    SELECT  MONTH(OrderDate) AS OrderMonth, OrderDate,
        SalesOrderID, TotalDue, 
        ROW_NUMBER() OVER(PARTITION BY MONTH(OrderDate)
            ORDER BY TotalDue DESC) AS RowNumber
    FROM Sales.SalesOrderHeader
    WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01')
SELECT OrderMonth, CAST(OrderDate AS DATE) AS OrderDate, 
    SalesOrderID, 
    TotalDue 
FROM Orders 
WHERE RowNumber <= 4
ORDER BY OrderMonth, TotalDue DESC;


--2-11.1 Create the table
CREATE TABLE #Numbers(Number INT);

--2-11.2 Populate the tally table
INSERT INTO #Numbers(Number)
SELECT TOP(1000000) ROW_NUMBER() OVER(ORDER BY a.object_id) 
FROM sys.objects a
CROSS JOIN sys.objects b
CROSS JOIN sys.objects c;

--2-12.1 Find the earliest date and the number of days
DECLARE @Min DATE, @DayCount INT;
SELECT @Min = MIN(OrderDate), 
	@DayCount = DATEDIFF(DAY,MIN(OrderDate),MAX(OrderDate))
FROM Sales.SalesOrderHeader;

--2-12.2 Change numbers to dates and then find missing
WITH Dates AS (
	SELECT TOP(@DayCount) DATEADD(DAY,Number,@Min) AS OrderDate
	FROM #Numbers AS N
	ORDER BY Number
)
SELECT Dates.OrderDate
FROM Dates
LEFT JOIN Sales.SalesOrderHeader AS SOH
	ON Dates.OrderDate = SOH.OrderDate
WHERE SOH.SalesOrderID IS NULL;

--2-13.1 Using NTILE to assign bonuses
WITH Sales AS (
    SELECT SP.FirstName, SP.LastName,
        SUM(SOH.TotalDue) AS TotalSales
    FROM [Sales].[vSalesPerson] SP 
    JOIN Sales.SalesOrderHeader SOH
            ON SP.BusinessEntityID = SOH.SalesPersonID 
    WHERE SOH.OrderDate >= '2011-01-01' AND SOH.OrderDate < '2012-01-01'
    GROUP BY FirstName, LastName)
SELECT FirstName, LastName, TotalSales, 
    NTILE(4) OVER(ORDER BY TotalSales) * 1000 AS Bonus
FROM Sales;


--2-14.1 Assign bonuses in opposite order
WITH Sales AS (
    SELECT SP.FirstName, SP.LastName,
        SUM(SOH.TotalDue) AS TotalSales
    FROM [Sales].[vSalesPerson] SP 
    JOIN Sales.SalesOrderHeader SOH
            ON SP.BusinessEntityID = SOH.SalesPersonID 
    WHERE SOH.OrderDate >= '2011-01-01' AND SOH.OrderDate < '2012-01-01'
    GROUP BY FirstName, LastName)
SELECT FirstName, LastName, TotalSales, 
    -1000 * NTILE(4) OVER(ORDER BY TotalSales DESC) + 5000 AS Bonus
FROM Sales;








