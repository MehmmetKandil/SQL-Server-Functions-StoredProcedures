USE BikeShare;
GO


/*Exploratory Data Analysis(EDA) of BikeShare dataset using functions*/

/*
* CONVERT() >> https://www.sqlservertutorial.net/sql-server-system-functions/sql-server-convert-function/
* DATEPART() >> https://www.sqlservertutorial.net/sql-server-date-functions/sql-server-datepart-function/
* CAST() >> https://www.sqlservertutorial.net/sql-server-system-functions/sql-server-cast-function/
* DATEDIFF() >> https://www.sqlservertutorial.net/sql-server-date-functions/sql-server-datediff-function/
* DATENAME() >> https://www.sqlservertutorial.net/sql-server-date-functions/sql-server-datename-function/
*/

-- Q1. How many transactions exist per day?

SELECT
  -- Select the date portion of StartDate (StartDate is a datetime) by using convert() function 
  convert(date, StartDate) as StartDate,
  -- Measure how many records exist for each StartDate
  count(id) as CountOfRows 
FROM CapitalBikeShare 
-- Group by the date portion of StartDate
group by convert(date, StartDate)
-- Sort the results by the date portion of StartDate
order by convert(date, StartDate);

select * from CapitalBikeShare;

/*
***********************************************************************************
*/

-- Q2. What is the trip time in hours per day = (EndDate - StartDate)?
-- First step, you must check if StartDate & EndDate have Seconds or no seconds?

--StartDate has Seconds or not?
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

--EndDate has Seconds or not?
SELECT
	-- Count the number of IDs
	COUNT(ID) AS Count,
    -- Use DATEPART() to evaluate the SECOND part of StartDate
    "EndDate" = CASE WHEN DATEPART(SECOND, EndDate) = 0 THEN 'SECONDS = 0'
					   WHEN DATEPART(SECOND, EndDate) > 0 THEN 'SECONDS > 0' END
FROM CapitalBikeShare
GROUP BY
    -- Use DATEPART() to Group By the CASE statement
	CASE WHEN DATEPART(SECOND, EndDate) = 0 THEN 'SECONDS = 0'
		 WHEN DATEPART(SECOND, EndDate) > 0 THEN 'SECONDS > 0' END;


-- Second step, Calculate TotalTripHours per day
SELECT CAST(StartDate AS DATE) StartDate,
	-- Calculate TotalTripHours
	SUM(DATEDIFF(MINUTE, StartDate, EndDate))/ 60 as TotalTripHours 
FROM CapitalBikeShare 
GROUP BY CAST(StartDate AS DATE)
-- Order TotalTripHours in descending order
ORDER BY TotalTripHours DESC;

/*
***********************************************************************************
*/

-- Q3. Which day of week is busiest?
-- Calculate TotalTripHours per DayOfWeek
SELECT
    -- Select the day of week value for StartDate
	DATENAME(WEEKDAY, StartDate) as DayOfWeek,
    -- Calculate TotalTripHours
	SUM(DATEDIFF(MINUTE, StartDate, EndDate))/ 60 as TotalTripHours 
FROM CapitalBikeShare 
-- Group by the day of week
GROUP BY DATENAME(WEEKDAY, StartDate)
-- Order TotalTripHours in descending order
ORDER BY TotalTripHours DESC;

/*
***********************************************************************************
*/

/*Saturday was the busiest day of the month for BikeShare rides. 
Do you wonder if there were any individual Saturday outliers that contributed to this?*/

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
GROUP BY CONVERT(DATE, StartDate)
ORDER BY TotalRideHours DESC;

/*
***********************************************************************************
*/


-- DECLARE & CAST
-- Let's use DECLARE() and CAST() to combine a date variable and a time variable into a datetime variable.

-- Declare and Initialize a time variable @ShiftStartTime
DECLARE @ShiftStartTime AS time = '08:00 AM'

-- Declare a date variable @StartDate
DECLARE @StartDate AS date

-- Initializing @StartDate by setting StartDate to the first StartDate from CapitalBikeShare
SET 
	@StartDate = (
    	SELECT TOP 1 StartDate 
    	FROM CapitalBikeShare 
    	ORDER BY StartDate ASC
		)

-- Declare a datetime variable @ShiftStartDateTime
DECLARE @ShiftStartDateTime AS datetime

-- Cast StartDate and ShiftStartTime to DateTime data type
SET @ShiftStartDateTime = Cast(@StartDate AS datetime) + Cast(@ShiftStartTime AS datetime) 

SELECT @ShiftStartDateTime

/*
***********************************************************************************
*/

-- DECLARE a TABLE VARIABLE

-- Declare a variable @Shifts as a TABLE
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

-- Declare a variable @RideDates as a TABLE
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



/*Date Manipulation*/

-- GETDATE() function returns the current system timestamp
SELECT GETDATE();

-- Using variables
DECLARE @CurrentDatetime AS datetime
SET @CurrentDatetime = GETDATE()
SELECT @CurrentDatetime;

-- DATEDIFF( date_part , start_date , end_date)
-- DATEDIFF calculates the difference between two dates in years, months, weeks, etc.
SELECT DATEDIFF(DAY, '2/26/2018', '3/3/2018');
SELECT DATEDIFF(WEEK, '2/26/2018', '3/3/2018');
SELECT DATEDIFF(MONTH, '2/26/2018', '3/3/2018');


-- DATEADD(datepart, number, date)
-- The DATEADD() function adds a number to a specified date part of an input date and returns the modified value.

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

