USE BaseballStats;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- Create and populate a table of integers for testing
CREATE TABLE dbo.integers
	(integer_id INT NOT NULL);

INSERT INTO dbo.integers
	(integer_id)
VALUES
	(1), (2), (3), (4), (5), (6), (7), (8), (9), (12), (13), (14), (15), (17), (19), (20), (21), (22), (23), (24);
-- CTE with ROW_NUMBER that finds islands, but will not work with duplicates.
WITH CTE_ISLANDS AS (
	SELECT
		integer_id,
		integer_id - ROW_NUMBER() OVER (ORDER BY integer_id) AS gap_quantity
	FROM dbo.integers)
SELECT
	MIN(integer_id) AS island_start,
	MAX(integer_id) AS island_end
FROM CTE_ISLANDS
GROUP BY gap_quantity;
-- Add some duplicates to test with
INSERT INTO dbo.integers
	(integer_id)
VALUES
	(2), (12), (12), (24);

-- CTE with ROW_NUMBER that finds islands and handles duplicates gracefully.
WITH CTE_ISLANDS AS (
	SELECT
		integer_id,
		integer_id - DENSE_RANK() OVER (ORDER BY integer_id) AS gap_quantity
	FROM dbo.integers)
SELECT
	MIN(integer_id) AS island_start,
	MAX(integer_id) AS island_end,
	COUNT(*) AS distinct_value_count
FROM CTE_ISLANDS
GROUP BY gap_quantity;
-- Query to find gaps, as well as gap size.
WITH CTE_GAPS AS (
    SELECT 
		integer_id,
		ROW_NUMBER() OVER (ORDER BY integer_id) AS island_quantity
    FROM dbo.integers)
SELECT
	ISLAND_END.integer_id + 1 AS gap_starting_value,
	ISLAND_START.integer_id - 1 AS gap_ending_value,
	ISLAND_START.integer_id - ISLAND_END.integer_id - 1 AS gap_length
FROM CTE_GAPS AS ISLAND_END
INNER JOIN CTE_GAPS AS ISLAND_START
ON ISLAND_START.island_quantity = ISLAND_END.island_quantity + 1
WHERE ISLAND_START.integer_id - ISLAND_END.integer_id > 1;

DROP TABLE dbo.integers;
GO

CREATE TABLE dbo.error_log
(	error_log_id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_error_log PRIMARY KEY CLUSTERED,
	error_time_utc DATETIME NOT NULL,
	error_source VARCHAR(50) NOT NULL,
	severity VARCHAR(10) NOT NULL,
	error_description VARCHAR(100) NOT NULL);
GO

CREATE NONCLUSTERED INDEX ix_error_log_error_time_utc ON dbo.error_log (error_time_utc);
GO

