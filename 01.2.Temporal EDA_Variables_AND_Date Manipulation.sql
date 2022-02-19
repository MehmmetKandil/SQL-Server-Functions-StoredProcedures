SELECT
  -- Select the date portion of StartDate
  convert(date, StartDate) as StartDate,
  -- Measure how many records exist for each StartDate
  count(id) as CountOfRows 
FROM CapitalBikeShare 
-- Group by the date portion of StartDate
group by convert(date, StartDate)
-- Sort the results by the date portion of StartDate
order by convert(date, StartDate);




--to check if there is a SECOND part of StartDate
SELECT
	-- Count the number of IDs
	COUNT(ID) AS Count,
    -- Use DATEPART() to evaluate the SECOND part of StartDate
    "StartDate" = CASE WHEN DATEPART(SECOND, StartDate) = 0 THEN 'SECONDS = 0'
					   WHEN DATEPART(SECOND, StartDate) > 0 THEN 'SECONDS > 0' END
FROM CapitalBikeShare
GROUP BY
    -- Use DATEPART() to Group By the CASE statement
	CASE WHEN DATEPART(SECOND, StartDate) = 0 THEN 'SECONDS = 0'
		 WHEN DATEPART(SECOND, StartDate) > 0 THEN 'SECONDS > 0' END;



--to check if there is a MINUTE part of StartDate
SELECT
	-- Count the number of IDs
	COUNT(ID) AS Count,
    -- Use DATEPART() to evaluate the SECOND part of StartDate
    "StartDate" = CASE WHEN DATEPART(MINUTE, StartDate) = 0 THEN 'MINUTES = 0'
					   WHEN DATEPART(MINUTE, StartDate) > 0 THEN 'MINUTES > 0' END
FROM CapitalBikeShare
GROUP BY
    -- Use DATEPART() to Group By the CASE statement
	CASE WHEN DATEPART(MINUTE, StartDate) = 0 THEN 'MINUTES = 0'
		 WHEN DATEPART(MINUTE, StartDate) > 0 THEN 'MINUTES > 0' END;


-- Calculate TotalTripHours per day
SELECT
	SUM(DATEDIFF(MINUTE, StartDate, EndDate))/ 60 as TotalTripHours 
FROM CapitalBikeShare 

WHERE CAST(StartDate AS DATE) = '03/01/2018'
-- Order TotalTripHours in descending order
ORDER BY TotalTripHours DESC


-- Calculate TotalTripHours per day
SELECT
    -- Select the day of week value for StartDate
	DATENAME(WEEKDAY, StartDate) as DayOfWeek,
    -- Calculate TotalTripHours
	SUM(DATEDIFF(MINUTE, StartDate, EndDate))/ 60 as TotalTripHours 
FROM CapitalBikeShare 
-- Group by the day of week
GROUP BY DATENAME(WEEKDAY, StartDate)
-- Order TotalTripHours in descending order
ORDER BY TotalTripHours DESC




-- Find the outliers of Saturday
SELECT
	-- Calculate TotalRideHours using SUM() and DATEDIFF()
  	SUM(DATEDIFF(MINUTE, StartDate, EndDate))/ 60 AS TotalRideHours,
    -- Select the DATE portion of StartDate
  	CONVERT(DATE, StartDate) AS DateOnly,
    -- Select the WEEKDAY
  	DATENAME(WEEKDAY, CONVERT(DATE, StartDate)) AS DayOfWeek 
FROM CapitalBikeShare
-- Only include Saturday
WHERE DATENAME(WEEKDAY, StartDate) = 'Saturday' 
GROUP BY CONVERT(DATE, StartDate);



-- DECLARE & CAST
-- Create @ShiftStartTime
DECLARE @ShiftStartTime AS time = '08:00 AM'

-- Create @StartDate
DECLARE @StartDate AS date

-- Set StartDate to the first StartDate from CapitalBikeShare
SET 
	@StartDate = (
    	SELECT TOP 1 StartDate 
    	FROM CapitalBikeShare 
    	ORDER BY StartDate ASC
		)

-- Create ShiftStartDateTime
DECLARE @ShiftStartDateTime AS datetime

-- Cast StartDate and ShiftStartTime to datetime data types
SET @ShiftStartDateTime = Cast(@StartDate AS datetime) + Cast(@ShiftStartTime AS datetime) 

SELECT @ShiftStartDateTime


--DECLARE a TABLE VARIABLE
-- Declare @Shifts as a TABLE
DECLARE @Shifts TABLE (
    -- Create StartDateTime column
	StartDateTime DateTime,
    -- Create EndDateTime column
	EndDateTime DateTime)
-- Populate @Shifts
INSERT INTO @Shifts (StartDateTime, EndDateTime)
	SELECT '3/1/2018 8:00 AM', '3/1/2018 4:00 PM'
SELECT * 
FROM @Shifts


-- Instead of storing static values in a table variable, let's store the result of a query.
-- Declare @RideDates as a TABLE
DECLARE @RideDates TABLE(
    -- Define RideStart column
	RideStart DATE, 
    -- Define RideEnd column
    RideEnd DATE)
-- Populate @RideDates
INSERT INTO @RideDates(RideStart, RideEnd)
-- Select the unique date values of StartDate and EndDate
SELECT DISTINCT
    -- Cast StartDate as date
	CAST(StartDate as date),
    -- Cast EndDate as date
	CAST(EndDate as date) 
FROM CapitalBikeShare 
SELECT * 
FROM @RideDates



-- Date Manipulation

SELECT DATEDIFF(DAY, '2/26/2018', '3/3/2018')
SELECT DATEDIFF(WEEK, '2/26/2018', '3/3/2018')
SELECT DATEDIFF(MONTH, '2/26/2018', '3/3/2018')


-- Yesterday
SELECT DATEADD(DAY, -1, GETDATE());
--Last Month
SELECT DATEADD(MONTH, -1, GETDATE());
--Last Year
SELECT DATEADD(YEAR, -1, GETDATE());

-- Find the first day of the current month
SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)

-- Find the first day of the current week
SELECT DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)

