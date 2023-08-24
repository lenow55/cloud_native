#!/bin/bash
## помещается база в буфер?
# 0 - нет
# 1 - да
mem_type=$1
## кэш запросов
# 0 - нет
# 1 - да
cache_type=$2
# количество клиентских подключений
clients=$3
# длительность тестирования
period=$4
# размерность бд
scale=$5
# с какого теста продолжить
# ввести номер цикла
start_cnt=$6
# до какого теста работать
# ввести номер цикла
end_cnt=$7
# активность pgpool
# 0 - нет
# 1 - да
declare -a pgpool=(
"0"
"1")

# Количество соединений
declare -a connections=(
"50"
"100"
"200"
"300")
# процент на запись
declare -a insertVselect=(
"50"
"25"
"5"
"0")
# сложность запросов
declare -a queryCost=(
"0"
"1000"
"5000")

function make_script {
    local path_script=$1
    local cost=$2
    local iVs=$3
    echo "\set ntellers 10 * :scale" >> $path_script
    echo "\set nbranches :scale" >> $path_script
    echo "\set naccounts 100000 * :scale - $cost" >> $path_script
    echo "\set aid    random(1,:naccounts)" >> $path_script
    if [ "$iVs" = "0" ]; then
        echo "BEGIN;" >> $path_script
        if [ "$cost" = "0" ]; then
            echo "SELECT abalance FROM pgbench_accounts WHERE aid = :aid;" >> $path_script
        else
            echo "SELECT" >> $path_script
            echo "  COUNT(*)" >> $path_script
            echo "FROM" >> $path_script
            echo "  pgbench_accounts" >> $path_script
            echo "  INNER JOIN pgbench_branches" >> $path_script
            echo "  ON pgbench_accounts.bid = pgbench_branches.bid" >> $path_script
            echo "WHERE pgbench_accounts.aid>=:aid AND pgbench_accounts.aid<=:aid+$cost;" >> $path_script
        fi
    else
        echo "\set bid    random(1,:nbranches)" >> $path_script
        echo "\set tid    random(1,:ntellers)" >> $path_script
        echo "\set delta  random(-5000,5000)" >> $path_script
        echo "\set choice random(-100,100)" >> $path_script
        echo "BEGIN;" >> $path_script
        echo "\if :choice <= $((iVs * 2))" >> $path_script
        if [ "$cost" = "0" ]; then
            echo "  INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);" >> $path_script
            echo "\else" >> $path_script
            echo "  SELECT abalance FROM pgbench_accounts WHERE aid = :aid;" >> $path_script
        else
            echo "  INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);" >> $path_script
            echo "\else" >> $path_script
            echo "SELECT" >> $path_script
            echo "  COUNT(*)" >> $path_script
            echo "FROM" >> $path_script
            echo "  pgbench_accounts" >> $path_script
            echo "  INNER JOIN pgbench_branches" >> $path_script
            echo "  ON pgbench_accounts.bid = pgbench_branches.bid" >> $path_script
            echo "WHERE pgbench_accounts.aid>=:aid AND pgbench_accounts.aid<=:aid+$cost;" >> $path_script
        fi
        echo "\endif" >> $path_script
    fi
    echo "END;" >> $path_script
    return
}

extension="txt"
TIMESTAMP=`date +"%Y%m%d_%H%M%S"`
folder_path=$(dirname "$0")/"$TIMESTAMP"
mkdir "$folder_path"

counter=0
start_datetime=""
end_datetime=""

## now loop through the above array
for pool in "${pgpool[@]}"
do
    host=""
    port=""
    if [ "$pool" = "0" ]; then
        host="cluster-example-rw"
        port=5432
    else
        host="pgpool"
        port=9999
    fi
    for cost in "${queryCost[@]}"
    do
        for iVs in "${insertVselect[@]}"
        do
            SUB_SCRIPT=$(mktemp --suffix=.sql)
            echo "\set scale $scale" >> $SUB_SCRIPT
            make_script $SUB_SCRIPT $cost $iVs
            for connection in "${connections[@]}"
            do
                counter=$((counter + 1))
                if [ "$counter" -lt "$start_cnt" ]; then
                    continue
                fi
                echo "TEST_NUMBER: $counter"
                filename="$folder_path/$counter.$extension"
                jsonname="$folder_path/$counter.json"
                touch $filename
                touch $jsonname
                start_datetime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                echo "TIMESTAMP: $start_datetime" >> $filename
                echo "TEST_NUMBER: $counter" >> $filename
                echo "COST: $cost" >> $filename
                echo "SCALE: $scale" >> $filename
                echo "PERCENT_WRITE: $iVs" >> $filename
                echo "POOL: $pool" >> $filename
                echo "COUNT_CONNECTIONS: $connection" >> $filename
                echo "QUERY_CACHE: $cache_type" >> $filename
                echo "BASE_SIZE: $mem_type" >> $filename
                echo "pgbench --host $host -p $port -U app -c $connection -j $clients -T $period -P 10 -r -f $SUB_SCRIPT app" >> $filename
                benchmark_result=$(pgbench --host "$host" -p $port -U app -c $connection -j $clients -T $period -P 10 -r -f $SUB_SCRIPT app 2>&1)
                echo -e "$benchmark_result" >> $filename
                if echo "$benchmark_result" | grep -q "pgbench: error:"; then
                    echo "Pgbench: Error"
                    exit 1
                fi
                if echo "$benchmark_result" | grep -q "WARNING:  memcache: updating free space"; then
                    echo "Pgpool: Error mem"
                    exit 1
                fi
                cat $SUB_SCRIPT >> $filename
                check_repl=$( PGPASSWORD=$ROOT_GPPASSWORD psql --host cluster-example-rw -U postgres -x -c "
                select
                    client_addr as client, usename as user, application_name as name,
                    state, sync_state as mode,
                    (pg_wal_lsn_diff(pg_current_wal_lsn(),sent_lsn) / 1024)::int as pending,
                    (pg_wal_lsn_diff(sent_lsn,write_lsn) / 1024)::int as write,
                    (pg_wal_lsn_diff(write_lsn,flush_lsn) / 1024)::int as flush,
                    (pg_wal_lsn_diff(flush_lsn, replay_lsn) / 1024)::int as replay,
                    (pg_wal_lsn_diff(pg_current_wal_lsn(),replay_lsn)::int / 1024) as total_lag
                    from pg_stat_replication;
                    "
                )
                line_count=$(echo "$check_repl" | wc -l)
                if [ "$line_count" = "1" ]; then
                    echo "Replication Fail"
                    exit 1
                else
                    echo "Healthy State"
                fi
                check_pool=$(psql --host pgpool -p 9999 -U app -c "SELECT * FROM pg_stat_activity WHERE NOT application_name='psql';")
                line_count_pool=$(echo "$check_pool" | wc -l)
                if [ "$line_count_pool" = "1" ]; then
                    echo "Pool Fail"
                    exit 1
                else
                    echo "Healthy State Pool"
                fi
                sleep 5
                end_datetime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                query="node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{namespace=~\"default\",container=\"postgres\"}"
                step="10s"
                url='http://prometheus-community-kube-prometheus.default.svc:9090/api/v1/query_range?query='"$query"'&start='"$start_datetime"'&end='"$end_datetime"'&step='"$step"
                load_prom_res=$(curl -g "$url")
                echo -e "$load_prom_res" >> $jsonname
                if [ "$counter" -eq "$end_cnt" ]; then
                    exit
                fi
            done
        done
    done
done


