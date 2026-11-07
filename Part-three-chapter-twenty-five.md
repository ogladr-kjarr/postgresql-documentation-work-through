# PostgreSQL Walkthrough - Part Three

## PostgreSQL Documentation Chapter Twenty Three: Backup and Restore

### 25.3

#### Main Server

The first instruction to setting up a server for continuous archiving, to allow a backup to be created, which archived WAL files will be replayed over, is to modify the `postgresql.conf` file.

```
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /mnt/server/archivedir/%f && cp %p /mnt/server/archivedir/%f'

# Set to create a WAL every 60 seconds, as without it the database would not process enough
# inserts to create WALs for this test.
archive_timeout = 60

# For this test I set the min WAL file size to 32MG, down from 80MB. I wanted to set it lower
# but it must be at least double the wal_segment_size which is 16MB.
min_wal_size = 32MB
```

Before taking a base backup, execute the command `select pg_switch_wal()` to switch to a new WAL file.

```
pg_basebackup -D /mnt/server/base-backup/ -F p -X n -v
```


#### Standby Server

Modify the `postgresql.conf` file with the following.

```
restore_command = 'cp /mnt/server/archivedir/%f %p'	
```