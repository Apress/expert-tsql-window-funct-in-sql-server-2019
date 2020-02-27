--Be sure to run Adam Machanic's Thinking Big Adventure Script
--http://dataeducation.com/thinking-big-adventure/

USE master; 
GO
ALTER DATABASE AdventureWorks2017
SET COMPATIBILITY_LEVEL = 130 WITH NO_WAIT
GO
USE AdventureWorks2017;
GO

DROP INDEX IF EXISTS Test1 ON dbo.BigTransactionHistory;

CREATE INDEX Test1 ON dbo.BigTransactionHistory
(ProductID, TransactionID) INCLUDE(Quantity);



DROP TABLE IF EXISTS  #test;
create table #test(transactionid int, productid int, quantity int, calc int);

--Run each statement separately to check the run time
--Window aggregate, 2016
INSERT INTO #test
SELECT 
	TransactionID, ProductID, Quantity, 
	SUM(Quantity) OVER(PARTITION BY ProductID) AS SubTotal
FROM dbo.bigTransactionHistory;

TRUNCATE TABLE #test;

--CTE, 2016
WITH summary as (
	SELECT ProductID, Sum(Quantity) AS SubTotal 
	FROM bigTransactionHistory
	GROUP BY ProductID)
INSERT INTO #test
SELECT TransactionID, bth.ProductID, Quantity, summary.SubTotal	
FROM bigTransactionHistory as BTH
JOIN Summary on bth.ProductID = summary.ProductID;

TRUNCATE TABLE #test;

--Running total No frame, 2016
INSERT INTO #test
SELECT TransactionID, ProductID, Quantity, 
	SUM(Quantity) OVER(PARTITION BY ProductID ORDER BY TransactionID) AS RunningTotal 
FROM dbo.bigTransactionHistory;

TRUNCATE TABLE #test;

--Rows, 2016
INSERT INTO #test
SELECT TransactionID, ProductID, Quantity, 
	SUM(Quantity) OVER(PARTITION BY ProductID ORDER BY TransactionID
	ROWS UNBOUNDED PRECEDING) AS RunningTotal 
FROM dbo.bigTransactionHistory;


USE master; 
GO
ALTER DATABASE AdventureWorks2017
SET COMPATIBILITY_LEVEL = 150 WITH NO_WAIT
GO
USE AdventureWorks2017;
GO

TRUNCATE TABLE #test;

--Window aggregate, 2019
INSERT INTO #test
SELECT 
	TransactionID, ProductID, Quantity, 
	SUM(Quantity) OVER(PARTITION BY ProductID) AS SubTotal
FROM dbo.bigTransactionHistory;

TRUNCATE TABLE #test;

--CTE 2019
WITH summary as (
	SELECT ProductID, Sum(Quantity) AS SubTotal 
	FROM bigTransactionHistory
	GROUP BY ProductID)
INSERT INTO #test
SELECT TransactionID, bth.ProductID, Quantity, summary.SubTotal	
FROM bigTransactionHistory as BTH
JOIN Summary on bth.ProductID = summary.ProductID;

TRUNCATE TABLE #Test;

--Running total no frame, 2019
INSERT INTO #test
SELECT TransactionID, ProductID, Quantity, 
	SUM(Quantity) OVER(PARTITION BY ProductID ORDER BY TransactionID) AS RunningTotal 
FROM dbo.bigTransactionHistory;

TRUNCATE TABLE #test;

--Rows, 2019
INSERT INTO #test
SELECT TransactionID, ProductID, Quantity, 
	SUM(Quantity) OVER(PARTITION BY ProductID ORDER BY TransactionID
	ROWS UNBOUNDED PRECEDING) AS RunningTotal 
FROM dbo.bigTransactionHistory;

