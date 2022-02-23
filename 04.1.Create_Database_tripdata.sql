CREATE DATABASE tripdata;
GO

USE tripdata;
GO


CREATE TABLE YellowTripData (
  ID int,
  VendorID int,
  PickupDate datetime2,
  DropoffDate datetime2,
  PassengerCount int,
  TripDistance float,
  RateCodeID int,
  StoreFwdFlag char(1),
  PULocationID int,
  DOLocationID int,
  PaymentType int,
  FareAmount float,
  FareExtra float,
  MTATax float,
  TipAmount float,
  TollAmount float,
  ImproveSurcharge float,
  TotalAmount float
);
GO

BULK INSERT YellowTripData FROM 'D:\00-2022\08-sql\datacamp\WritingFunctionsAndStored Procedures\Tripdata_sample-pipe.csv' WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');
GO

