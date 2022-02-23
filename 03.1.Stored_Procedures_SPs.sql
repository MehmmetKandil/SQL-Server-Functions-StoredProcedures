USE BikeShare
GO

-- check if the procedure is exist
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'cuspSumRideHrsSingleDay')
  DROP PROCEDURE cuspSumRideHrsSingleDay
GO

-- Procedure with OUTPUT parameters
-- Create the stored procedure dbo.cuspSumRideHrsSingleDay with OUTPUT parameter
CREATE PROCEDURE dbo.cuspSumRideHrsSingleDay
-- Declare the input parameter
@DateParm date,
-- Declare the output parameter
@RideHrsOut numeric OUTPUT
AS
  -- Don't send the row count 
  SET NOCOUNT ON
  BEGIN
    -- Assign the query result to @RideHrsOut
    SELECT
      @RideHrsOut = SUM(DATEDIFF(MINUTE, StartDate, EndDate)) / 60
    FROM CapitalBikeShare
    -- Cast StartDate as date and compare with @DateParm
    WHERE CAST(StartDate AS date) = @DateParm
    RETURN
  END

-- EXECUTE with OUTPUT parameter
-- Execute the dbo.cuspSumRideHrsSingleDay stored procedure and capture the output parameter.
-- Create @RideHrs
DECLARE @RideHrs AS numeric(18, 0)
-- Execute the stored procedure
EXEC dbo.cuspSumRideHrsSingleDay
-- Pass the input parameter
@DateParm = '3/1/2018',
-- Store the output in @RideHrs
@RideHrsOut = @RideHrs OUTPUT
-- Select @RideHrs
SELECT
  @RideHrs AS RideHours

-------------------------------------------------------------------------------
-- check if the procedure is exist
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'cuspRideSummaryCreate')  
  DROP PROCEDURE cuspRideSummaryCreate  
go

-- Create the stored procedure to insert a record into the RideSummary table.
CREATE PROCEDURE dbo.cuspRideSummaryCreate (@DateParm date, @RideHrsParm numeric)
AS
BEGIN
  SET NOCOUNT ON
  -- Insert into the Date and RideHours columns
  INSERT INTO dbo.RideSummary (Date, RideHours)
    -- Use values of @DateParm and @RideHrsParm
    VALUES (@DateParm, @RideHrsParm)

  -- Select the record that was just inserted
  SELECT
    -- Select Date column
    Date,
    -- Select RideHours column
    RideHours
  FROM dbo.RideSummary
  -- Check whether Date equals @DateParm
  WHERE Date = @DateParm
END;

--------------------------------------------------------------
-- check if the procedure is exist
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'cuspRideSummaryUpdate')  
DROP PROCEDURE cuspRideSummaryUpdate  
go

-- Create the stored procedure to update an existing record in the RideSummary table.
CREATE PROCEDURE dbo.cuspRideSummaryUpdate (@DateParm date, @RideHrs numeric(18, 0))
AS
BEGIN
  SET NOCOUNT ON
  -- Update RideSummary
  UPDATE dbo.RideSummary
  -- Set
  SET Date = @DateParm,
      RideHours = @RideHrs
  -- Include records where Date equals @Date
  WHERE Date = @DateParm
END;

-- "EXECUTE with return value"
-- Execute dbo.cuspRideSummaryUpdate to change the RideHours to 300 for '3/1/2018'. 
-- Store the return code from the stored procedure.
-- Create @ReturnStatus
DECLARE @ReturnStatus AS int
-- Execute the SP, storing the result in @ReturnStatus
EXEC @ReturnStatus = dbo.cuspRideSummaryUpdate
-- Specify @DateParm
@DateParm = '3/1/2018',
-- Specify @RideHrs
@RideHrs = 300

-- Select the columns of interest
SELECT
  @ReturnStatus AS ReturnStatus,
  Date,
  RideHours
FROM dbo.RideSummary
WHERE Date = '3/1/2018';

-----------------------------------------------------------------------------
-- check if the procedure is exist
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'cuspRideSummaryDelete')  
  DROP PROCEDURE cuspRideSummaryDelete  
go

-- Create the stored procedure
CREATE PROCEDURE dbo.cuspRideSummaryDelete
-- Specify @DateParm input parameter
(@DateParm date,
-- Specify @RowCountOut output parameter
@RowCountOut int OUTPUT)
AS
BEGIN
  -- Delete record(s) where Date equals @DateParm
  DELETE FROM dbo.RideSummary
  WHERE Date = @DateParm
  -- Set @RowCountOut to @@ROWCOUNT
  SET @RowCountOut = @@ROWCOUNT
END;


-- EXECUTE with OUTPUT & return value
-- Store and display both the output parameter and return code when executing dbo.cuspRideSummaryDelete SP
-- Create @ReturnStatus
DECLARE @ReturnStatus AS int
-- Create @RowCount
DECLARE @RowCount AS int

-- Execute the SP, storing the result in @ReturnStatus
EXEC @ReturnStatus = dbo.cuspRideSummaryDelete
-- Specify @DateParm
@DateParm = '3/1/2018',
-- Specify RowCountOut
@RowCountOut = @RowCount OUTPUT

-- Select the columns of interest
SELECT
  @ReturnStatus AS ReturnStatus,
  @RowCount AS 'RowCount';

----------------------------------------------------------------------------------
-- **** TRY..CATCH ****
-- check if the procedure is exist
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'cuspRideSummaryDeleteWithError')  
  DROP PROCEDURE cuspRideSummaryDeleteWithError  
go

-- Create dbo.cuspRideSummaryDeleteWithError to include an intentional error so we can see how the TRY CATCH block works.
CREATE PROCEDURE dbo.cuspRideSummaryDeleteWithError
-- (Incorrectly) specify @DateParm
@DateParm nvarchar(30),
-- Specify @Error
@Error nvarchar(max) = NULL OUTPUT
AS
  SET NOCOUNT ON
  BEGIN
    -- Start of the TRY block
    BEGIN TRY
      -- Delete
      DELETE FROM dbo.RideSummary
      WHERE Date = @DateParm
    -- End of the TRY block
    END TRY
    -- Start of the CATCH block
    BEGIN CATCH
      SET @Error =
      'Error_Number: ' + CAST(ERROR_NUMBER() AS varchar) +
      'Error_Severity: ' + CAST(ERROR_SEVERITY() AS varchar) +
      'Error_State: ' + CAST(ERROR_STATE() AS varchar) +
      'Error_Message: ' + ERROR_MESSAGE() +
      'Error_Line: ' + CAST(ERROR_LINE() AS varchar)
    -- End of the CATCH block
    END CATCH
  END;

-- CATCH an error --
-- Execute dbo.cuspRideSummaryDelete and pass an invalid @DateParm value of '1/32/2018' to see how the error is handled.
-- The invalid date will be accepted by the nvarchar data type of @DateParm, but
-- the error will occur when SQL attempts to convert it to a valid date when executing the stored procedure.

-- Create @ReturnCode
DECLARE @ReturnCode AS int
-- Create @ErrorOut
DECLARE @ErrorOut AS nvarchar(max)
-- Execute the SP, storing the result in @ReturnCode
EXEC @ReturnCode = dbo.cuspRideSummaryDeleteWithError
-- Specify @DateParm
@DateParm = '1/32/2018',
-- Assign @ErrorOut to @Error
@Error = @ErrorOut OUTPUT
-- Select @ReturnCode and @ErrorOut
SELECT
  @ReturnCode AS ReturnCode,
  @ErrorOut AS ErrorMessage;
