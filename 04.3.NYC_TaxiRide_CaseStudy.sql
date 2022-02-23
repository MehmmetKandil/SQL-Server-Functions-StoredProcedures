USE tripdata;
GO


--Use EDA to find impossible scenarios
--Calculate how many YellowTripData records have each type of error discovered during EDA.
--DropOffDate before PickupDate, DropOffDate before today, PickupDate before today, TripDistance is zero.
SELECT
  -- PickupDate is after today
  COUNT(CASE
    WHEN PickupDate > GETDATE() THEN 1
  END) AS 'FuturePickup',
  -- DropOffDate is after today
  COUNT(CASE
    WHEN DropOffDate > GETDATE() THEN 1
  END) AS 'FutureDropOff',
  -- PickupDate is after DropOffDate
  COUNT(CASE
    WHEN PickupDate > DropOffDate THEN 1
  END) AS 'PickupBeforeDropoff',
  -- TripDistance is 0
  COUNT(CASE
    WHEN TripDistance = 0 THEN 1
  END) AS 'ZeroTripDistance'
FROM YellowTripData;

--Mean imputation
--Create a stored procedure named cuspImputeTripDistanceMean
--that will apply mean imputation to the YellowTripData records with an incorrect TripDistance of zero
-- Create the stored procedure

-- check if the procedure is exist
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'cuspImputeTripDistanceMean')
  DROP PROCEDURE cuspImputeTripDistanceMean
GO

-- Create the procedure cuspImputeTripDistanceMean
CREATE PROCEDURE dbo.cuspImputeTripDistanceMean
AS
BEGIN
  -- Specify @AvgTripDistance variable
  DECLARE @AvgTripDistance AS numeric(18, 4)

  -- Calculate the average trip distance
  SELECT
    @AvgTripDistance = AVG(TripDistance)
  FROM YellowTripData
  -- Only include trip distances greater than 0
  WHERE TripDistance > 0

  -- Update the records where trip distance is 0
  UPDATE YellowTripData
  SET TripDistance = @AvgTripDistance
  WHERE TripDistance = 0
END;

-----------------------------------------------------------
--Hot Deck imputation
--Create a function named dbo.GetTripDistanceHotDeck that returns a TripDistance value via Hot Deck methodology

-- check if the function is exist
IF OBJECT_ID(N'dbo.GetTripDistanceHotDeck', N'FN') IS NOT NULL
  DROP FUNCTION dbo.GetTripDistanceHotDeck;
GO

-- Create the function
CREATE FUNCTION dbo.GetTripDistanceHotDeck()
-- Specify return data type
RETURNS numeric(18,4)
AS 
BEGIN
RETURN
	-- Select the first TripDistance value
	(SELECT TOP 1 TripDistance
	FROM YellowTripData
    -- Sample 1000 records
	TABLESAMPLE(1000 rows)
    -- Only include records where TripDistance is > 0
	WHERE TripDistance > 0)
END;
--------------------------------------------------------------------
--CREATE FUNCTIONs
--Create three functions to help solve the business case:
-- 1.Convert distance from miles to kilometers.
-- 2.Convert currency based on exchange rate parameter.
	--(These two functions should return a numeric value with precision of 18 and 2 decimal places.)
-- 3.Identify the driver shift based on the hour parameter value passed.

-- Use CREATE FUNCTION to accept @Miles input parameter & return the distance converted to kilometers
-- check if the function is exist
IF OBJECT_ID(N'dbo.ConvertMileToKm', N'FN') IS NOT NULL
  DROP FUNCTION dbo.ConvertMileToKm;
GO
-- Create the function
CREATE FUNCTION dbo.ConvertMileToKm (@Miles numeric(18, 2))
-- Specify return data type
RETURNS numeric(18, 2)
AS
BEGIN
  RETURN
  -- Convert Miles to Kilometers
  (SELECT
    @Miles * 1.609)
