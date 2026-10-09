# PostgreSQL Documentation Readthrough - Part Zero

## Data

The e-commerce database was taken from the GitHub [repo](https://github.com/harryho/db-samples/blob/master/pgsql/ecommerce.sql), while the taxi data was taken from the NYC Taxi and Limousine Commission [site](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) for the yellow taxi data in Summer 2025. The flight data was taken from [PostgresPro website](https://postgrespro.com/community/demodb), specifically the three month database.

### Pre-Processing

#### YellowCab

I used Polars in Python (in [this notebook](data/yellow_trip/Extract-Transform-Load.ipynb)) to read all twelve of the 2025 parquet files, perform some transformations, and write to a CSV to be read into the database. The parquet files added up to roughly 840MB, the CSV file is roughly 6.6GB. I used lazy loading of the data, and streaming write, to create a CSV. After trying to work on my laptop with this it was a bit unwieldy so I decided to only use June, July, and August months. This produced a CSV file of only 1.2GB once rows with null values or negative fares had been removed. The code for the table creation and loading of data is [here](data/yellow_trip/yellow_trip.sql).

Once in the database I did some exploring using the pickup datetime and found that there was a record for the first day of the year in the dataset. I also found for days of the year 151 and 244 there were nearly no fares for those days. Sure enough the entries for the first day of the year were due to two records dated 2009 in the dataset. The entries for day 151 were for fares that started on the 31st of May, but ended on the first of June. The entries for day 244 were dated the first of September, so they also should not be in the dataset, along with the data from 2009.

There were no negative trip distances, but there were a lot of negative total fare values. Looking at the payment types there are four values for negative fares: Cash, Credit Card, Dispute, and No Charge. Dispute and No Charge I can kinda see that it could be negative, but for Cash and Credit Card I cannot think why this would be the case. The metadata document and supplementary material on fares do not mention negative fares, so I removed this data.

The queries I used for exploration were:

```sql
--- This query showed the total number of fares collected on a given day of the year,
--- and by ordering by day of the year made it easy to spot days with reduced income or
--- wildly inapropriate dates
SELECT EXTRACT(DOY FROM tpep_dropoff_datetime) AS doy, SUM(fare_amount) AS daily_total 
FROM trips 
GROUP BY doy 
ORDER BY doy;

--- Like the query above, but for the pickup date not the drop off
SELECT EXTRACT(DOY FROM tpep_pickup_datetime) as doy, SUM(fare_amount) AS daily_total 
FROM trips 
GROUP BY doy 
ORDER BY doy;

--- Used to scrutinise a given day highlighted in the queries above
SELECT * 
FROM trips
WHERE EXTRACT(DOY FROM tpep_dropoff_datetime) = 245;

--- Check there are no negative distances
SELECT trip_distance 
FROM trips 
WHERE trip_distance < 0;

--- Find out the total amount of negative rides, and the fare associated with them
SELECT COUNT(*) AS number_of_rides, SUM(fare_amount) AS total_negative_fare_amount 
FROM trips 
WHERE fare_amount < 0;

--- Check the fare types for negative fare amounts
SELECT DISTINCT payment_type, COUNT(*) number_of_rides 
FROM trips 
WHERE fare_amount < 0 
GROUP BY payment_type;

--- Check the drop-off time is after the pickup time
SELECT * 
FROM trips 
WHERE tpep_pickup_datetime > tpep_dropoff_datetime;

--- Check for long running fares
SELECT id 
FROM trips 
GROUP BY id 
HAVING max(tpep_dropoff_datetime - tpep_pickup_datetime) > '1 day'::interval;

--- Check for no trip distance journeys
SELECT * 
FROM trips 
WHERE trip_distance = 0

--- Check for obviously erroneous outlier entries in the fare amount
SELECT fare_amount, trip_distance 
FROM trips 
WHERE fare_amount > 1000 AND trip_distance < 100
ORDER BY trip_distance DESC;

--- Check for obviously erroneous outlier entries in the tax and tolls amount
SELECT mta_tax, tolls_amount, trip_distance
FROM trips
WHERE mta_tax > 5000 or tolls_amount > 700
ORDER BY trip_distance DESC;
```

To transform the data into the records I wanted, that is no erroneous dates, no negative fares, and no fares over $1000 but with less than 100 miles distance, I used the following from the [notebook](data/yellow_trip/Extract-Transform-Load.ipynb). For fares over 1 day in length, of zero distance trips, I ignored, as I didn't understand how they arose.

```python
# Create a scan of all the parquet files in the current directory, but do not load them into memory
def extract():
    return pl.scan_parquet("*.parquet")

# Change numeric values for readable text values
def update_payment_type(df):
    return df.with_columns(replaced=pl.col("payment_type").replace_strict([0, 1, 2, 3, 4, 5, 6], 
        ["FlexFareTrip", "CreditCard", "Cash", "NoCharge", "Dispute","Unknown","VoidedTrip"])
        ).drop("payment_type"
        ).rename({"replaced": "payment_type"})

# Change numeric values for readable text values
def update_rate_code(df):
    return df.with_columns(replaced=pl.col("RatecodeID").replace_strict([1, 2, 3, 4, 5, 6, 99], 
    ["StandardRate", "JFK", "Newark", "NassauOrWestchester", "NegotiatedFare", "GroupRide", "NullUnknown"])
        ).drop("RatecodeID"
        ).rename({"replaced": "RateCode"})

# Remove rows that have a null value in any column
def drop_null_values(df):
    return df.drop_nulls()

# Remove all rows with dates that are either wildly wrong, or in the wrong day for the pickup time
def drop_unwanted_pickup_dates(df):
    df = df.with_columns(pl.col("tpep_pickup_datetime").dt.month().alias("pickup_month"))
    df = df.filter(pl.col("pickup_month").is_in([6, 7, 8]))
    return df.drop("pickup_month")

# Remove all rows with dates that are straddling the times the data is valid for, or are very wrong
def drop_unwanted_dropoff_dates(df):
    df = df.with_columns(pl.col("tpep_dropoff_datetime").dt.month().alias("dropoff_month"))
    df = df.filter(pl.col("dropoff_month").is_in([6, 7, 8]))
    return df.drop("dropoff_month")

# Remove where the fare is negative
def drop_negative_fares(df):
    return df.filter(pl.col("fare_amount") > 0)

# Remove where the pick up time is after the drop off time
def drop_time_travel(df):
    return df.filter(~(pl.col("tpep_pickup_datetime") > pl.col("tpep_dropoff_datetime")))
    
# Remove where the fare is over £1000 but the distance is less than 100 miles
def drop_outlier_fare_amount_records(df):
    return df.filter(~((pl.col("fare_amount") > 100) & (pl.col("trip_distance") < 100)))

# Remove where the mta tax is over £5000
def drop_outlier_mta_tax_records(df):
    return df.filter(~(pl.col("mta_tax") > 5000))

# Remove where the toll charge is over £700
def drop_outlier_toll_records(df):
    return df.filter(~(pl.col("mta_tax") > 700))

# Create a sink, so that when the pipleine is run the streaming data goes to the file
def write_to_csv(df):
    df.sink_csv("2025_yellow_cab_data.csv")

# Extract
df = extract()

# Transform
df = update_payment_type(df)
df = update_rate_code(df)
df = drop_null_values(df)
df = drop_unwanted_pickup_dates(df)
df = drop_unwanted_dropoff_dates(df)
df = drop_negative_fares(df)
df = drop_time_travel(df)
df = drop_outlier_fare_amount_records(df)
df = drop_outlier_mta_tax_records(df)
df = drop_outlier_toll_records(df)

# Load
write_to_csv(df)
```

#### E-Commerce

This database was fine to just be created as is from the .sql file provided on GitHub as follows.

```bash
createdb ecommerce
psql ecommerce < ecommerce.sql
```

#### Flights

This database was also fine to just be created as is from the .sql file provided as follows (using the Postgres database as the script creates and connects to the demo database for creation):

```bash
gunzip demo-20250901-3m.sql.gz
psql postgres < demo-20250901-3m.sql
```
