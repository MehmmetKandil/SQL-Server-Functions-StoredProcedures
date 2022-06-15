USE BikeShare
GO

/*
Multi-statement table-valued functions (MSTVF)
* You can execute multiple queries within the function and aggregate results into the returned table.
*/

-- Check if the function exists
IF OBJECT_ID(N'dbo.CountTripAvgDuration', N'FN') IS NOT NULL
  DROP FUNCTION CountTripAvgDuration;
GO
-- Create the function
-- this function returns the trip count and average ride duration for each day for the month & year parameter values passed.
CREATE FUNCTION CountTripAvgDuration (@Month char(2), @Year char(4))
-- Specify return table variable
RETURNS @DailyTripStats TABLE (
  TripDate date,
  TripCount int,
  AvgDuration numeric
)
AS
BEGIN
  -- Populate the table avriable @DailyTripStats with the results of the Query
  INSERT INTO @DailyTripStats
    SELECT
      -- Cast StartDate as a date
      CAST(StartDate AS date),
      COUNT(ID),
      AVG(Duration)
    FROM CapitalBikeShare
    WHERE DATEPART(MONTH, StartDate) = @Month
    AND DATEPART(YEAR, StartDate) = @Year
    -- Group by StartDate as a date
    GROUP BY CAST(StartDate AS date)
  -- Return
  RETURN
END

-- Execute a multi-statement table-valued function CountTripAvgDuration
SELECT * FROM CountTripAvgDuration('03', '2018')

/*
***********************************************************************************
*/

USE BikeStores;
GO

/*
Another example of Multi-statement table-valued functions (MSTVF)
The following udfContacts() function combines staffs and customers into a single contact list:
https://www.sqlservertutorial.net/sql-server-user-defined-functions/sql-server-table-valued-functions/
*/

-- Check if the function exists
IF OBJECT_ID(N'dbo.udfContacts', N'FN') IS NOT NULL
  DROP FUNCTION CountTripAvgDuration;
GO

-- Create the function
-- udfContacts() function combines staffs and customers into a single contact list
CREATE FUNCTION udfContacts()
	-- Specify return table variable
    RETURNS @contacts TABLE (
        first_name VARCHAR(50),
        last_name VARCHAR(50),
        email VARCHAR(255),
        phone VARCHAR(25),
        contact_type VARCHAR(20)
    )
AS
BEGIN
	-- Populate the table avriable @contacts with the results of the Query realted to staffs table
    INSERT INTO @contacts
    SELECT 
        first_name, 
        last_name, 
        email, 
        phone,
        'Staff'
    FROM
        sales.staffs;
	-- Populate the table avriable @contacts with the results of the Query realted to customers table
    INSERT INTO @contacts
    SELECT 
        first_name, 
        last_name, 
        email, 
        phone,
        'Customer'
    FROM
        sales.customers;
    RETURN;
END;

-- Execute a multi-statement table-valued function udfContacts
SELECT
    * 
FROM
    udfContacts();




