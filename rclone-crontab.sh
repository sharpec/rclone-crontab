!/bin/bash
set -e
if [ ! $# -eq 1 ]
then
	echo
	cecho "Error: Arguments missing"
	echo
	exit 1
else
	FOLDER=$1
fi
#echo $FOLDER
SCRIPTDIR="/etc/rclone-crontab"
SADIR="$SCRIPTDIR/sa"
LOGDIR="/var/log/rclone"
LOGFILE="$LOGDIR/$FOLDER-$DATETIME.log"
DATETIME="`date +%Y%m%d_%H%M%S`"
OPTION="
  --fast-list \
  --transfers=16 \
  --checkers=32 \
  -vP \
  --ignore-errors \
  --stats=30s \
  --max-backlog=2000000 \
  --ignore-case \
  --size-only \
  --no-update-modtime \
  --drive-chunk-size=256M \
  --use-mmap \
  --drive-server-side-across-configs=true \
  --drive-stop-on-upload-limit \
  --timeout=10s \
  --tpslimit=4 \
  --tpslimit-burst=20 \
  "
#   --track-renames \
mkdir -p $LOGDIR
mkdir -p $SADIR
#
# Running Rclone
echo
echo "Running rclone sync:"
rclone $OPTION sync "td-$FOLDER:" "td-$FOLDER-bck:0/" \
        --stats 360m \
        --backup-dir="td-$FOLDER-bck:$DATETIME/" \
        --stats-log-level NOTICE \
        --drive-service-account-file="$SADIR/$FOLDER.json"
        2>&1 | tee $LOGFILE
