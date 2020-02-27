--3.1.1 Window aggregate examples
SELECT CustomerID, SalesOrderID,
    CAST(MIN(OrderDate) OVER() AS DATE) AS FirstOrderDate, 
    CAST(MAX(OrderDate) OVER() AS DATE) AS LastOrderDate,
    COUNT(*) OVER() OrderCount, 
    FORMAT(SUM(TotalDue) OVER(),'C') TotalAmount
FROM Sales.SalesOrderHeader
ORDER BY CustomerID, SalesOrderID;

--3.1.2 Use PARTITION BY
SELECT CustomerID, SalesOrderID,
    CAST(MIN(OrderDate) OVER(PARTITION BY CustomerID) AS DATE) 
        AS FirstOrderDate, 
    CAST(MAX(OrderDate) OVER(PARTITION BY CustomerID) AS DATE)
        AS LastOrderDate,
    COUNT(*) OVER(PARTITION BY CustomerID) OrderCount, 
    FORMAT(SUM(TotalDue) OVER(PARTITION BY CustomerID),'C') AS TotalAmount
FROM Sales.SalesOrderHeader
ORDER BY CustomerID, SalesOrderID;

--3.2.1 Use different OVER clauses
SELECT CustomerID, SalesOrderID, FORMAT(TotalDue,'c') AS TotalDue,
    FORMAT(SUM(TotalDue) OVER(PARTITION BY CustomerID),'c') AS CustomerSales,
    FORMAT(SUM(TotalDue) OVER(),'c') AS TotalSales
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01'
ORDER BY CustomerID, SalesOrderID;


--3-3-1 Using window functions in expressions
SELECT CustomerID, SalesOrderID, 
   CAST(OrderDate AS Date) AS OrderDate,
   MIN(SalesOrderID/CustomerID) 
      OVER(PARTITION BY CustomerID) AS Expr1,
   CAST(MIN(DATEADD(d,1,OrderDate)) OVER() AS DATE) AS Expr2,
   AVG((SELECT COUNT(*) 
        FROM Sales.SalesOrderDetail AS SOD 
        WHERE SalesOrderID = SOH.SalesOrderID)) OVER() AS Expr3
FROM Sales.SalesOrderHeader AS SOH; 


--3-4.1 Add a window aggregate to an aggregate query
SELECT CustomerID, SUM(TotalDue) AS CustomerTotal,
    SUM(TotalDue) OVER() AS GrandTotal
FROM Sales.SalesOrderHeader
GROUP BY CustomerID;


--3-5.1 How to add a window aggregate to an aggregate query
SELECT CustomerID, SUM(TotalDue) AS CustomerTotal,
    SUM(SUM(TotalDue)) OVER() AS GrandTotal
FROM Sales.SalesOrderHeader
GROUP BY CustomerID;


--3.6.1 Using a CTE
WITH SALES AS (
   SELECT CustomerID, SUM(TotalDue) AS CustomerTotal
   FROM Sales.SalesOrderHeader
   GROUP BY CustomerID)
SELECT CustomerID, CustomerTotal, 
   SUM(CustomerTotal) OVER() AS GrandTotal
FROM Sales;

--3-7.1 Window aggregate to multiple group by
SELECT YEAR(OrderDate) AS OrderYear,
    CustomerID, SUM(TotalDue) AS CustTotalForYear,	
    SUM(SUM(TotalDue)) OVER(PARTITION BY CustomerID) AS CustomerTotal
FROM Sales.SalesOrderHeader
GROUP BY CustomerID, YEAR(OrderDate)
ORDER BY CustomerID, OrderYear;

--3-8.1 Calculate the percent of sales 
SELECT P.ProductID, 
    FORMAT(SUM(OrderQty * UnitPrice),'C') AS ProductSales,
    FORMAT(SUM(SUM(OrderQty * UnitPrice)) OVER(),'C') AS TotalSales,
    FORMAT(SUM(OrderQty * UnitPrice)/ 
        SUM(SUM(OrderQty * UnitPrice)) OVER(), 'P') AS PercentOfSales
FROM Sales.SalesOrderDetail AS SOD 
JOIN Production.Product AS P ON SOD.ProductID = P.ProductID
JOIN Production.ProductSubcategory AS SUB ON P.ProductSubcategoryID
    = SUB.ProductSubcategoryID
JOIN Production.ProductCategory AS CAT ON SUB.ProductCategoryID
    = CAT.ProductCategoryID
WHERE CAT.Name = 'Bikes'
GROUP BY P.ProductID
ORDER BY PercentOfSales DESC;

