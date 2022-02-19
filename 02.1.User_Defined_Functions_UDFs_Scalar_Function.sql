USE BikeShare
go
--create, update, and execute user-defined functions (UDFs)
--various types of UDFs: scalar, inline, and multi-statement table-valued

-- 1- Scalar functions may or may not have parameters
--    always return a single (scalar) value. 
--    The returned value can be of any data type, except text, ntext, image, cursor, and timestamp

-- ***Scalar Function with no input parameter***
--******************* 1 ****************************
IF OBJECT_ID(N'dbo.GetTomorrow', N'FN') IS NOT NULL
  DROP FUNCTION dbo.GetTomorrow;
GO
-- Create GetTomorrow()
CREATE FUNCTION GetTomorrow ()
RETURNS date
AS
BEGIN
  RETURN (SELECT
    DATEADD(DAY, 1, GETDATE()))
END

SELECT dbo.GetTomorrow();
---------------------------------------------------------------------------------------------
-- ***Scalar Function with no input parameter***
--******************* 2 ****************************
IF OBJECT_ID(N'dbo.GetYesterday', N'FN') IS NOT NULL
  DROP FUNCTION GetYesterday;
GO
-- Create GetYesterday()
CREATE FUNCTION GetYesterday ()
-- Specify return data type
RETURNS date
AS
BEGIN
  -- Calculate yesterday's date value
  RETURN (SELECT
    DATEADD(DAY, -1, GETDATE()))
END

SELECT dbo.GetYesterday();
----------------------------------------------------------------------------------------------
-- ***Scalar Function with input parameter***
--******************* 1 ****************************
IF OBJECT_ID(N'dbo.SumRideHrsSingleDay', N'FN') IS NOT NULL
  DROP FUNCTION SumRideHrsSingleDay;
GO
-- Create SumRideHrsSingleDay
CREATE FUNCTION SumRideHrsSingleDay (@DateParm date)
-- Specify return data type
RETURNS numeric
AS
-- Begin
BEGIN
  RETURN
  -- Add the difference between StartDate and EndDate
  (SELECT
    SUM(DATEDIFF(MINUTE, StartDate, EndDate)) / 60
  FROM CapitalBikeShare
  -- Only include transactions where StartDate = @DateParm
  WHERE CAST(StartDate AS date) = @DateParm)
-- End
END

-- Create @RideHrs
DECLARE @RideHrs AS numeric
-- Execute SumRideHrsSingleDay function and store the result in @RideHrs
EXEC @RideHrs = dbo.SumRideHrsSingleDay @DateParm = '3/5/2018'
SELECT
  'Total Ride Hours for 3/5/2018:',
  @RideHrs

-- *** OR ***
SELECT
  dbo.SumRideHrsSingleDay('3/5/2018');

-----------------------------------------------------------------------------------------------
-- ***Scalar Function with input parameter***
--******************* 2 ****************************
IF OBJECT_ID(N'dbo.SumRideHrsDateRange', N'FN') IS NOT NULL
  DROP FUNCTION SumRideHrsDateRange;
GO
-- Create the function
CREATE FUNCTION SumRideHrsDateRange (@StartDateParm datetime, @EndDateParm datetime)
-- Specify return data type
RETURNS numeric
AS
BEGIN
  RETURN
  -- Sum the difference between StartDate and EndDate
  (SELECT
    SUM(DATEDIFF(MINUTE, StartDate, EndDate)) / 60
  FROM CapitalBikeShare
  -- Include only the relevant transactions
  WHERE StartDate > @StartDateParm
  AND StartDate < @EndDateParm)
END

-- Create @BeginDate
DECLARE @BeginDate AS date = '3/1/2018'
-- Create @EndDate
DECLARE @EndDate AS date = '3/10/2018'
SELECT
  -- Select @BeginDate
  @BeginDate AS BeginDate,
  -- Select @EndDate
  @EndDate AS EndDate,
  -- Execute SumRideHrsDateRange()
  dbo.SumRideHrsDateRange(@BeginDate, @EndDate) AS TotalRideHrs
