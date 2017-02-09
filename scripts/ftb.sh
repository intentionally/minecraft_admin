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

ftb_stop() {
  
}

case "$1" in
  quickstart)
    ftb_start
    ;;
  start)
    ftb_start_and_wait
    ;;
  stop)
    ;;
  reload)
    ;;
  restart)
    ;;
  backup)
    ;;
  status)
    ;;
  command)
    ;;
  *)
    echo "Usage: $0 {start|stop|reload|restart|backup|status|command [COMMAND]}"
    exit 1
    ;;
esac

exit 0
