USE BikeShare
go

/*Create, update, and execute User-Defined Functions (UDFs)*/
/*'https://www.sqlservertutorial.net/sql-server-user-defined-functions/sql-server-scalar-functions/'*/

/*	 Various types of UDFs: 
	*Scalar
	*Inline
	*Multi-statement table-valued
*/

/* Scalar functions may or may not have parameters
	* Always return a single (scalar) value. 
	* The returned value can be of any data type, except text, ntext, image, cursor, and timestamp
*/

/*Scalar Function:
	* with no input parameter
	* with input parameter
*/

/*Scalar Function with no input parameter*/

/* 1st Function*/
-- Check if the function exists
IF OBJECT_ID(N'dbo.GetTomorrow', N'FN') IS NOT NULL
  DROP FUNCTION dbo.GetTomorrow;
GO
-- Create GetTomorrow() function
CREATE FUNCTION GetTomorrow ()
RETURNS date
AS
BEGIN
  RETURN (SELECT
	-- DATEADD(datepart, number, date)
    DATEADD(DAY, 1, GETDATE()))
END

SELECT dbo.GetTomorrow()

/*
***********************************************************************************
*/

/*2nd Function*/
-- Check if the function exists
IF OBJECT_ID(N'dbo.GetYesterday', N'FN') IS NOT NULL
  DROP FUNCTION GetYesterday;
GO
-- Create GetYesterday() function
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

/*
***********************************************************************************
*/

/*Scalar Function with input parameter*/

/*1st Function*/
/*One input one output*/
/*Create a function named SumRideHrsSingleDay() which returns the total ride time in hours for the @DateParm parameter passed*/

-- Check if the function exists
IF OBJECT_ID(N'dbo.SumRideHrsSingleDay', N'FN') IS NOT NULL
  DROP FUNCTION SumRideHrsSingleDay;
GO

-- Create a function SumRideHrsSingleDay()
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

/*** OR ***/
SELECT
  'Total Ride Hours for 3/5/2018:', dbo.SumRideHrsSingleDay('3/5/2018');

/*
***********************************************************************************
*/

/*2nd Function*/
/*Multiple inputs one output*/
/*Create a function SumRideHrsDateRange that accepts two parameters @StartDateParm and @EndDateParm 
and returns the total ride hours for all transactions that have a StartDate within the parameter values*/

-- Check if the function exists
IF OBJECT_ID(N'dbo.SumRideHrsDateRange', N'FN') IS NOT NULL
  DROP FUNCTION SumRideHrsDateRange;
GO

-- Create a function SumRideHrsDateRange
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