INSERT INTO dbo.error_log (error_time_utc, error_source, severity, error_description)
VALUES
	('2/20/2019 00:00:15', 'print_server_01', 'low', 'device unreachable'),
	('2/21/2019 00:00:13', 'print_server_01', 'low', 'device unreachable'),
	('2/22/2019 00:00:11', 'print_server_01', 'low', 'device unreachable'),
	('2/23/2019 00:00:17', 'print_server_01', 'low', 'device unreachable'),
	('2/24/2019 00:00:12', 'print_server_01', 'low', 'device unreachable'),
	('2/25/2019 00:00:15', 'print_server_01', 'low', 'device unreachable'),
	('2/26/2019 00:00:12', 'print_server_01', 'low', 'device unreachable'),
	('2/22/2019 22:34:01', 'network_switch_05', 'critical', 'device unresponsive'),
	('2/22/2019 22:34:06', 'sql_server_02', 'critical', 'device unreachable'),
	('2/22/2019 22:34:06', 'sql_server_02 sql service', 'critical', 'service down'),
	('2/22/2019 22:34:06', 'sql_server_02 sql server agent service', 'high', 'service down'),
	('2/22/2019 22:34:06', 'app_server_11', 'critical', 'device unreachable'),
	('2/22/2019 22:34:11', 'file_server_03', 'high', 'device unreachable'),
	('2/22/2019 22:34:31', 'app_server_10', 'critical', 'device unreachable'),
	('2/22/2019 22:34:39', 'web_server', 'medium', 'device unreachable'),
	('2/22/2019 22:35:00', 'web_site', 'medium', 'http 404 thrown'),
	('2/05/2019 03:05:00', 'app_git_repo', 'low', 'repo unavailable'),
	('2/12/2019 03:05:00', 'app_git_repo', 'low', 'repo unavailable'),
	('2/19/2019 03:05:00', 'app_git_repo', 'low', 'repo unavailable'),
	('2/26/2019 03:05:00', 'app_git_repo', 'low', 'repo unavailable'),
	('2/26/2019 03:07:15', 'git service error', 'medium', ''),
	('2/26/2019 03:07:15', 'git service error', 'medium', ''),
	('1/31/2019 23:59:50', 'sql_server_01', 'critical', 'corrupt database identified'),
	('1/31/2019 23:59:53', 'sql_server_01', 'critical', 'corrupt database identified'),
	('1/31/2019 23:59:57', 'sql_server_01', 'critical', 'corrupt database identified'),
	('2/1/2019 00:00:00', 'sql_server_01 sql service', 'critical', 'service down'),
	('2/1/2019 00:00:15', 'sql_server_01 sql server agent service', 'critical', 'service down'),
	('2/1/2019 00:15:00', 'etl data load to sql_server_01', 'medium', 'job failed'),
	('2/1/2019 00:30:00', 'etl data load to sql_server_01', 'medium', 'job failed'),
	('2/1/2019 00:45:00', 'etl data load to sql_server_01', 'medium', 'job failed'),
	('2/1/2019 01:00:00', 'etl data load to sql_server_01', 'medium', 'job failed'),
	('2/1/2019 01:15:00', 'etl data load to sql_server_01', 'medium', 'job failed'),
	('2/1/2019 01:30:00', 'etl data load to sql_server_01', 'medium', 'job failed')
GO

-- Look at our error log data:
SELECT
	*
FROM dbo.error_log
ORDER BY error_log.error_time_utc;

-- Find clusters of alerts that are within 5 minutes of each other.
WITH CTE_ERROR_HISTORY AS (
	SELECT
		LAG(error_log.error_time_utc) OVER (ORDER BY error_log.error_time_utc, error_log.error_log_id) AS previous_event_time,
		LEAD(error_log.error_time_utc) OVER (ORDER BY error_log.error_time_utc, error_log.error_log_id) AS next_event_time,
		ROW_NUMBER() OVER (ORDER BY error_log.error_time_utc, error_log.error_log_id) AS island_location,
		error_log.error_time_utc,
		error_log.error_log_id
	FROM dbo.error_log),
CTE_ISLAND_START AS (
	SELECT
		ROW_NUMBER() OVER (ORDER BY CTE_ERROR_HISTORY.error_time_utc, CTE_ERROR_HISTORY.error_log_id) AS island_number,
		CTE_ERROR_HISTORY.error_time_utc AS island_start_time,
		CTE_ERROR_HISTORY.next_event_time,
		CTE_ERROR_HISTORY.island_location AS island_start_location
	FROM CTE_ERROR_HISTORY
	WHERE DATEDIFF(MINUTE, CTE_ERROR_HISTORY.previous_event_time, CTE_ERROR_HISTORY.error_time_utc) > 5 OR CTE_ERROR_HISTORY.previous_event_time IS NULL),
CTE_ISLAND_END AS (
	SELECT
		ROW_NUMBER() OVER (ORDER BY CTE_ERROR_HISTORY.error_time_utc, CTE_ERROR_HISTORY.error_log_id) AS island_number,
		CTE_ERROR_HISTORY.error_time_utc AS island_end_time,
		CTE_ERROR_HISTORY.next_event_time,
		CTE_ERROR_HISTORY.island_location AS island_end_location
	FROM CTE_ERROR_HISTORY
	WHERE DATEDIFF(MINUTE, CTE_ERROR_HISTORY.error_time_utc, CTE_ERROR_HISTORY.next_event_time) > 5 OR CTE_ERROR_HISTORY.next_event_time IS NULL)
SELECT
	CTE_ISLAND_START.island_start_time,
	CTE_ISLAND_END.island_end_time,
	CTE_ISLAND_END.island_end_location - CTE_ISLAND_START.island_start_location + 1 AS count_of_events
FROM CTE_ISLAND_START
INNER JOIN CTE_ISLAND_END
ON CTE_ISLAND_START.island_number = CTE_ISLAND_END.island_number;

DROP TABLE dbo.error_log;
GO

