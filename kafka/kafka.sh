#! /bin/bash

### BEGIN INIT INFO
# Provides:  kafka
# Required-Start:
# Required-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: kafka service
### END INIT INFO

KNAME="kafka"
KCMD="/export/kafka/current/bin/kafka-server-start.sh /export/kafka/current/config/server.properties"
KPIDFILE="/var/run/$KNAME.pid"
KLOGFILE="/var/log/$KNAME.log"

KUSER="kafka"
KAFKA_HEAP_OPTS="-Xmx4G -Xms4G"
export KAFKA_HEAP_OPTS

recursiveKill() { # Recursively kill a process and all subprocesses
  CPIDS=$(pgrep -P $1);
  for PID in $CPIDS
  do
    recursiveKill $PID
  done
  sleep 3 && kill -9 $1 2>/dev/null & # hard kill after 3 seconds
  kill $1 2>/dev/null # try soft kill first
}

function kstart {
  echo "Starting $KNAME ..."
  ulimit -n 65536
  ulimit -s 10240
  ulimit -c unlimited
  if [ -f "$KPIDFILE" ]; then
    echo "Already running according to $KPIDFILE"
    exit 1
  else
    /bin/su "$KUSER" -m -c "$KCMD" > $KLOGFILE 2>&1 &
    PID=$!
    echo $PID > $KPIDFILE
    echo "Started $KNAME with pid $PID - Logging to $KLOGFILE"
  fi
}

function kstop {
  echo "Stopping $KNAME ..."
  if [ ! -f $KPIDFILE ]; then
    echo "Already stopped!"
  else
    PID=`cat $KPIDFILE`
    recursiveKill $PID
    rm -f $KPIDFILE
    echo "Stopped $KNAME"
  fi
}

function kstatus {
  if [ -f "$KPIDFILE" ]; then
    PID=`cat $KPIDFILE`
    if [ "$(/bin/ps --no-headers -p $PID)" ]; then
      echo "$KNAME is running (pid : $PID)"
    else
      echo "Pid $PID found in $KPIDFILE, but not running."
    fi
  else
    echo "$KNAME is NOT running"
  fi
}

case "$1" in
  start)
    kstart
    ;;
  stop)
    kstop
    ;;
  restart)
    $0 stop
    sleep 3
    $0 start
    ;;
  status)
    kstatus
    ;;
  *)
    echo "Usage: /etc/init.d/kafka {start|stop|restart|status}" && exit 1
    ;;
esac
