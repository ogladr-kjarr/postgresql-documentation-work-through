FROM postgres:18-alpine3.23
COPY --chown=postgres:postgres postgresql.conf /usr/local/share/postgresql/postgresql.conf.sample
COPY sensors.sql /docker-entrypoint-initdb.d/

RUN mkdir -p /mnt/server/archivedir && chown -R postgres:postgres /mnt/server/archivedir/
RUN mkdir -p /mnt/server/base-backup && chown -R 70:70  /mnt/server/base-backup