-- Quick view of baseball data, as well as size of these tables
SELECT TOP 10
	*
FROM dbo.GameLog;
GO

SELECT
	COUNT(*),
	MIN(GameDate),
	MAX(GameDate)
FROM dbo.GameLog;
GO

SELECT TOP 10
	*
FROM dbo.GameEvent;
GO

SELECT
	COUNT(*)
FROM dbo.GameEvent;
GO

-- Longest winning streaks by the New York Yankees
WITH GAME_LOG AS (
	SELECT
		CASE WHEN (HomeScore > VisitingScore AND HomeTeamName = 'NYA') OR (VisitingScore > HomeScore AND VisitingTeamName = 'NYA') THEN 'W'
			 WHEN (HomeScore > VisitingScore AND VisitingTeamName = 'NYA') OR (VisitingScore > HomeScore AND HomeTeamName = 'NYA') THEN 'L'
			 WHEN VisitingScore = HomeScore THEN 'T'
		END AS result,
		LAG(CASE WHEN (HomeScore > VisitingScore AND HomeTeamName = 'NYA') OR (VisitingScore > HomeScore AND VisitingTeamName = 'NYA') THEN 'W'
			 WHEN (HomeScore > VisitingScore AND VisitingTeamName = 'NYA') OR (VisitingScore > HomeScore AND HomeTeamName = 'NYA') THEN 'L'
			 WHEN VisitingScore = HomeScore THEN 'T' END) OVER (ORDER BY GameLog.GameDate, GameLog.GameLogId) AS previous_game_result,
		LEAD(CASE WHEN (HomeScore > VisitingScore AND HomeTeamName = 'NYA') OR (VisitingScore > HomeScore AND VisitingTeamName = 'NYA') THEN 'W'
			 WHEN (HomeScore > VisitingScore AND VisitingTeamName = 'NYA') OR (VisitingScore > HomeScore AND HomeTeamName = 'NYA') THEN 'L'
			 WHEN VisitingScore = HomeScore THEN 'T' END) OVER (ORDER BY GameLog.GameDate, GameLog.GameLogId) AS next_game_result,
		ROW_NUMBER() OVER (ORDER BY GameLog.GameDate, GameLog.GameLogId) AS island_location,
		GameLog.GameDate,
		GameLog.GameLogId
	FROM dbo.GameLog
	WHERE GameLog.HomeTeamName = 'NYA' OR GameLog.VisitingTeamName = 'NYA'
	AND GameLog.GameType = 'REG'),
CTE_ISLAND_START AS (
	SELECT
		ROW_NUMBER() OVER (ORDER BY GAME_LOG.GameDate, GAME_LOG.GameLogId) AS island_number,
		GAME_LOG.GameDate AS island_start_time,
		GAME_LOG.island_location AS island_start_location
	FROM GAME_LOG
	WHERE GAME_LOG.result = 'W'
	AND (GAME_LOG.previous_game_result <> 'W' OR GAME_LOG.previous_game_result IS NULL)),
CTE_ISLAND_END AS (
	SELECT
		ROW_NUMBER() OVER (ORDER BY GAME_LOG.GameDate, GAME_LOG.GameLogId) AS island_number,
		GAME_LOG.GameDate AS island_end_time,
		GAME_LOG.island_location AS island_end_location
	FROM GAME_LOG
	WHERE GAME_LOG.result = 'W'
	AND (GAME_LOG.next_game_result <> 'W' OR GAME_LOG.next_game_result IS NULL))
SELECT
	CTE_ISLAND_START.island_start_time,
	CTE_ISLAND_END.island_end_time,
	CTE_ISLAND_END.island_end_location - CTE_ISLAND_START.island_start_location + 1 AS count_of_events,
	DATEDIFF(DAY, CTE_ISLAND_START.island_start_time, CTE_ISLAND_END.island_end_time) + 1 AS length_of_streak_in_days
FROM CTE_ISLAND_START
INNER JOIN CTE_ISLAND_END
ON CTE_ISLAND_START.island_number = CTE_ISLAND_END.island_number
ORDER BY CTE_ISLAND_END.island_end_location - CTE_ISLAND_START.island_start_location DESC;
GO

