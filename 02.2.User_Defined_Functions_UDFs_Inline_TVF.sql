USE BikeShare
GO

/*
Inline TVF (inline table value function)
*/
/* 
 *1. We specify TABLE as the return type, instead of any scalar data type
 *2. One input or Multiple input parameters can be passed to the Inline TVF
 *3. The function body is not enclosed between BEGIN and END block. Inline table valued function body, cannot have BEGIN and END block.
 *4. The structure of the table that gets returned, is determined by the SELECT statement with in the function.
	 https://www.codeproject.com/Articles/167399/Using-Table-Valued-Functions-in-SQL-Server
	 https://www.sqlservertutorial.net/sql-server-user-defined-functions/sql-server-table-valued-functions/
*/
-- Create the function
IF OBJECT_ID(N'dbo.SumStationStats', N'FN') IS NOT NULL
  DROP FUNCTION dbo.SumStationStats;
GO
-- Create the function
-- this function returns the ride count and total ride duration for each starting station where the start date matches the input parameter
CREATE FUNCTION SumStationStats (@StartDate AS datetime)
-- Specify return data type
RETURNS TABLE
AS
  RETURN (
  SELECT
    StartStation,
    -- Use COUNT() to select RideCount
    COUNT(ID) AS RideCount,
    -- Use SUM() to calculate TotalDuration
    SUM(DURATION) AS TotalDuration
  FROM CapitalBikeShare
  WHERE CAST(StartDate AS date) = @StartDate
  -- Group by StartStation
  GROUP BY StartStation);

-- Execute SumStationStats function
SELECT TOP 10
    *
  -- Execute SumStationStats with 3/15/2018
FROM dbo.SumStationStats('3/15/2018')
ORDER BY RideCount DESC;

/*OR*/
-- Create a variable table @StationStats 
DECLARE @StationStats TABLE (
  StartStation nvarchar(100),
  RideCount int,
  TotalDuration numeric
)
-- Populate @StationStats with the results of the function
INSERT INTO @StationStats
  SELECT TOP 10
    *
  -- Execute SumStationStats with 3/15/2018
  FROM dbo.SumStationStats('3/15/2018')
  ORDER BY RideCount DESC
-- Select all the records from @StationStats
SELECT
  *
FROM @StationStats;

-- if you want to view the text of the function, you can use the stored procedure: sp_helptext Function_Name
sp_helptext SumStationStats;

-- you can encrypt the function and in this case you will not be able to view the text of the function.
-- first you need to ALTER FUNCTION and then
-- use WITH ENCRYPTION before the AS clause

