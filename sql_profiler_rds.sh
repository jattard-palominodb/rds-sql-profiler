# SQL Profiler for RDS
# PalominoDB 2012
# Author: James Attard [jattard@palominodb.com]
# File: sql_profiler_rds.sh
# Usage: sql_profiler_rds.sh <config file>

# Sample config file:
# ===================
# database to be reviewed:
# user=user1
# password=DELETED
# host=live-db.xxxxxxxxx.us-east-1.rds.amazonaws.com

# database holding review information:
# review_user=user2
# review_password=DELETED
# review_host=review-db.xxxxxxxxxx.us-east-1.rds.amazonaws.com
# review_schema=palomino

profiler_config=$1
. $profiler_config

email_to="jattard@palominodb.com"
review_server=`echo $host | awk -F"." '{print $1}'`
digest=pt-query-digest
slow_log=/mnt/slowlogs/

# download slow log
mysql --quick -u$user -p$password -h$host -D mysql -s -r -e "SELECT CONCAT( '# Time: ', DATE_FORMAT(start_time, '%y%m%d %H%i%s'), '\n', '# User@Host: ', user_host, '\n', '# Query_time: ', TIME_TO_SEC(query_time), ' Lock_time: ', TIME_TO_SEC(lock_time), ' Rows_sent: ', rows_sent, ' Rows_examined: ', rows_examined, '\n', sql_text, ';' ) FROM mysql.slow_log" > $slow_log/$review_server.log

# mark old entries as reviewed
mysql -u$review_user -p$review_password -h$review_host -D$review_schema -e "update profiler-queries-$review_server set reviewed_by='palomino' where reviewed_by is null;"

# review and report new top N entries
$digest --create-review-table --create-review-history-table --no-report --review h=$review_host,u=$review_user,p=$review_password,D=$review_schema,t=profiler-queries-$review_server --review-history D=$review_schema,t=profiler-histories-$review_server --limit 5 $slow_log/$review_server.log >/dev/null 2>&1

# same as above but send email
$digest --review-all --review h=$review_host,u=$review_user,p=$review_password,D=$review_schema,t=profiler-queries-$review_server --review-history D=$review_schema,t=profiler-histories-$review_server $slow_log/$review_server.log | mailx -s "SQL Profiler report for $review_server" $email_to

# rotate logs
mysql -u$user -p$password -h$host -e "CALL mysql.rds_rotate_slow_log"
