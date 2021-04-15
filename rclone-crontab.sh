#!/bin/bash
set -e
if [ ! $# -eq 1 ]
then
        echo
        echo "Error: Arguments missing"
        echo
        exit 1
else
        FOLDER=$1
fi
#echo $FOLDER
SCRIPTDIR="/etc/rclone-crontab"
SADIR="$SCRIPTDIR/sa"
LOGDIR="/var/log/rclone"
DATETIME="`date +%Y-%m-%d_%H-%M-%S`"
LOGFILE="$LOGDIR/$FOLDER-$DATETIME.log"
LOGCHECK="$LOGDIR/check-$FOLDER-$DATETIME.txt"
LOGDEDUP="$LOGDIR/dedupe-$FOLDER-$DATETIME.txt"
OPTION="
  --fast-list \
  --transfers=16 \
  --checkers=32 \
  -vP \
  --ignore-errors \
  --stats=30s \
  --max-backlog=2000000 \
  --ignore-case \
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
# Check duplicated file
rclone dedupe "td-$FOLDER-bck:0/" \
        --drive-service-account-file="$SADIR/$FOLDER.json" \
        --dedupe-mode oldest \
        2>&1 | tee $LOGDEDUP
#
# Running Rclone
echo
echo "Running rclone sync:"
rclone $OPTION sync "td-$FOLDER:" "td-$FOLDER-bck:0/" \
        --stats 360m \
        --backup-dir="td-$FOLDER-bck:$DATETIME/" \
        --stats-log-level NOTICE \
        --drive-service-account-file="$SADIR/$FOLDER.json" \
        2>&1 | tee $LOGFILE
#
# Running check and alert
echo "Running rclone check:"
rclone check "td-$FOLDER:" "td-$FOLDER-bck:0/" \
        --drive-service-account-file="$SADIR/$FOLDER.json" \
        --log-level=ERROR \
        2>&1 | tee $LOGCHECK
        
if [ -s "$LOGCHECK" ] 
then
        echo "Backup with error"
        apprise -vv -t ""$FOLDER" error" \
        -b "Backup "$FOLDER" with error" \
        --attach $LOGDEDUP
        --attach $LOGFILE
        --attach $LOGCHECK
else
        echo "Backup Successful"
fi