-- Longest losing streaks by the New York Yankees
WITH GAME_LOG AS (
	SELECT
		CASE WHEN (HomeScore > VisitingScore AND HomeTeamName = 'NYA') OR (VisitingScore > HomeScore AND VisitingTeamName = 'NYA') THEN 'W'
			 WHEN (HomeScore > VisitingScore AND VisitingTeamName = 'NYA') OR (VisitingScore > HomeScore AND HomeTeamName = 'NYA') THEN 'L'
			 WHEN VisitingScore = HomeScore THEN 'T'
		END AS result,
		LAG(CASE WHEN (HomeScore > VisitingScore AND HomeTeamName = 'NYA') OR (VisitingScore > HomeScore AND VisitingTeamName = 'NYA') THEN 'W'
			 WHEN (HomeScore > VisitingScore AND VisitingTeamName = 'NYA') OR (VisitingScore > HomeScore AND HomeTeamName = 'NYA') THEN 'L'
			 WHEN VisitingScore = HomeScore THEN 'T' END) OVER (ORDER BY GameLog.GameDate, GameLog.GameLogId) AS previous_game_result,
		LEAD(CASE WHEN (HomeScore > VisitingScore AND HomeTeamName = 'NYA') OR (VisitingScore > HomeScore AND VisitingTeamName = 'NYA') THEN 'W'
			 WHEN (HomeScore > VisitingScore AND VisitingTeamName = 'NYA') OR (VisitingScore > HomeScore AND HomeTeamName = 'NYA') THEN 'L'
			 WHEN VisitingScore = HomeScore THEN 'T' END) OVER (ORDER BY GameLog.GameDate, GameLog.GameLogId) AS next_game_result,
		ROW_NUMBER() OVER (ORDER BY GameLog.GameDate, GameLog.GameLogId) AS island_location,
		GameLog.GameDate,
		GameLog.GameLogId
	FROM dbo.GameLog
	WHERE GameLog.HomeTeamName = 'NYA' OR GameLog.VisitingTeamName = 'NYA'
	AND GameLog.GameType = 'REG'),
CTE_ISLAND_START AS (
	SELECT
		ROW_NUMBER() OVER (ORDER BY GAME_LOG.GameDate, GAME_LOG.GameLogId) AS island_number,
		GAME_LOG.GameDate AS island_start_time,
		GAME_LOG.island_location AS island_start_location
	FROM GAME_LOG
	WHERE GAME_LOG.result = 'L'
	AND (GAME_LOG.previous_game_result <> 'L' OR GAME_LOG.previous_game_result IS NULL)),
CTE_ISLAND_END AS (
	SELECT
		ROW_NUMBER() OVER (ORDER BY GAME_LOG.GameDate, GAME_LOG.GameLogId) AS island_number,
		GAME_LOG.GameDate AS island_end_time,
		GAME_LOG.island_location AS island_end_location
	FROM GAME_LOG
	WHERE GAME_LOG.result = 'L'
	AND (GAME_LOG.next_game_result <> 'L' OR GAME_LOG.next_game_result IS NULL))
SELECT
	CTE_ISLAND_START.island_start_time,
	CTE_ISLAND_END.island_end_time,
	CTE_ISLAND_END.island_end_location - CTE_ISLAND_START.island_start_location + 1 AS count_of_events,
	DATEDIFF(DAY, CTE_ISLAND_START.island_start_time, CTE_ISLAND_END.island_end_time) + 1 AS length_of_streak_in_days
FROM CTE_ISLAND_START
INNER JOIN CTE_ISLAND_END
ON CTE_ISLAND_START.island_number = CTE_ISLAND_END.island_number
ORDER BY CTE_ISLAND_END.island_end_location - CTE_ISLAND_START.island_start_location DESC;
GO