END;
-------------------------------------------------------------------
-- Create a function which accepts @DollarAmt and @ExchangeRate input parameters, multiplies them, and returns the result.
-- check if the function is exist
IF OBJECT_ID(N'dbo.ConvertDollar', N'FN') IS NOT NULL
  DROP FUNCTION dbo.ConvertDollar;
GO

-- Create the function
CREATE FUNCTION dbo.ConvertDollar
-- Specify @DollarAmt parameter
(@DollarAmt numeric(18, 2),
-- Specify ExchangeRate parameter
@ExchangeRate numeric(18, 2))
-- Specify return data type
RETURNS numeric(18, 2)
AS
BEGIN
  RETURN
  -- Multiply @ExchangeRate and @DollarAmt
  (SELECT
    @ExchangeRate * @DollarAmt)
END;
--------------------------------------------------------------------
--Create a function that returns the shift as an integer: 1st shift is 12am to 9am, 2nd is 9am to 5pm, 3rd is 5pm to 12am.
-- check if the function is exist
IF OBJECT_ID(N'dbo.GetShiftNumber', N'FN') IS NOT NULL
  DROP FUNCTION dbo.GetShiftNumber;
GO

-- Create the function
CREATE FUNCTION dbo.GetShiftNumber (@Hour integer)
-- Specify return data type
RETURNS int
AS
BEGIN
  RETURN
  -- 12am (0) to 9am (9) shift
  (CASE
    WHEN @Hour >= 0 AND
      @Hour < 9 THEN 1
    -- 9am (9) to 5pm (17) shift
    WHEN @Hour >= 9 AND
      @Hour < 17 THEN 2
    -- 5pm (17) to 12am (24) shift
    WHEN @Hour >= 17 AND
      @Hour < 24 THEN 3
  END)
END;
---------------------------------------------------------------------
-- Test the 3 FUNCTIONs

SELECT
-- Select the first 100 records of PickupDate
TOP 100
  PickupDate,
  -- Determine the shift value of PickupDate
  dbo.GetShiftNumber(DATENAME(HOUR, PickupDate)) AS 'Shift',
  -- Select FareAmount
  FareAmount,
  -- Convert FareAmount to Euro
  dbo.ConvertDollar(FareAmount, 0.87) AS 'FareinEuro',
  -- Select TripDistance
  TripDistance,
  -- Convert TripDistance to kilometers
  dbo.ConvertMiletoKm(TripDistance) AS 'TripDistanceinKM'
FROM YellowTripData
-- Only include records for the 2nd shift
WHERE dbo.GetShiftNumber(DATENAME(HOUR, PickupDate)) = 2;
---------------------------------------------------------------------
-- Logical weekdays with Hot Deck
-- Calculate Total Fare Amount per Total Distance for each day of week. If the TripDistance is zero use the Hot Deck imputation function you created before
SELECT
  -- Select the pickup day of week
  DATENAME(WEEKDAY, PickupDate) AS DayofWeek,
  -- Calculate TotalAmount per TripDistance
  CAST(AVG(TotalAmount /
                        -- Select TripDistance if it's more than 0
                        CASE
                          WHEN TripDistance > 0 THEN TripDistance
                          -- Use GetTripDistanceHotDeck()
                          ELSE dbo.GetTripDistanceHotDeck()
                        END) AS decimal(10, 2)) AS 'AvgFare'
FROM YellowTripData
GROUP BY DATENAME(WEEKDAY, PickupDate)
-- Order by the PickupDate day of week
ORDER BY 
CASE
  WHEN DATENAME(WEEKDAY, PickupDate) = 'Monday' THEN 1
  WHEN DATENAME(WEEKDAY, PickupDate) = 'Tuesday' THEN 2
  WHEN DATENAME(WEEKDAY, PickupDate) = 'Wednesday' THEN 3
  WHEN DATENAME(WEEKDAY, PickupDate) = 'Thursday' THEN 4
  WHEN DATENAME(WEEKDAY, PickupDate) = 'Friday' THEN 5
  WHEN DATENAME(WEEKDAY, PickupDate) = 'Saturday' THEN 6
  WHEN DATENAME(WEEKDAY, PickupDate) = 'Sunday' THEN 7
