#!/bin/bash

CONFIG=$LIGHTSAILDIR/config.sh

if [ -z "$LIGHTSAILDIR" ]; then
        echo "No LIGHTSAILDIR specified";
        exit 255
fi

. $CONFIG

if [ -z "$DROPBOX_SYNC_SLACK_HOOK" ]; then
        echo "No slack hook specified";
        exit 254
fi

if [ -z "$DROPBOX_S3_URL" ]; then
        echo "No s3 url specified";
        exit 254
fi

SLACK_HOOK=$DROPBOX_SYNC_SLACK_HOOK
S3_URL=$DROPBOX_S3_URL

curl -X POST --data-urlencode "payload={\"text\": \"Starting daily Dropbox sync\"}" $SLACK_HOOK

/usr/bin/rclone sync dropbox: $S3_URL 
RET=$?

if [ "$RET" -eq "0" ]; then
	MESSAGE="Dropbox synced to S3."
else
	MESSAGE="Problem syncing Dropbox to S3."
fi

if [ ! -z "$MESSAGE" ]; then
	curl -X POST --data-urlencode "payload={\"text\": \"$MESSAGE\"}" $SLACK_HOOK
fi
