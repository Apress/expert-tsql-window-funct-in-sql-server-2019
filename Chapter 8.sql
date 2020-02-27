--8-1.1 A simple query
SELECT * 
FROM HumanResources.Employee;

--8-2.1 Query to produce Sequence Project (Compute Scalar) operator
SELECT CustomerID, ROW_NUMBER() OVER(ORDER BY SalesOrderID) AS RowNumber
FROM Sales.SalesOrderHeader;

--8-3.1 Add PARTITION BY
SELECT CustomerID, 
   ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY SalesOrderID) AS RowNumber
FROM Sales.SalesOrderHeader;

--8-4.1 A query to show the Sort operator
SELECT CustomerID, SalesOrderID, 
    ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY OrderDate) AS RowNumber
FROM Sales.SalesOrderHeader;

--8-5.1 A query with a Table Spool operator 
SELECT CustomerID, SalesOrderID, SUM(TotalDue) 
    OVER(PARTITION BY CustomerID) AS SubTotal
FROM Sales.SalesOrderHeader;

--8-6.1 A query isth a window spool operator
SELECT CustomerID, SalesOrderID, TotalDue, 
    SUM(TotalDue) OVER(PARTITION BY CustomerID ORDER BY SalesOrderID) AS RunningTotal
FROM Sales.SalesOrderHeader;

--8-7.0 Settings
USE [master];
GO
--Change database name as needed
ALTER DATABASE [AdventureWorks2017] 
SET COMPATIBILITY_LEVEL = 120;
GO
USE [AdventureWorks2017];
SET STATISTICS IO ON;
SET NOCOUNT ON;
GO

--8-7.1 Query to produce Sequence Project
PRINT '8-7.1';
SELECT CustomerID, ROW_NUMBER() OVER(ORDER BY SalesOrderID) AS RowNumber
FROM Sales.SalesOrderHeader;

--8-7.2 A query to show the Sort operator
PRINT '8-7.2';
SELECT CustomerID, SalesOrderID, 
    ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY OrderDate) AS RowNumber
FROM Sales.SalesOrderHeader;

--8-7.3 A query with a Table Spool operator 
PRINT '8-7.3';
SELECT CustomerID, SalesOrderID, SUM(TotalDue) OVER(PARTITION BY CustomerID) 
    AS SubTotal
FROM Sales.SalesOrderHeader;

--8-8.1 Drop the existing index
DROP INDEX [IX_SalesOrderHeader_CustomerID] ON [Sales].[SalesOrderHeader];
GO

--8-8.2 Create a new index for the query
CREATE NONCLUSTERED INDEX [IX_SalesOrderHeader_CustomerID_OrderDate] 
    ON [Sales].[SalesOrderHeader] ([CustomerID], [OrderDate]);

--8-9.1 query with a join 
SELECT SOH.CustomerID, SOH.SalesOrderID, SOH.OrderDate, C.TerritoryID,
    ROW_NUMBER() OVER(PARTITION BY SOH.CustomerID ORDER BY SOH.OrderDate) 
        AS RowNumber
FROM Sales.SalesOrderHeader AS SOH 
JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID;

--8-9.2 Rearrange the query
WITH Sales AS (
    SELECT CustomerID, OrderDate, SalesOrderID, 
        ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY OrderDate) 
            AS RowNumber
    FROM Sales.SalesOrderHeader)
SELECT Sales.CustomerID, SALES.SalesOrderID, Sales.OrderDate,
    C.TerritoryID, Sales.RowNumber
FROM Sales 
JOIN Sales.Customer AS C ON C.CustomerID = Sales.CustomerID;

--8-10.1 Set the compatibility level
USE master;
GO
ALTER DATABASE AdventureWorks2017
SET COMPATIBILITY_LEVEL = 140 WITH NO_WAIT;
GO
USE AdventureWorks2017;
GO

--8-10.2 Turn on Statistics IO 
SET STATISTICS IO ON;
SET NOCOUNT ON;
GO

--8-10.3 Create a larger table for testing
DROP TABLE IF EXISTS dbo.SOD ;
CREATE TABLE dbo.SOD(SalesOrderID INT, SalesOrderDetailID INT, LineTotal Money);

--8-10.4 Populate the table
INSERT INTO dbo.SOD(SalesOrderID, SalesOrderDetailID, LineTotal)
SELECT SalesOrderID, SalesOrderDetailID, LineTotal 
FROM Sales.SalesOrderDetail
UNION ALL 
SELECT SalesOrderID + MAX(SalesOrderID) OVER(), SalesOrderDetailID, LineTotal 
FROM Sales.SalesOrderDetail;

--8-10.5 Create a nonclustered index
CREATE INDEX SalesOrderID_SOD ON dbo.SOD 
(SalesOrderID, SalesOrderDetailID) INCLUDE(LineTotal);

