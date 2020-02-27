Use Master; 
GO
go
CREATE DATABASE StockAnalysisDemo;
GO
USE StockAnalysisDemo;
GO

CREATE TABLE Stocks(TickerSymbol VARCHAR(4));

INSERT INTO Stocks (TickerSymbol)
SELECT TOP(999) 'Z' + CAST(ROW_NUMBER() OVER(ORDER BY A.name) AS VARCHAR) 
FROM sys.objects AS A 
CROSS JOIN sys.objects AS B;

CREATE TABLE Dates(TradeDate DATE);

WITH 
AllDates AS (
	SELECT TOP(1000) DATEADD(d,ROW_NUMBER() OVER(ORDER BY A.name),'2017-01-01') AS TradeDate 
	FROM sys.objects AS A 
	CROSS JOIN sys.objects AS B),
 FilterOutWeekends AS (
	SELECT TradeDate
	FROM AllDates 
	WHERE DATENAME( WEEKDAY,TradeDate) NOT IN ('Saturday','Sunday')
	),
FilterOutHolidays AS (
	SELECT TradeDate 
	FROM FilterOutWeekends 
	WHERE FORMAT(TradeDate,'mm/dd') NOT IN('01/01','12/25','07/04')
		AND TradeDate NOT IN (
			'2017-01-02','2017-01-16','2017-02-20','2017-04-14','2017-05-29','2017-09-04','2017-11-23',
			'2018-01-15','2018-02-19','2018-03-30','2018-05-28','2018-09-03','2018-11-22',
			'2019-01-21','2019-02-18','2019-04-19','2019-05-27','2019-09-02','2019-11-28')
	)
INSERT INTO Dates( TradeDate )
SELECT TradeDate 
FROM FilterOutHolidays;
	

CREATE TABLE StockHistory(TickerSymbol VARCHAR(4), TradeDate DATE, 
	ClosePrice DECIMAL(5,2), OpenPrice DECIMAL(5,2));

WITH StockSeed AS (
	SELECT TickerSymbol, '2017-01-03' AS StartDate, 
		CAST(RAND(CAST(NEWID() AS VARBINARY)) * 100 AS DECIMAL(5,2)) AS ClosePrice
	FROM Stocks)
INSERT INTO StockHistory
        ( TickerSymbol ,
          TradeDate ,
          ClosePrice,
		  OpenPrice
        )
SELECT TickerSymbol, StartDate, ClosePrice, ClosePrice -1
FROM StockSeed;

DECLARE @CurrentDate AS DATE 
DECLARE @PrevDate AS DATE 
DECLARE DATES CURSOR FAST_FORWARD FOR SELECT TradeDate FROM Dates ORDER BY TradeDate;
OPEN DATES;
FETCH NEXT FROM DATES INTO @PrevDate;
FETCH NEXT FROM DATES INTO @CurrentDate
WHILE @@FETCH_STATUS = 0 BEGIN 
	WITH OrigStocks AS (
		SELECT TickerSymbol,  
		ClosePrice + CASE WHEN CAST(RAND(CAST(NEWID() AS VARBINARY)) * 10 AS TINYINT)%2 = 0 THEN -1 ELSE 1 END *   CAST(RAND(CAST(NEWID() AS VARBINARY)) AS DECIMAL(5,2)) AS ClosePrice
	FROM StockHistory 
	WHERE TradeDate = @PrevDate)
	INSERT INTO StockHistory
	        ( TickerSymbol ,
	          TradeDate ,
	          ClosePrice,
			  OpenPrice
	        )
	SELECT TickerSymbol, @CurrentDate, 
		ClosePrice, ClosePrice + .5
	FROM OrigStocks;
	

	SET @PrevDate = @CurrentDate;
	FETCH NEXT FROM DATES INTO @CurrentDate;
END;
CLOSE DATES;
DEALLOCATE dates; 




