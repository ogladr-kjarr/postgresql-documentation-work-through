CREATE TABLE trips(
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    vendor_id SMALLINT, 	
    tpep_pickup_datetime TIMESTAMP,
    tpep_dropoff_datetime TIMESTAMP,
    passenger_count	SMALLINT,
    trip_distance NUMERIC(8,2),
    ratecode_id	VARCHAR(100),
    store_and_fwd_flag VARCHAR(1),
    pu_location_id SMALLINT,	
    do_location_id SMALLINT,
    payment_type VARCHAR(100),
    fare_amount	NUMERIC(8,2),
    extra NUMERIC(8,2),
    mta_tax	NUMERIC(8,2),
    tip_amount NUMERIC(8,2),
    tolls_amount NUMERIC(8,2),
    improvement_surcharge NUMERIC(8,2),
    total_amount NUMERIC(8,2),
    congestion_surcharge NUMERIC(8,2),
    airport_fee	NUMERIC(8,2),
    cbd_congestion_fee NUMERIC(8,2)
);


COPY trips (
    vendor_id,
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    passenger_count,
    trip_distance,
    store_and_fwd_flag,
    pu_location_id,	
    do_location_id,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    airport_fee,
    cbd_congestion_fee,
    payment_type,
    ratecode_id)
FROM '/var/lib/postgresql/2025_yellow_cab_data.csv'
WITH (DELIMITER ',', 
    HEADER TRUE);
    