END ASC;
----------------------------------------------------------------------
-- Format for Germany
-- Write a query to display the TotalDistance, TotalRideTime and TotalFare for each day and NYC Borough
-- Display the date, distance, ride time, and fare totals for German culture
SELECT
  -- Cast PickupDate as a date and display as a German date
  FORMAT(CAST(PickupDate AS date), 'd', 'de-de') AS 'PickupDate',
  Zone.Borough,
  -- Display TotalDistance in the German format
  FORMAT(SUM(TripDistance), 'n', 'de-de') AS 'TotalDistance',
  -- Display TotalRideTime in the German format
  FORMAT(SUM(DATEDIFF(MINUTE, PickupDate, DropoffDate)), 'n', 'de-de') AS 'TotalRideTime',
  -- Display TotalFare in German currency
  FORMAT(SUM(TotalAmount), 'c', 'de-de') AS 'TotalFare'
FROM YellowTripData
INNER JOIN TaxiZoneLookup AS Zone
  ON PULocationID = Zone.LocationID
GROUP BY CAST(PickupDate AS date),
         Zone.Borough
ORDER BY CAST(PickupDate AS date),
Zone.Borough;
----------------------------------------------------------------------
-- Format for English
-- Write a query to display the TotalDistance, TotalRideTime and TotalFare for each day and NYC Borough
-- Display the date, distance, ride time, and fare totals for English culture
SELECT
  -- Cast PickupDate as a date and display as a English date
  FORMAT(CAST(PickupDate AS date), 'd', 'en-us') AS 'PickupDate',
  Zone.Borough,
  -- Display TotalDistance in the English format
  FORMAT(SUM(TripDistance), 'n', 'en-us') AS 'TotalDistance',
  -- Display TotalRideTime in the English format
  FORMAT(SUM(DATEDIFF(MINUTE, PickupDate, DropoffDate)), 'n', 'en-us') AS 'TotalRideTime',
  -- Display TotalFare in English currency
  FORMAT(SUM(TotalAmount), 'c', 'en-us') AS 'TotalFare'
FROM YellowTripData
INNER JOIN TaxiZoneLookup AS Zone
  ON PULocationID = Zone.LocationID
GROUP BY CAST(PickupDate AS date),
         Zone.Borough
ORDER BY CAST(PickupDate AS date),
Zone.Borough;
----------------------------------------------------------------------
-- NYC Borough statistics SP
-- 1st objective of the business case
-- Calculate AvgFarePerKM, RideCount and TotalRideMin for each NYC borough and weekday.
-- You should omit records where the TripDistance is zero.

-- Check if the procedure is exist
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'cuspBoroughRideStats')
  DROP PROCEDURE cuspBoroughRideStats
GO

-- Create the procedure cuspBoroughRideStats
CREATE PROCEDURE dbo.cuspBoroughRideStats
AS
BEGIN
  SELECT
    -- Calculate the pickup weekday
    DATENAME(WEEKDAY, PickupDate) AS 'Weekday',
    -- Select the Borough
    Zone.Borough AS 'PickupBorough',
    -- Display AvgFarePerKM as German currency
    FORMAT(AVG(dbo.ConvertDollar(TotalAmount, .88) / dbo.ConvertMiletoKM(TripDistance)), 'c', 'de-de') AS 'AvgFarePerKM',
    -- Display RideCount in the German format
    FORMAT(COUNT(ID), 'n', 'de-de') AS 'RideCount',
    -- Display TotalRideMin in the German format
    FORMAT(SUM(DATEDIFF(SECOND, PickupDate, DropOffDate)) / 60, 'n', 'de-de') AS 'TotalRideMin'
  FROM YellowTripData
  INNER JOIN TaxiZoneLookup AS Zone
    ON PULocationID = Zone.LocationID
  -- Only include records where TripDistance is greater than 0
  WHERE TripDistance > 0
  -- Group by pickup weekday and Borough
  GROUP BY DATENAME(WEEKDAY, PickupDate),
           Zone.Borough
  ORDER BY CASE
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Monday' THEN 1
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Tuesday' THEN 2
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Wednesday' THEN 3
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Thursday' THEN 4
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Friday' THEN 5
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Saturday' THEN 6
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Sunday' THEN 7
  END,
  SUM(DATEDIFF(SECOND, PickupDate, DropOffDate)) / 60
  DESC
