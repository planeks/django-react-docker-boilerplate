## Backup script

Configure the backup script to make regular backups of the database. You can call it `backup.sh` and put it to 
the `/home/appuser` directory.

Create the directory for backups:

```bash
$ mkdir /home/appuser/backups
```

The idea is to make a database dump, add the project files including the `.env` file and `media` directory to the archive.
Those archives will be stored locally to the `backups` directory. The script will remove the local archives older than 5 days.
We also strongly recommend to store the archives on the remote storage. 
You can use AWS S3 or DigitalOcean Spaces. You can use the `s3cmd` utility for that. Install it with the following command:

```bash
$ sudo apt install s3cmd
```

Configure the `s3cmd` utility with the following command:

```bash
$ s3cmd --configure
```

The `backup.sh` script should contain the next code:

```bash
#!/bin/bash
TIME_SUFFIX=`date +%Y-%m-%d:%H:%M:%S`
cd /home/appuser/projects/newprojectname
docker compose -f compose.prod.yml exec -T postgres backup
DB_DUMP_NAME=`docker compose -f compose.prod.yml exec -T postgres backups | head -n 3 | tail -n 1 | tr -s ' ' '\n' | tail -1`
docker cp newprojectname_postgres_1:/backups/$DB_DUMP_NAME /home/appuser/backups/
tar --exclude='media/thumbs' -zcvf /home/appuser/backups/newprojectname-$TIME_SUFFIX.tar.gz /home/appuser/projects/newprojectname/data/prod/media /home/appuser/projects/newprojectname/.env /home/appuser/projects/newprojectname/src /home/appuser/backups/$DB_DUMP_NAME
s3cmd put /home/appuser/backups/newprojectname-$TIME_SUFFIX.tar.gz s3://newprojectname-backups/staging/
find /home/appuser/backups/*.gz -mtime +5 -exec rm {} \;
docker compose -f compose.prod.yml exec -T postgres cleanup 7
```

📌 Modify the script according to the project needs. Check the directories and file names.

Try to run the script manually and than add it to the `crontab` to run it regularly.

```bash
$ sudo crontab -e
```

Add the next line

```bash
0 1 * * *       /home/appuser/backup.sh >> /home/appuser/backup.log 2>&1
```

## Restore project from backup

First, you need to unzip the archive for the particular date. If the archive is stored on the remote storage you need to download it first.

Than, if you need to restore source code, `.env` or `media` files you can just copy them to the proper directories.

If you need to restore the database you need to do the following steps.

Copy the database dump to the `backups` directory:

```bash
$ docker cp <dump_name> newprojectname_postgres_1:/backups/
```

Stop the app containers that are using the database (`django`, `celeryworker`, etc.)

```bash
$ docker compose -f compose.prod.yml stop django celeryworker
``` 

Restore the database:

```bash
$ docker compose -f compose.prod.yml exec -T postgres restore <dump_name>
```

Run the app containers again:

```bash
$ docker compose -f compose.prod.yml up -d django celeryworker
```

## Cleaning Docker data

Also, you can setup the Cron jobs to schedule cleaning unnecessary Docker data.

```bash
$ sudo crontab -e
```

Add the next lines

```bash
0 2 * * *       docker system prune -f >> /home/appuser/docker_prune.log 2>&1
```