-- Longest winning streaks across all teams
WITH GAME_LOG AS (
	SELECT
		CASE WHEN (HomeScore > VisitingScore AND HomeTeamName = 'BOS') OR (VisitingScore > HomeScore AND VisitingTeamName = 'BOS') THEN 'W'
			 WHEN (HomeScore > VisitingScore AND VisitingTeamName = 'BOS') OR (VisitingScore > HomeScore AND HomeTeamName = 'BOS') THEN 'L'
			 WHEN VisitingScore = HomeScore THEN 'T'
		END AS result,
		LAG(CASE WHEN (HomeScore > VisitingScore AND HomeTeamName = 'BOS') OR (VisitingScore > HomeScore AND VisitingTeamName = 'BOS') THEN 'W'
			 WHEN (HomeScore > VisitingScore AND VisitingTeamName = 'BOS') OR (VisitingScore > HomeScore AND HomeTeamName = 'BOS') THEN 'L'
			 WHEN VisitingScore = HomeScore THEN 'T' END) OVER (PARTITION BY CASE WHEN VisitingTeamName = 'BOS' THEN HomeTeamName ELSE VisitingTeamName END
				ORDER BY GameLog.GameDate, GameLog.GameLogId) AS previous_game_result,
		LEAD(CASE WHEN (HomeScore > VisitingScore AND HomeTeamName = 'BOS') OR (VisitingScore > HomeScore AND VisitingTeamName = 'BOS') THEN 'W'
			 WHEN (HomeScore > VisitingScore AND VisitingTeamName = 'BOS') OR (VisitingScore > HomeScore AND HomeTeamName = 'BOS') THEN 'L'
			 WHEN VisitingScore = HomeScore THEN 'T' END) OVER (PARTITION BY CASE WHEN VisitingTeamName = 'BOS' THEN HomeTeamName ELSE VisitingTeamName END 
				ORDER BY GameLog.GameDate, GameLog.GameLogId) AS next_game_result,
		ROW_NUMBER() OVER (PARTITION BY CASE WHEN VisitingTeamName = 'BOS' THEN HomeTeamName ELSE VisitingTeamName END ORDER BY GameLog.GameDate, GameLog.GameLogId) AS island_location,
		CASE WHEN VisitingTeamName = 'BOS' THEN HomeTeamName ELSE VisitingTeamName END AS opposing_team, 
		GameLog.GameDate,
		GameLog.GameLogId
	FROM dbo.GameLog
	WHERE GameLog.GameType = 'REG'
	AND GameLog.HomeTeamName = 'BOS' OR GameLog.VisitingTeamName = 'BOS'),
CTE_ISLAND_START AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY GAME_LOG.opposing_team ORDER BY GAME_LOG.GameDate, GAME_LOG.GameLogId) AS island_number,
		GAME_LOG.GameDate AS island_start_time,
		GAME_LOG.island_location AS island_start_location,
		GAME_LOG.opposing_team
	FROM GAME_LOG
	WHERE GAME_LOG.result = 'W'
	AND (GAME_LOG.previous_game_result <> 'W' OR GAME_LOG.previous_game_result IS NULL)),
CTE_ISLAND_END AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY GAME_LOG.opposing_team ORDER BY GAME_LOG.GameDate, GAME_LOG.GameLogId) AS island_number,
		GAME_LOG.GameDate AS island_end_time,
		GAME_LOG.island_location AS island_end_location,
		GAME_LOG.opposing_team
	FROM GAME_LOG
	WHERE GAME_LOG.result = 'W'
	AND (GAME_LOG.next_game_result <> 'W' OR GAME_LOG.next_game_result IS NULL))
SELECT
	CTE_ISLAND_START.island_start_time,
	CTE_ISLAND_START.opposing_team,
	CTE_ISLAND_END.island_end_time,
	CTE_ISLAND_END.island_end_location - CTE_ISLAND_START.island_start_location + 1 AS count_of_events,
	DATEDIFF(DAY, CTE_ISLAND_START.island_start_time, CTE_ISLAND_END.island_end_time) + 1 AS length_of_streak_in_days
FROM CTE_ISLAND_START
INNER JOIN CTE_ISLAND_END
ON CTE_ISLAND_START.island_number = CTE_ISLAND_END.island_number
AND CTE_ISLAND_START.opposing_team = CTE_ISLAND_END.opposing_team
ORDER BY CTE_ISLAND_END.island_end_location - CTE_ISLAND_START.island_start_location DESC;
GO

/* Winning streaks by all teams vs. all teams!  Create 2 sections for the first CTE: one for the home team and one for the visiting team.
   Omit ties from the second CTE as they have already been counted once.
   Add extra CTE to order results so we can apply window functions over the combined data set. */