END;
----------------------------------------------------------------------
-- NYC Borough statistics results
-- Let's see the results of the dbo.cuspBoroughRideStats stored procedure we just created
-- Create SPResults
DECLARE @SPResults table(
  	-- Create Weekday
	Weekday nvarchar(30),
    -- Create Borough
	Borough nvarchar(30),
    -- Create AvgFarePerKM
	AvgFarePerKM nvarchar(30),
    -- Create RideCount
	RideCount	nvarchar(30),
    -- Create TotalRideMin
	TotalRideMin nvarchar(30))

-- Insert the results into @SPResults
INSERT INTO @SPResults
-- Execute the SP
EXEC dbo.cuspBoroughRideStats

-- Select all the records from @SPresults 
SELECT * 
FROM @SPresults;
----------------------------------------------------------------------

-- 2nd objective of the business case
-- **Pickup locations by shift**
-- What are the AvgFarePerKM, RideCount and TotalRideMin for each pickup location and shift within a NYC Borough?
-- Create a stored procedure named cuspPickupZoneShiftStats that accepts @Borough nvarchar(30) as an input parameter and
-- limits records with the matching Borough value.

-- Check if the procedure is exist
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'cuspPickupZoneShiftStats')
  DROP PROCEDURE cuspPickupZoneShiftStats
GO

-- Create the stored procedure
CREATE PROCEDURE dbo.cuspPickupZoneShiftStats
-- Specify @Borough parameter
@Borough nvarchar(30)
AS
BEGIN
  SELECT
    DATENAME(WEEKDAY, PickupDate) AS 'Weekday',
    -- Calculate the shift number
    dbo.GetShiftNumber(DATEPART(HOUR, PickupDate)) AS 'Shift',
    Zone.Zone AS 'Zone',
    FORMAT(AVG(dbo.ConvertDollar(TotalAmount, .77) / dbo.ConvertMiletoKM(TripDistance)), 'c', 'de-de') AS 'AvgFarePerKM',
    FORMAT(COUNT(ID), 'n', 'de-de') AS 'RideCount',
    FORMAT(SUM(DATEDIFF(SECOND, PickupDate, DropOffDate)) / 60, 'n', 'de-de') AS 'TotalRideMin'
  FROM YellowTripData
  INNER JOIN TaxiZoneLookup AS Zone
    ON PULocationID = Zone.LocationID
  WHERE dbo.ConvertMiletoKM(TripDistance) > 0
  AND Zone.Borough = @Borough
  GROUP BY DATENAME(WEEKDAY, PickupDate),
           -- Group by shift
           dbo.GetShiftNumber(DATEPART(HOUR, PickupDate)),
           Zone.Zone
  ORDER BY CASE
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Monday' THEN 1
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Tuesday' THEN 2
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Wednesday' THEN 3
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Thursday' THEN 4
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Friday' THEN 5
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Saturday' THEN 6
    WHEN DATENAME(WEEKDAY, PickupDate) = 'Sunday' THEN 7
  END,
  -- Order by shift
  dbo.GetShiftNumber(DATEPART(HOUR, PickupDate)),
  SUM(DATEDIFF(SECOND, PickupDate, DropOffDate)) / 60 DESC
END;
----------------------------------------------------------------------
-- Pickup locations by shift results
-- Let's see the AvgFarePerKM,RideCount and TotalRideMin for the pickup locations within Manhattan during the different driver shifts of each weekday.
-- Create @Borough
DECLARE @Borough AS nvarchar(30) = 'Manhattan'
-- Execute the SP
EXEC dbo.cuspPickupZoneShiftStats
-- Pass @Borough
@Borough = 'Manhattan';


