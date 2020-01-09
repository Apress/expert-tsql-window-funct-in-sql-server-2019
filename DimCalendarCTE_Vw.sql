CREATE VIEW [dbo].[DimCalendarCTE_Vw]
AS
	WITH DimDateCTE
	AS (SELECT CAST('2010-01-01' AS DATETIME) AS [AnchorDate]
		UNION ALL
		SELECT [AnchorDate] + 1
		FROM [DimDateCTE]
		WHERE [AnchorDate] + 1 < DATEADD(s, -1, DATEADD(YYYY, DATEDIFF(YYYY, 0, GETDATE()) + 2, 0)) -- end date to end recursion (two years out)
	   )
	SELECT CAST(CONVERT(VARCHAR, [AnchorDate], 112) AS INT) AS [DateKey]
		, CAST([AnchorDate] AS DATE) AS [FullDateAlternateKey]
		, [AnchorDate] AS [DateTime]
		, DATEDIFF([wk], CAST(CAST(DATEPART([mm], [AnchorDate]) AS NVARCHAR(2))
							+ '/01/'
							+ CAST(DATEPART([yyyy], [AnchorDate]) AS NVARCHAR(4)) AS SMALLDATETIME), [AnchorDate])
							+ 1 AS [WeekOfMonth]
		, CONVERT(VARCHAR, [AnchorDate], 110) AS [TextDate] --use style 101 for '/' separator
		-- many other variations possible by casting to/from a string. the two above are the simplest forms
		, YEAR([AnchorDate]) AS [Year Nbr]
		, DATEPART(quarter, [AnchorDate]) AS [Qtr Nbr]
		, MONTH([AnchorDate]) AS [Month Nbr]
		, DATEPART([dayofyear], [AnchorDate]) AS [DOY Nbr]
		, DAY([AnchorDate]) AS [DOM Nbr]
		--,datepart(day, AnchorDate) as [DOM Nbr]
		, DATEPART([weekday], [AnchorDate]) AS [DOW Nbr]
		, DATEPART(week, [AnchorDate]) AS [WOY nbr]
		--returns nvarchar values
		, datename(Year, [AnchorDate]) AS [Year]
		, datename(quarter, [AnchorDate]) AS [Quarter]
		, datename(month, [AnchorDate]) AS [Month Name]
		, LEFT(datename(month, [AnchorDate]), 3) AS [Month Abbr]
		, datename(year, [AnchorDate]) + ' ' + LEFT(datename(month, [AnchorDate]), 3) AS [Year Month]
		, datename([dayofyear], [AnchorDate]) AS [DOY]
		, datename(day, [AnchorDate]) AS [DOM]
		, datename(week, [AnchorDate]) AS [WOY]
		, datename([weekday], [AnchorDate]) AS [DOW Name]
		, DATEADD([s], -1, DATEADD([YYYY], DATEDIFF([YYYY], 0, [AnchorDate]) + 1, 0)) AS [LastDOY]
		, DATEADD([s], -1, DATEADD([mm], DATEDIFF([m], 0, [AnchorDate]), 0)) AS [LastDay_PreviousMonth]
		, DATEADD([s], 0, DATEADD([mm], DATEDIFF([m], 0, [AnchorDate]), 0)) AS [FirstDOM]
		, DATEADD([s], -1, DATEADD([mm], DATEDIFF([m], 0, [AnchorDate]) + 1, 0)) AS [LastDOM]
		, DATEADD([wk], -52, [AnchorDate]) AS [SameBusinessDayLY]
		, CAST(DATEADD([s], -0.1, DATEADD([YYYY], DATEDIFF([YYYY], 0, [AnchorDate]) - 2, 0)) AS DATE) AS [First DOY Three Years Ago]
		-- compound values needed in time dimensions
		, CAST(datename(year, [AnchorDate])
				+ RIGHT('00' + CAST(MONTH([AnchorDate]) AS NVARCHAR), 2)
				+ RIGHT('00' + CAST(DAY([AnchorDate]) AS NVARCHAR), 2) AS INT) AS [Date_key]
		, CAST(datename(year, [AnchorDate])
				+ RIGHT('00' + CAST(MONTH([AnchorDate]) AS NVARCHAR), 2) AS INT) AS [Month_key]
		, CAST(datename(year, [AnchorDate])
				+ RIGHT('00' + CAST(DATEPART(week, [AnchorDate]) AS NVARCHAR), 2) AS INT) AS [week_key]
		, CAST(datename(year, [AnchorDate])
				+ datename(quarter, [AnchorDate]) AS INT) AS [Quarter_key]
		--logical flags
		, CASE
			WHEN DAY([AnchorDate]) = 1
			THEN 'Y'
			ELSE 'N'
		END AS [First_DOM_YN]
		, CASE
			WHEN DAY(DATEADD(day, 1, [AnchorDate])) = 1
			THEN 'Y'
			ELSE 'N'
		END AS [Last_DOM_YN]
		, CASE
			WHEN DATEPART([weekday], [AnchorDate]) BETWEEN 2 AND 6
			THEN 'Y'
			ELSE 'N'
		END AS [Weekday_YN]
	FROM [DimDateCTE] 
GO
SELECT * 
FROM [dbo].[DimCalendarCTE_Vw]
OPTION(MAXRECURSION 0); 
