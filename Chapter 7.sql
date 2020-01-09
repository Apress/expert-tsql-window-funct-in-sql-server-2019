--7-1.1 Using PERCENT_RANK and CUME_DIST
SELECT COUNT(*) NumberOfOrders, Month(OrderDate) AS OrderMonth,
    RANK() OVER(ORDER BY COUNT(*)) AS Ranking,
    PERCENT_RANK() OVER(ORDER BY COUNT(*)) AS PercentRank,
    CUME_DIST() OVER(ORDER BY COUNT(*)) AS CumeDist
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01'
GROUP BY  Month(OrderDate);

--7-2.1 Create the table
CREATE TABLE #MonthlyTempsStl(MNo Int, MName varchar(15), AvgHighTempF INT, AvgHighTempC DECIMAL(4,2));

--7-2.2 Insert the rows with F temps
INSERT INTO #MonthlyTempsStl (Mno, Mname, AvgHighTempF)
VALUES(1,'Jan',40),(2,'Feb',45),(3,'Mar',55),(4,'Apr',67),(5,'May',77),(6,'Jun',85),
	(7,'Jul',89),(8,'Aug',88),(9,'Sep',81),(10,'Oct',69),(11,'Nov',56),(12,'Dec',43);

--7-2.3 Calculate C
UPDATE #MonthlyTempsStl 
SET AvgHighTempC = (AvgHighTempF - 32) * 5.0/9;

--7-2.4 Return the results
SELECT * FROM #MonthlyTempsStl;

 --7-3.1 Ranking the temps
SELECT MName, AvgHighTempF, AvgHighTempC, 
	PERCENT_RANK() OVER(ORDER BY AvgHighTempF) * 100.0 AS PR,
	CUME_DIST() OVER(ORDER BY AvgHighTempF) * 100.0 AS CD
FROM #MonthlyTempsStl;

--7-4.1 Find median for the set
SELECT COUNT(*) NumberOfOrders, Month(OrderDate) AS orderMonth,
    PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY COUNT(*)) 
    OVER() AS TheMedian,
    PERCENTILE_DISC(.5) WITHIN GROUP (ORDER BY COUNT(*)) 
    OVER() AS PercentileDisc
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01' 
GROUP BY Month(OrderDate); 

--7-4.2 Return just the answer
SELECT  DISTINCT PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY COUNT(*)) 
    OVER() AS TheMedian,
    PERCENTILE_DISC(.5) WITHIN GROUP (ORDER BY COUNT(*)) 
    OVER() AS PercentileDisc
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01' 
GROUP BY Month(OrderDate);

--7-5.1 Filter out January
SELECT  DISTINCT PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY COUNT(*)) 
    OVER() AS TheMedian,
    PERCENTILE_DISC(.5) WITHIN GROUP (ORDER BY COUNT(*)) 
    OVER() AS PercentileDisc
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-02-01' AND OrderDate < '2014-01-01' 
GROUP BY Month(OrderDate);

--7-6.1 Set up table
CREATE TABLE #scores(StudentID INT IDENTITY, Score DECIMAL(5,2));

--7-6.2 Insert scores with Itzik style numbers table
WITH lv0 AS (SELECT 0 g UNION ALL SELECT 0)
     ,lv1 AS (SELECT 0 g FROM lv0 a CROSS JOIN lv0 b) 
     ,lv2 AS (SELECT 0 g FROM lv1 a CROSS JOIN lv1 b) 
     ,lv3 AS (SELECT 0 g FROM lv2 a CROSS JOIN lv2 b) 
     ,lv4 AS (SELECT 0 g FROM lv3 a CROSS JOIN lv3 b) 
     ,Tally (n) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) 
                   FROM lv4)
INSERT INTO #scores(Score)
SELECT TOP(1000) CAST(RAND(CHECKSUM(NEWID())) * 100 as DECIMAL(5,2)) AS Score
FROM Tally;

--7-6.3 Return the score at the top 25%
SELECT DISTINCT PERCENTILE_DISC(.25) WITHIN GROUP 
     (ORDER BY Score DESC) OVER() AS Top25
FROM #scores;

--7-7.1 Using 2005 functionality
SELECT COUNT(*) NumberOfOrders, Month(OrderDate) AS OrderMonth,
    ((RANK() OVER(ORDER BY COUNT(*)) -1) * 1.0)/(COUNT(*) OVER() -1) 
    AS PercentRank,
    (RANK() OVER(ORDER BY COUNT(*)) * 1.0)/COUNT(*) OVER() 
    AS CumeDist
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01' 
GROUP BY  Month(OrderDate);

--7-8.1 PERCENTILE_DISC
SELECT DISTINCT PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY COUNT(*)) OVER() AS PercentileDisc
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01' 
GROUP BY  Month(OrderDate);

--7-8.2 Old method
WITH Level1 AS (
    SELECT COUNT(*) NumberOfOrders,
        ((RANK() OVER(ORDER BY COUNT(*)) -1) * 1.0)/(COUNT(*) OVER() -1) 
        AS PercentRank
    FROM Sales.SalesOrderHeader
    WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01' 
    GROUP BY  Month(OrderDate))
SELECT TOP(1) NumberOfOrders AS PercentileDisc
FROM Level1 
WHERE Level1.PercentRank <= 0.75
ORDER BY Level1.PercentRank DESC;

--7-7.1 PERCENTILE_CONT
SELECT DISTINCT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY COUNT(*)) OVER() AS PercentCont
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01' 
GROUP BY  Month(OrderDate);

--7-9.2 Using 2005 functionality
WITH Level1 AS (
	SELECT ROW_NUMBER() OVER(ORDER BY COUNT(*)) AS RowNum, 
		COUNT(*) AS NumberOfOrders, 
		(COUNT(*) OVER() -1) * .75 + 1 AS TheRow 
	FROM Sales.SalesOrderHeader
	WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01'
	GROUP BY Month(OrderDate)), 
Level2 AS (
	SELECT RowNum, NumberOfOrders,
		FLOOR(TheRow) AS TheBottomRow,
		CEILING(TheRow) AS TheTopRow, 
		TheRow
	FROM Level1 ), 
Level3 AS (
	SELECT SUM(CASE WHEN RowNum = TheBottomRow THEN NumberOfOrders END) AS BottomValue,
		SUM(CASE WHEN RowNum = TheTopRow THEN NumberOfOrders END) AS TopValue, 
		MAX(TheRow % Level2.TheBottomRow) AS Diff
	FROM Level2)
SELECT  Level3.BottomValue + 
	(Level3.TopValue - Level3.BottomValue) * Diff
FROM Level3;