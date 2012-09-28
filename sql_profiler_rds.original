#SQL Profiler for RDS
#PalominoDB 2012

#Usage: sql_profiler_rds.sh <config file>

#Sample config file:
#user=user1
#password=DELETED
#host=live-db.xxxxxxxxx.us-east-1.rds.amazonaws.com
#slow_log=/mnt/slowlogs/db.slow

#review_user=user2
#review password=DELETED
#review_host=review-db.xxxxxxxxxx.us-east-1.rds.amazonaws.com
#review_schema=palomino

email_to=jattard@palominodb.com
review_server=`echo $review_host | awk -F"." '{print $1}'`

profiler_config=$1
. $profiler_config

digest=/mnt/slowlogs/pt-query-digest

mysql --quick -u$user -p$password -h$host -D mysql -s -r -e "SELECT CONCAT( '# Time: ', DATE_FORMAT(start_time, '%y%m%d %H%i%s'), '\n', '# User@Host: ', user_host, '\n', '# Query_time: ', TIME_TO_SEC(query_time), ' Lock_time: ', TIME_TO_SEC(lock_time), ' Rows_sent: ', rows_sent, ' Rows_examined: ', rows_examined, '\n', sql_text, ';' ) FROM mysql.slow_log" > $slow_log

# store each node on a separate query_review_table
# update sql_profiler_queries set reviewed_by='palomino' where reviewed_by is null;

# parse
$digest --create-review-table --create-review-history-table --no-report --review h=$review_host,u=$review_user,p=$review_password,D=$review_schema,t=sql_profiler_queries --review-history D=$review_schema,t=sql_profiler_histories --limit 5 $slow_log >/dev/null 2>&1

# parse and email
$digest --review h=$review_host,u=$review_user,p=$review_password,D=$review_schema,t=sql_profiler_queries --review-history D=$review_schema,t=sql_profiler_histories $slow_log | mail -s "SQLProfiler report for $review_server" $email_to