WITH GAME_LOG AS (
	SELECT
		CASE WHEN HomeScore > VisitingScore THEN 'W'
			 WHEN VisitingScore > HomeScore THEN 'L'
			 WHEN HomeScore = VisitingScore THEN 'T'
		END AS result,
		VisitingTeamName AS opposing_team,
		HomeTeamName AS team_to_trend,
		GameLog.GameDate,
		GameLog.GameLogId
	FROM dbo.GameLog
	WHERE GameLog.GameType = 'REG'
	UNION ALL
	SELECT
		CASE WHEN VisitingScore > HomeScore THEN 'W'
			 WHEN HomeScore > VisitingScore THEN 'L'
		END AS result,
		HomeTeamName AS opposing_team,
		VisitingTeamName AS team_to_trend,
		GameLog.GameDate,
		GameLog.GameLogId
	FROM dbo.GameLog
	WHERE GameLog.GameType = 'REG'
	AND VisitingScore <> HomeScore),
GAME_LOG_ORDERED AS (
	SELECT
		GAME_LOG.GameLogId,
		GAME_LOG.GameDate,
		GAME_LOG.team_to_trend,
		GAME_LOG.opposing_team,
		GAME_LOG.result,
		LAG(GAME_LOG.result) OVER (PARTITION BY team_to_trend, opposing_team ORDER BY GAME_LOG.GameDate, GAME_LOG.GameLogId) AS previous_game_result,
		LEAD(GAME_LOG.result) OVER (PARTITION BY team_to_trend, opposing_team ORDER BY GAME_LOG.GameDate, GAME_LOG.GameLogId) AS next_game_result,
		ROW_NUMBER() OVER (PARTITION BY team_to_trend, opposing_team ORDER BY GAME_LOG.GameDate, GAME_LOG.GameLogId) AS island_location
	FROM GAME_LOG),
CTE_ISLAND_START AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY GAME_LOG_ORDERED.team_to_trend, GAME_LOG_ORDERED.opposing_team ORDER BY GAME_LOG_ORDERED.GameDate, GAME_LOG_ORDERED.GameLogId) AS island_number,
		GAME_LOG_ORDERED.GameDate AS island_start_time,
		GAME_LOG_ORDERED.island_location AS island_start_location,
		GAME_LOG_ORDERED.opposing_team,
		GAME_LOG_ORDERED.team_to_trend
	FROM GAME_LOG_ORDERED
	WHERE GAME_LOG_ORDERED.result = 'W'
	AND (GAME_LOG_ORDERED.previous_game_result <> 'W' OR GAME_LOG_ORDERED.previous_game_result IS NULL)),
CTE_ISLAND_END AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY GAME_LOG_ORDERED.team_to_trend, GAME_LOG_ORDERED.opposing_team ORDER BY GAME_LOG_ORDERED.GameDate, GAME_LOG_ORDERED.GameLogId) AS island_number,
		GAME_LOG_ORDERED.GameDate AS island_end_time,
		GAME_LOG_ORDERED.island_location AS island_end_location,
		GAME_LOG_ORDERED.opposing_team,
		GAME_LOG_ORDERED.team_to_trend
	FROM GAME_LOG_ORDERED
	WHERE GAME_LOG_ORDERED.result = 'W'
	AND (GAME_LOG_ORDERED.next_game_result <> 'W' OR GAME_LOG_ORDERED.next_game_result IS NULL))
SELECT
	CTE_ISLAND_START.island_start_time,
	CTE_ISLAND_START.team_to_trend,
	CTE_ISLAND_START.opposing_team,
	CTE_ISLAND_END.island_end_time,
	CTE_ISLAND_END.island_end_location - CTE_ISLAND_START.island_start_location + 1 AS count_of_events,
	DATEDIFF(DAY, CTE_ISLAND_START.island_start_time, CTE_ISLAND_END.island_end_time) + 1 AS length_of_streak_in_days
FROM CTE_ISLAND_START
INNER JOIN CTE_ISLAND_END
ON CTE_ISLAND_START.island_number = CTE_ISLAND_END.island_number
AND CTE_ISLAND_START.opposing_team = CTE_ISLAND_END.opposing_team
AND CTE_ISLAND_START.team_to_trend = CTE_ISLAND_END.team_to_trend
ORDER BY CTE_ISLAND_END.island_end_location - CTE_ISLAND_START.island_start_location DESC;
GO

