#!/bin/bash

SERVERDIR='/srv/ftb'
HISTORY=1024
SERVICE="ftb"
USERNAME="ubuntu"
PIDFILE="/var/run/${SERVICE}.pid"

if [ ! -f "$SERVERDIR/settings.sh" ]; then
  echo "$SERVERDIR/settings.sh missing. Script failing."
  exit 1
fi

. $SERVERDIR/settings.sh

if [ -f "$SERVERDIR/local-settings.sh" ]; then
  . $SERVERDIR/local-settings.sh
fi

BASECMD="$JAVACMD -server -Xms${MIN_RAM} -Xmx${MAX_RAM} -XX:PermSize=${PERMGEN_SIZE} ${JAVA_PARAMETERS} -jar ${FORGEJAR} nogui"
FULLCMD="cd $SERVERDIR && screen -h $HISTORY -dmS $SERVICE $BASECMD"

as_user() {
  su - "$USERNAME" -c "$1"
}

mc_command() {
  as_user "screen -p 0 -S $SERVICE -X eval 'stuff \"$1\"\015'"
  echo "[MC-CMD] $1"
}

check_screen() {
  local SCREENPID=`cat /var/run/${SERVICE}.pid`

  if [ -z "$SCREENPID" ]; then
    return 1
  else
    return 0
  fi
}

check_java() {
  local JAVAPID=`pgrep -u $USERNAME -f $FORGEJAR`
  
  if [ -z "$JAVAPID" ]; then
    return 1
  else
    return 0
  fi
}

ftb_start() {
  if (check_java && ! check_screen) || (check_screen && ! check_java); then
    echo "Screen or Java is active without the other. Clean up and rerun."
    exit 1
  elif check_java && check_screen; then
    echo "$SERVICE is running"
  else
    echo "Starting $SERVICE..."
    cd $SERVERDIR
    as_user "$FULLCMD"
    if check_java && check_screen; then
      echo "$SERVICE started."
    else
      echo "[ERROR] $SERVICE not started."
    fi
  fi
}

ftb_start_and_wait() {
  local SLEEPINTERVAL=1
  local VTIMEOUT=180
  local ELAPSED=0

  if (check_java && ! check_screen) || (check_screen && ! check_java); then
    echo "Screen or Java is active without the other. Clean up and rerun."
    exit 1
  elif check_java && check_screen; then
    echo "$SERVICE is running"
  else
    echo "Starting $SERVICE..."
    cd $SERVERDIR
    as_user "$FULLCMD"
    printf "Starting: "
    while :; do
      for c in / - \\ \|; do
        printf "\b%s" "$c"
        if ! check_java; then
          printf "\n"
          printf "[ERROR] $ERVICE not started."
          exit 1
        fi
        if [ "$ELAPSED" -ge "$VTIMEOUT"]; then
          printf "\n$SERVICE started.\n"
          break 2
        fi
        sleep $SLEEPINTERVAL
        ELAPSED=$(( ELAPSED + SLEEPINTERVAL ))
      done
    done
  fi
}

ftb_stop_countdown() {
  local COUNT=30

  if check_java; then
    echo "Stopping $SERVICE..."
    echo "Announcing shutdown..."
    while [ "$COUNT" -gt 0 ]; do
      mc_command "say SHUTDOWN IN $COUNT SECONDS"
      if [[ "$COUNT" -ge 20 ]]; then
        COUNT=$(( COUNT - 10 ))
        sleep 10
      elif [[ "$COUNT" -eq 10 ]]; then
        COUNT=$(( COUNT - 5 ))
        sleep 5
      else
        COUNT=$(( COUNT - 1 ))
        mc_command "save-all"
        sleep 1
      fi
    done
    mc_command "stop"
    sleep 5
  fi
}

ftb_stop() {
  local COUNT=30
  local TMPPID=`cat /var/run/${SERVICE}.pid`

  ftb_stop_countdown
  if check_screen; then
    as_user "screen -S $SERVICE -X quit"
    rm /var/run/${SERVICE}.pid
  fi
  if check_java; then
    echo "[ERROR] Failed to stop $SERVICE java process."
    exit 1
  fi
}

ftb_reload() {
  local SLEEPINTERVAL=1
  local VTIMEOUT=180
  local ELAPSED=0
  
  if check_screen; then
    if check_java; then
      mc_command "say SERVER RESTART INITIATED"
      ftb_stop_countdown
    fi
    as_user "cd $SERVERDIR && screen -p 0 -S $SERVICE -X $BASECMD"
    printf "Starting: "
    while :; do
      for c in / - \\ \|; do
        printf "\b%s" "$c"
        if ! check_java; then
          printf "\n"
          printf "[ERROR] $ERVICE not started."
          exit 1
        fi
        if [ "$ELAPSED" -ge "$VTIMEOUT"]; then
          printf "\n$SERVICE started.\n"
          break 2
        fi
        sleep $SLEEPINTERVAL
        ELAPSED=$(( ELAPSED + SLEEPINTERVAL ))
      done
    done
  fi
}

case "$1" in
  quickstart)
    ftb_start
    ;;
  start)
    ftb_start_and_wait
    ;;
  stop)
    ftb_stop
    ;;
  reload)
    ftb_reload
    ;;
  restart)
    ftb_stop
    ftb_start_and_wait
    ;;
  quickrestart)
    ftb_stop
    ftb_start
    ;;
  backup)
    if check_java; then
      mc_command "backup start"
    else
      echo "[ERROR] $SERVICE Java process is not running"
    fi
    ;;
  status)
    if check_java; then
      echo "$SERVICE Java process is running"
    else
      echo "$SERVICE Java process is not running"
    fi
    if check_screen; then
      echo "$SERVICE screen is running"
    else
      echo "$SERVICE screen is not running"
    fi
    ;;
  command)
    if [ "$#" -gt 1 ]; then
      if check_java; then
        shift
        mc_command "$*"
      else
        echo "[ERROR] $SERVICE Java process is not running"
        exit 1
      fi
    else
      echo "[ERROR] No commnad given"
      exit 1
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|reload|restart|backup|status|command [COMMAND]}"
    exit 1
    ;;
esac

exit 0
