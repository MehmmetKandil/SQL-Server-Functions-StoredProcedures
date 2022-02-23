USE tripdata;
GO


CREATE TABLE TaxiZoneLookup (
  LocationID int,
  Borough VARCHAR(100),
  Zone VARCHAR(100),
  ServiceZone VARCHAR(100)
);
GO

BULK INSERT TaxiZoneLookup FROM 'D:\00-2022\08-sql\datacamp\WritingFunctionsAndStored Procedures\taxi_zone_lookup.csv' WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');
GO

