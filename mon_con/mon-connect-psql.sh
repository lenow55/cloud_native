#/bin/bash

TIMESTAMP=`date`
echo -e "[$TIMESTAMP]: start mon psql connections\n"

SUMM=""
while true; do
    TIMESTAMP=`date`
    RESULT=`psql -c "SELECT * FROM pg_stat_activity WHERE NOT application_name='psql';"`
    SUMM2=`echo -n $RESULT |  md5sum`
    if [ "$SUMM" != "$SUMM2" ]; then
        echo -e "[$TIMESTAMP]: check psql connections\n$RESULT"
    fi
    SUMM=$SUMM2
    sleep 1
done
