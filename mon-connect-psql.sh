#/bin/bash

TIMESTAMP=`date`
echo "[$TIMESTAMP]: start mon psql connections"

while true; do
    TIMESTAMP=`date`
    echo "[$TIMESTAMP]: check psql connections\n"
    psql -c 'SELECT * FROM pg_stat_activity;'
    sleep 1
done