/* Longest winning streaks across all teams in baseball.  This is very similar to the previous query, but with no need to partition by opposting team. */
WITH GAME_LOG AS (
	SELECT
		CASE WHEN HomeScore > VisitingScore THEN 'W'
			 WHEN VisitingScore > HomeScore THEN 'L'
			 WHEN HomeScore = VisitingScore THEN 'T'
		END AS result,
		VisitingTeamName AS opposing_team,
		HomeTeamName AS team_to_trend,
		GameLog.GameDate,
		GameLog.GameLogId
	FROM dbo.GameLog
	WHERE GameLog.GameType = 'REG'
	UNION ALL
	SELECT
		CASE WHEN VisitingScore > HomeScore THEN 'W'
			 WHEN HomeScore > VisitingScore THEN 'L'
		END AS result,
		HomeTeamName AS opposing_team,
		VisitingTeamName AS team_to_trend,
		GameLog.GameDate,
		GameLog.GameLogId
	FROM dbo.GameLog
	WHERE GameLog.GameType = 'REG'
	AND VisitingScore <> HomeScore),
GAME_LOG_ORDERED AS (
	SELECT
		GAME_LOG.GameLogId,
		GAME_LOG.GameDate,
		GAME_LOG.team_to_trend,
		GAME_LOG.result,
		LAG(GAME_LOG.result) OVER (PARTITION BY team_to_trend ORDER BY GAME_LOG.GameDate, GAME_LOG.GameLogId) AS previous_game_result,
		LEAD(GAME_LOG.result) OVER (PARTITION BY team_to_trend ORDER BY GAME_LOG.GameDate, GAME_LOG.GameLogId) AS next_game_result,
		ROW_NUMBER() OVER (PARTITION BY team_to_trend ORDER BY GAME_LOG.GameDate, GAME_LOG.GameLogId) AS island_location
	FROM GAME_LOG),
CTE_ISLAND_START AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY GAME_LOG_ORDERED.team_to_trend ORDER BY GAME_LOG_ORDERED.GameDate, GAME_LOG_ORDERED.GameLogId) AS island_number,
		GAME_LOG_ORDERED.GameDate AS island_start_time,
		GAME_LOG_ORDERED.island_location AS island_start_location,
		GAME_LOG_ORDERED.team_to_trend
	FROM GAME_LOG_ORDERED
	WHERE GAME_LOG_ORDERED.result = 'W'
	AND (GAME_LOG_ORDERED.previous_game_result <> 'W' OR GAME_LOG_ORDERED.previous_game_result IS NULL)),
CTE_ISLAND_END AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY GAME_LOG_ORDERED.team_to_trend ORDER BY GAME_LOG_ORDERED.GameDate, GAME_LOG_ORDERED.GameLogId) AS island_number,
		GAME_LOG_ORDERED.GameDate AS island_end_time,
		GAME_LOG_ORDERED.island_location AS island_end_location,
		GAME_LOG_ORDERED.team_to_trend
	FROM GAME_LOG_ORDERED
	WHERE GAME_LOG_ORDERED.result = 'W'
	AND (GAME_LOG_ORDERED.next_game_result <> 'W' OR GAME_LOG_ORDERED.next_game_result IS NULL))
SELECT
	CTE_ISLAND_START.island_start_time,
	CTE_ISLAND_START.team_to_trend,
	CTE_ISLAND_END.island_end_time,
	CTE_ISLAND_END.island_end_location - CTE_ISLAND_START.island_start_location + 1 AS count_of_events,
	DATEDIFF(DAY, CTE_ISLAND_START.island_start_time, CTE_ISLAND_END.island_end_time) + 1 AS length_of_streak_in_days
FROM CTE_ISLAND_START
INNER JOIN CTE_ISLAND_END
ON CTE_ISLAND_START.island_number = CTE_ISLAND_END.island_number
AND CTE_ISLAND_START.team_to_trend = CTE_ISLAND_END.team_to_trend
ORDER BY CTE_ISLAND_END.island_end_location - CTE_ISLAND_START.island_start_location DESC;
GO

/*	HomeScore = 12, VisitingScore = 4
	Row Count of last query = 104687

	Change scores to NULL:
	HomeScore = NULL, VisitingScore = NULL
	Row Count of last query = 104688
*/

UPDATE GameLog
	SET HomeScore = null,
		VisitingScore = null
FROM GameLog
WHERE GameLogID = 209967;
GO

UPDATE GameLog
	SET HomeScore = 12,
		VisitingScore = 4
FROM GameLog
WHERE GameLogID = 209967;
GO

SELECT * FROM GameLog WHERE GameLogID = 209967;

