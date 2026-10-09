--- Initial table 

CREATE TABLE trips(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    fare_amount	NUMERIC(8,2) NOT NULL CONSTRAINT positive_fare CHECK (fare_amount > 0),
    extra NUMERIC(8,2),
    mta_tax	NUMERIC(8,2),
    tip_amount NUMERIC(8,2),
    tolls_amount NUMERIC(8,2),
    improvement_surcharge NUMERIC(8,2),
    total_amount NUMERIC(8,2),
    congestion_surcharge NUMERIC(8,2),
    airport_fee	NUMERIC(8,2),
    cbd_congestion_fee NUMERIC(8,2),
    extra_fees NUMERIC(8,2) GENERATED ALWAYS AS (extra + 
                                                 mta_tax + 
                                                 tolls_amount + 
                                                 improvement_surcharge + 
                                                 congestion_surcharge +
                                                 airport_fee +
                                                 cbd_congestion_fee ) STORED,
    CONSTRAINT total_amount_gte_fare_amount CHECK (total_amount >= fare_amount)
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
        

--- Partitioning tables

CREATE TABLE par_trips (
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
    fare_amount	NUMERIC(8,2) NOT NULL CONSTRAINT positive_fare CHECK (fare_amount > 0),
    extra NUMERIC(8,2),
    mta_tax	NUMERIC(8,2),
    tip_amount NUMERIC(8,2),
    tolls_amount NUMERIC(8,2),
    improvement_surcharge NUMERIC(8,2),
    total_amount NUMERIC(8,2),
    congestion_surcharge NUMERIC(8,2),
    airport_fee	NUMERIC(8,2),
    cbd_congestion_fee NUMERIC(8,2),
    extra_fees NUMERIC(8,2) GENERATED ALWAYS AS (extra + 
                                                 mta_tax + 
                                                 tolls_amount + 
                                                 improvement_surcharge + 
                                                 congestion_surcharge +
                                                 airport_fee +
                                                 cbd_congestion_fee ) STORED,
    CONSTRAINT total_amount_gte_fare_amount CHECK (total_amount >= fare_amount),
    PRIMARY KEY(id, tpep_pickup_datetime)
) PARTITION BY RANGE (tpep_pickup_datetime);

CREATE INDEX ON par_trips (tpep_pickup_datetime);

CREATE TABLE par_trips_y2025m06 PARTITION OF par_trips
    FOR VALUES FROM ('2025-06-01 00:00:00') TO ('2025-07-01 00:00:00');

CREATE TABLE par_trips_y2025m07 PARTITION OF par_trips
    FOR VALUES FROM ('2025-07-01 00:00:00') TO ('2025-08-01 00:00:00');

CREATE TABLE par_trips_y2025m08 PARTITION OF par_trips
    FOR VALUES FROM ('2025-08-01 00:00:00') TO ('2025-09-01 00:00:00');

COPY par_trips (
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