--3-9.1 Create the partition function
CREATE PARTITION FUNCTION testFunction (DATE)
AS RANGE RIGHT
FOR VALUES ('2011-01-01','2012-01-01','2013-01-01','2014-01-01');
GO

--3-9.2 Create the partition scheme
CREATE PARTITION SCHEME testScheme
AS PARTITION testFunction ALL TO ('Primary');
GO

--3-9.3 Create a partitioned table
CREATE TABLE dbo.Orders(CustomerID INT, SalesOrderID INT, 
    OrderDate DATE, TotalDue MONEY)
ON testScheme(OrderDate);
GO

--3-9.4 Populate the table
INSERT INTO dbo.Orders(customerID, SalesOrderID, 
    OrderDate, TotalDue) 
SELECT CustomerID, SalesOrderID, 
    OrderDate, TotalDue
FROM Sales.SalesOrderHeader;
GO

--3-9.5 Create another partitioned table
CREATE TABLE dbo.Customer (CustomerID INT, ModifiedDate DATE)
ON testScheme(ModifiedDate);
GO

--3-9.6 Populate the table
INSERT INTO dbo.Customer(CustomerID, ModifiedDate)
SELECT CustomerID, ModifiedDate 
FROM Sales.Customer

--3-10.1 The query from my collegue
SELECT OBJECT_NAME(p.OBJECT_ID) TableName,
    ps.partition_number, ps.Row_count 
FROM sys.data_spaces  d 
JOIN sys.indexes i 
JOIN (SELECT DISTINCT OBJECT_ID
      FROM sys.partitions
      WHERE partition_number > 1) p
ON i.OBJECT_ID = p.OBJECT_ID
ON d.data_space_id = i.data_space_id
JOIN sys.dm_db_partition_stats ps
ON i.OBJECT_ID = ps.OBJECT_ID and i.index_id = ps.index_id
WHERE i.index_id < 2;

--3-10.2 The solution to find the percent of rows by table 
SELECT OBJECT_NAME(p.OBJECT_ID) TableName,
    ps.partition_number, ps.Row_count, 
    --My solution starts here
    FORMAT(ps.row_count * 1.0 /
        SUM(ps.row_count) OVER(PARTITION BY p.OBJECT_ID),'p') 
        As PercentOfRows                    
    --and ends here
FROM sys.data_spaces  d 
JOIN sys.indexes i 
JOIN (SELECT DISTINCT OBJECT_ID
      FROM sys.partitions
      WHERE partition_number > 1) p
ON i.OBJECT_ID = p.OBJECT_ID
ON d.data_space_id = i.data_space_id
JOIN sys.dm_db_partition_stats ps
ON i.OBJECT_ID = ps.OBJECT_ID and i.index_id = ps.index_id
WHERE i.index_id < 2;

--3-11 Drop objects created in this section
DROP TABLE dbo.Customer;
DROP TABLE dbo.Orders; 
DROP PARTITION SCHEME testScheme;
DROP PARTITION FUNCTION testFunction;


--3-12.1 Enable CRL
EXEC sp_configure 'clr_enabled', 1;
GO
RECONFIGURE;
GO
--3-12.2 Enable an unsigned assembly
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'clr strict security',0
GO
RECONFIGURE;
--3-12.3 Register the DLL
CREATE ASSEMBLY CustomAggregate FROM
 'C:\Custom\CustomAggregate.dll' WITH PERMISSION_SET = SAFE;
GO

--3-12.4 Create the function
CREATE Aggregate Median (@Value INT) RETURNS INT
EXTERNAL NAME CustomAggregate.Median;
GO

--3-12.5 Test the function
WITH Orders AS (
    SELECT CustomerID, SUM(OrderQty) AS OrderQty, SOH.SalesOrderID 
    FROM Sales.SalesOrderHeader AS SOH
    JOIN Sales.SalesOrderDetail AS SOD 
        ON SOH.SalesOrderID = SOD.SalesOrderDetailID
    GROUP BY CustomerID, SOH.SalesOrderID)
SELECT CustomerID, OrderQty, dbo.Median(OrderQty) OVER(PARTITION BY CustomerID) AS Median
FROM Orders
WHERE CustomerID IN (13011, 13012, 13019);

--3-13.1 Drop the objects
DROP AGGREGATE Median;
DROP ASSEMBLY CustomAggregate;
GO

--3-13.2 Reset CLR integration to the defaults
EXEC sp_configure 'clr_enabled', 0;
GO
RECONFIGURE;
EXEC sp_configure 'clr strict security',1;
GO




