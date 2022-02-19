USE BikeShare
GO

--Multi statement TVF
IF OBJECT_ID(N'dbo.CountTripAvgDuration', N'FN') IS NOT NULL
  DROP FUNCTION CountTripAvgDuration;
GO
-- Create the function
-- this function returns the trip count and average ride duration for each day for the month & year parameter values passed.
CREATE FUNCTION CountTripAvgDuration (@Month char(2), @Year char(4))
-- Specify return variable
RETURNS @DailyTripStats TABLE (
  TripDate date,
  TripCount int,
  AvgDuration numeric
)
AS
BEGIN
  -- Insert query results into @DailyTripStats
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

SELECT * FROM CountTripAvgDuration('03', '2018')