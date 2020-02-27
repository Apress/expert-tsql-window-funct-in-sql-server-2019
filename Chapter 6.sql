--6-1.1 Use LAG and LEAD
SELECT CustomerID, SalesOrderID, CAST(OrderDate AS DATE) AS OrderDate, 
    LAG(CAST(OrderDate AS DATE)) OVER(PARTITION BY CustomerID 
        ORDER BY SalesOrderID) AS PrevOrderDate,
    LEAD(CAST(OrderDate AS DATE)) OVER(PARTITION BY CustomerID 
        ORDER BY SalesOrderID) AS NextOrderDate
FROM Sales.SalesOrderHeader;

--6-1.2 Use LAG and LEAD as an argument
SELECT CustomerID, SalesOrderID, CAST(OrderDate AS DATE) AS OrderDate, 
    DATEDIFF(DAY,LAG(OrderDate) 
        OVER(PARTITION BY CustomerID ORDER BY SalesOrderID), OrderDate)
        AS DaysSincePrevOrder,
    DATEDIFF(DAY, OrderDate, LEAD(OrderDate) 
        OVER(PARTITION BY CustomerID ORDER BY SalesOrderID))
        AS DaysUntilNextOrder
FROM Sales.SalesOrderHeader;

--6-2.1 Using Offset with LAG
WITH Totals AS (
    SELECT YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate)/4 + 1 AS OrderQtr,
        SUM(TotalDue) AS TotalSales
	FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)/4 + 1)    
SELECT OrderYear, Totals.OrderQtr, TotalSales, 
    LAG(TotalSales, 4) OVER(ORDER BY OrderYear, OrderQtr) 
        AS PreviousYearsSales
FROM Totals
ORDER BY OrderYear, OrderQtr;

Listing 6-3. Using the Default Parameter with LAG
--6-3.1 Using Offset with LAG
WITH Totals AS (
    SELECT YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate)/4 + 1 AS OrderQtr,
        SUM(TotalDue) AS TotalSales
	FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)/4 + 1)    
SELECT OrderYear, Totals.OrderQtr, TotalSales, 
    LAG(TotalSales, 4, 0) OVER(ORDER BY OrderYear, OrderQtr) 
        AS PreviousYearsSales
FROM Totals
ORDER BY OrderYear, OrderQtr;

--6-4.1 Using FIRST_VALUE and LAST_VALUE
SELECT CustomerID, SalesOrderID, TotalDue, 
    FIRST_VALUE(TotalDue) OVER(PARTITION BY CustomerID 
        ORDER BY SalesOrderID) AS FirstOrderAmt,
    LAST_VALUE(TotalDue) OVER(PARTITION BY CustomerID 
        ORDER BY SalesOrderID) AS LastOrderAmt_WRONG,
    LAST_VALUE(TotalDue) OVER(PARTITION BY CustomerID 
        ORDER BY SalesOrderID 
        ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS LastOrderAmt
FROM Sales.SalesOrderHeader
ORDER BY CustomerID, SalesOrderID;

--6-5.1 Calculate Year-Over-Year Growth
WITH 
Level1 AS (
    SELECT YEAR(OrderDate) AS SalesYear, 
        MONTH(OrderDate) AS SalesMonth,
        SUM(TotalDue) AS TotalSales
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
    ),
Level2 AS (
    SELECT SalesYear, SalesMonth,TotalSales, 
        LAG(TotalSales,12) OVER(ORDER BY SalesYear) AS PrevYearSales
    FROM Level1)
SELECT SalesYear, SalesMonth,FORMAT(TotalSales,'C') AS TotalSales, 
    FORMAT(PrevYearSales,'C') AS PrevYearSales, 
    FORMAT((TotalSales-PrevYearSales)/PrevYearSales,'P') AS YOY_Growth
FROM Level2
WHERE PrevYearSales IS NOT NULL;

--6-6.1 Create the table
DROP TABLE IF EXISTS #TimeCards;
CREATE TABLE #TimeCards(
    TimeStampID INT NOT NULL IDENTITY PRIMARY KEY,
    EmployeeID INT NOT NULL,
    ClockDateTime DATETIME2(0) NOT NULL,
    EventType VARCHAR(5) NOT NULL);

--6-6.2 Populate the table
INSERT INTO #TimeCards(EmployeeID, 
    ClockDateTime, EventType)
VALUES
    (1,'2019-01-02 08:00','ENTER'),
    (2,'2019-01-02 08:03','ENTER'),
    (2,'2019-01-02 12:00','EXIT'),
    (2,'2019-01-02 12:34','Enter'),
    (3,'2019-01-02 16:30','ENTER'),
    (2,'2019-01-02 16:00','EXIT'),
    (1,'2019-01-02 16:07','EXIT'),
    (3,'2019-01-03 01:00','EXIT'),
    (2,'2019-01-03 08:10','ENTER'),
    (1,'2019-01-03 08:15','ENTER'),
    (2,'2019-01-03 12:17','EXIT'),
    (3,'2019-01-03 16:00','ENTER'),
    (1,'2019-01-03 15:59','EXIT'),
    (3,'2019-01-04 01:00','EXIT');

--6-6.2 Display the rows
SELECT TimeStampID, EmployeeID, ClockDateTime, EventType
FROM #TimeCards;

WITH Level1 AS (
    SELECT EmployeeID, EventType, ClockDateTime, 
        LEAD(ClockDateTime) OVER(PARTITION BY EmployeeID ORDER BY ClockDateTime) 
             AS NextDateTime
    FROM #TimeCards
),
Level2 AS (
    SELECT EmployeeID, CAST(ClockDateTime AS DATE) AS WorkDate, 
        SUM(DATEDIFF(second, ClockDateTime,NextDateTime)) AS Seconds
    FROM Level1
    WHERE EventType = 'Enter'
    GROUP BY EmployeeID, CAST(ClockDateTime AS DATE))
SELECT EmployeeID, WorkDate,  
    TIMEFROMPARTS(Seconds / 3600, Seconds % 3600 / 60, 
        Seconds % 3600 % 60, 0, 0) AS HoursWorked 
FROM Level2 
ORDER BY EmployeeID, WorkDate;



