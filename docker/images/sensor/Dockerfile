FROM python:3.15.2-trixie

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY sensor_readings.py ./

CMD ["python", "./sensor_readings.py"]