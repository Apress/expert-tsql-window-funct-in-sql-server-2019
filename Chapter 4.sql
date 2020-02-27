--4-1.1 A running total
SELECT CustomerID, SalesOrderID, CAST(OrderDate AS DATE) AS OrderDate, 
    TotalDue, SUM(TotalDue) OVER(PARTITION BY CustomerID 
        ORDER BY SalesOrderID) AS RunningTotal
FROM Sales.SalesOrderHeader;

--4-2.1 Three month sum and average for products qty sold 
SELECT MONTH(SOH.OrderDate) AS OrderMonth, SOD.ProductID, SUM(SOD.OrderQty) AS QtySold,
    SUM(SUM(SOD.OrderQty)) 
    OVER(PARTITION BY SOD.ProductID ORDER BY MONTH(SOH.OrderDate)
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthSum,
    AVG(SUM(SOD.OrderQty)) 
    OVER(PARTITION BY SOD.ProductID ORDER BY MONTH(SOH.OrderDate)
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthAvg
FROM Sales.SalesOrderHeader AS SOH 
JOIN Sales.SalesOrderDetail AS SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN Production.Product AS P ON SOD.ProductID = P.ProductID
WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01'
GROUP BY MONTH(SOH.OrderDate), SOD.ProductID;

--4-3.1 Display NULL when less than 
SELECT MONTH(SOH.OrderDate) AS OrderMonth, SOD.ProductID, 
    SUM(SOD.OrderQty) AS QtySold,
    CASE WHEN ROW_NUMBER() OVER(PARTITION BY SOD.ProductID 
         ORDER BY MONTH(SOH.OrderDate)) < 3 THEN NULL 
    ELSE  SUM(SUM(SOD.OrderQty)) OVER(PARTITION BY SOD.ProductID 
         ORDER BY MONTH(SOH.OrderDate)
         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) END AS ThreeMonthSum,
    CASE WHEN ROW_NUMBER() OVER(PARTITION BY SOD.ProductID 
         ORDER BY MONTH(SOH.OrderDate)) < 3 THEN NULL 
     ELSE AVG(SUM(SOD.OrderQty)) 
         OVER(PARTITION BY SOD.ProductID ORDER BY MONTH(SOH.OrderDate)
         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) END AS ThreeMonthAvg	
FROM Sales.SalesOrderHeader AS SOH 
JOIN Sales.SalesOrderDetail AS SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN Production.Product AS P ON SOD.ProductID = P.ProductID
WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01'
GROUP BY MONTH(SOH.OrderDate), SOD.ProductID;

--4-4.1 Create the table
CREATE TABLE #TheTable(ID INT, Data INT);

--4-4.2 Populate the table
INSERT INTO #TheTable(ID, Data)
VALUES(1,1),(2,1),(3,NULL), 
    (4,NULL),(5,6),(6,NULL),
    (7,5),(8,10),(9,11),
	(10,NULL),(11,NULL);
--4-4.3 Display the results
SELECT * FROM #TheTable;

--4-5.1 Find the max non-null row
SELECT ID, Data,
    MAX(CASE WHEN Data IS NOT NULL THEN ID END)
    OVER(ORDER BY ID) AS MaxRowID
FROM #TheTable;

--4-6.1 The solution
WITH MaxData AS
    (SELECT ID, Data,
        MAX(CASE WHEN Data IS NOT NULL THEN ID END)
        OVER(ORDER BY ID) AS MaxRowID
    FROM #TheTable)
SELECT ID, Data,
    MAX(Data) OVER(PARTITION BY MaxRowID) AS NewData
FROM MaxData;

--4-7.1 Create the temp table
CREATE TABLE #Registrations(ID INT NOT NULL IDENTITY PRIMARY KEY, 
	DateJoined DATE NOT NULL, DateLeft DATE NULL);
--4-7.2 Variables
DECLARE @Rows INT = 10000, @Years INT = 5, @StartDate DATE = '2019-01-01'

--4-7.3 Insert 10,000 rows with five years of possible dates
INSERT INTO #Registrations (DateJoined) 
SELECT TOP(@Rows) DATEADD(DAY,CAST(RAND(CHECKSUM(NEWID())) * @Years * 365  as INT) ,@StartDate)
FROM sys.objects a
CROSS JOIN sys.objects b
CROSS JOIN sys.objects c;

--4-7.4 Give cancellation dates to 75% of the subscribers
UPDATE TOP(75) PERCENT #Registrations 
SET DateLeft = DATEADD(DAY,CAST(RAND(CHECKSUM(NEWID())) * @Years * 365  as INT),DateJoined)

--4-7.5 The subscription data
SELECT * 
FROM #Registrations
ORDER BY DateJoined;

--4-8.1 Solve the subscription problem
WITH NewSubs AS (
    SELECT EOMONTH(DateJoined) AS TheMonth,
        COUNT(DateJoined) AS PeopleJoined
    FROM #Registrations
    GROUP BY EOMONTH(DateJoined)),
 Cancelled AS (
    SELECT EOMONTH(DateLeft) AS TheMonth,
        COUNT(DateLeft) AS PeopleLeft
    FROM #Registrations 
    GROUP BY EOMONTH(DateLeft))
SELECT NewSubs.TheMonth AS TheMonth, NewSubs.PeopleJoined,
    Cancelled.PeopleLeft, 
    SUM(NewSubs.PeopleJoined - ISNULL(Cancelled.PeopleLeft,0)) 
    OVER(ORDER BY NewSubs.TheMonth) AS Subscriptions
FROM NewSubs
LEFT JOIN Cancelled ON NewSubs.TheMonth = Cancelled.TheMonth;



