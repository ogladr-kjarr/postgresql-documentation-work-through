from datetime import datetime
import psycopg2
import random
import time
from zoneinfo import ZoneInfo

# Connection details
host = "main-db"
database = "sensors"
user = "postgres"
password = "postgres"

# Static data
site = "Shap"
sensor = "Temperature_One"

while True:

    # Delay sending a reading
    time.sleep(5)

    # Connect to the database
    conn = psycopg2.connect(
        host=host,
        database=database,
        user=user,
        password=password
    )
    cur = conn.cursor()

    instant = datetime.now(ZoneInfo("Europe/London"))
    current_reading = random.randint(-15, 38)

    cur.execute("INSERT INTO sensor_readings (reading_instant, site, sensor, reading) VALUES (%s, %s, %s, %s)", 
        (instant.isoformat(), site, sensor, current_reading))
    conn.commit()

    cur.close()
    conn.close()