--8-11.1 A running total
PRINT '8-11.1'
SELECT SalesOrderID, SalesOrderDetailID, LineTotal, 
    SUM(LineTotal) 
    OVER(PARTITION BY SalesOrderID ORDER BY SalesOrderDetailID) RunningTotal
FROM SOD;

--8-11.2 A query with FIRST_VALUE
PRINT '8-11.2'
SELECT SalesOrderID, SalesOrderDetailID, LineTotal, 
    FIRST_VALUE(LineTotal) 
    OVER(PARTITION BY SalesOrderID ORDER BY SalesOrderDetailID) FirstValue
FROM SOD;

PRINT '8-12.1'
SELECT SalesOrderID, SalesOrderDetailID, LineTotal, 
    SUM(LineTotal) 
	OVER(PARTITION BY SalesOrderID ORDER BY SalesOrderDetailID
	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) RunningTotal
FROM SOD;

--8-12.2 A query with FIRST_VALUE using ROWS
PRINT '8-12.2'
SELECT SalesOrderID, SalesOrderDetailID, LineTotal, 
	FIRST_VALUE(LineTotal) 
	OVER(PARTITION BY SalesOrderID ORDER BY SalesOrderDetailID
	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) RunningTotal
FROM SOD;

--8-13.1 Set the compatibility level
USE master;
GO
ALTER DATABASE AdventureWorks2017
SET COMPATIBILITY_LEVEL = 140 WITH NO_WAIT;
GO
USE AdventureWorks2017;
GO
--8-13.2 A window aggregate
PRINT '8-13.1'
SELECT SalesOrderID, SalesOrderDetailID, LineTotal, 
    SUM(LineTotal) OVER(PARTITION BY SalesOrderID) AS SubTotal	
FROM SOD;

--8-13.2 A statistical function
PRINT '8-11.2'
SELECT SalesOrderID, SalesOrderDetailID, LineTotal, 
	PERCENT_RANK()
	OVER(PARTITION BY SalesOrderID ORDER BY SalesOrderDetailID) AS Ranking	
FROM SOD;

--8-14.1 Set the compatibility level
USE master;
GO
ALTER DATABASE AdventureWorks2017
SET COMPATIBILITY_LEVEL = 150 WITH NO_WAIT;
GO
USE AdventureWorks2017;
GO
--8-14.2 A window aggregate
PRINT '8-14.1'
SELECT SalesOrderID, SalesOrderDetailID, LineTotal, 
    SUM(LineTotal) OVER(PARTITION BY SalesOrderID) AS SubTotal	
FROM SOD;

--8-15.1 Change settings
SET STATISTICS IO OFF;
SET STATISTICS TIME ON;
SET NOCOUNT ON;
GO
--8-15.2 Change compatability
USE MASTER;
GO
ALTER DATABASE AdventureWorks2017
SET COMPATIBILITY_LEVEL = 140 WITH NO_WAIT;
USE AdventureWorks2017;
GO
--8-15.3
PRINT '
DEFAULT frame'
SELECT SalesOrderID, SalesOrderDetailID, LineTotal, 
    SUM(LineTotal) OVER(PARTITION BY SalesOrderID
	ORDER BY SalesOrderDetailID) AS RunningTotal	
FROM SOD;

--8-15.4
PRINT '
ROWS'
SELECT SalesOrderID, SalesOrderDetailID, LineTotal, 
    SUM(LineTotal) OVER(PARTITION BY SalesOrderID
	ORDER BY SalesOrderDetailID 
	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS SubTotal	
FROM SOD;

--8-16.1
PRINT '
DEFAULT frame'
SELECT SalesOrderID, SalesOrderDetailID, LineTotal, 
    SUM(LineTotal) OVER(PARTITION BY SalesOrderID
	ORDER BY SalesOrderDetailID) AS RunningTotal
INTO #temp1
FROM SOD;

--8-16.2
PRINT '
ROWS'
SELECT SalesOrderID, SalesOrderDetailID, LineTotal, 
    SUM(LineTotal) OVER(PARTITION BY SalesOrderID
	ORDER BY SalesOrderDetailID 
	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS SubTotal	
INTO #Temp2
FROM SOD;

DROP TABLE #Temp1;
DROP TABLE #temp2;

--8-17.1 Drop index 
DROP INDEX [IX_SalesOrderHeader_CustomerID_OrderDate]
    ON Sales.SalesOrderHeader;
GO

--8-17-2 Recreate original index
CREATE INDEX [IX_SalesOrderHeader_CustomerID] ON Sales.SalesOrderHeader
    (CustomerID);

--8-17-3 Drop special table
DROP TABLE IF EXISTS dbo.SOD;
--8-17-4 Drop Thinking Big Adventure tables
DROP TABLE IF EXISTS dbo.bigTransactionHistory;
DROP TABLE IF EXISTS dbo.bigProduct;















