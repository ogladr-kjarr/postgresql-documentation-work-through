CREATE TABLE sensor_readings (
    reading_instant TIMESTAMP WITH TIME ZONE,
    site TEXT,
    sensor TEXT,
    reading NUMERIC(8, 3),
    PRIMARY KEY (reading_instant, site, sensor)
);

