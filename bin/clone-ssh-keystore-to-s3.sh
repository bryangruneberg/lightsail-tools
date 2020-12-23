#!/bin/bash

CONFIG=$LIGHTSAILDIR/config.sh

if [ -z "$LIGHTSAILDIR" ]; then
        echo "No LIGHTSAILDIR specified";
        exit 255
fi

. $CONFIG

if [ -z "$SSH_SYNC_SLACK_HOOK" ]; then
        echo "No slack hook specified";
        exit 254
fi

if [ -z "$SSH_S3_URL" ]; then
        echo "No s3 url specified";
        exit 254
fi

if [ -z "$SSH_KEYSTORE_DIR" ]; then
        echo "No ssh keystore specified";
        exit 254
fi

SLACK_HOOK=$SSH_SYNC_SLACK_HOOK
S3_URL=$SSH_S3_URL

curl -X POST --data-urlencode "payload={\"text\": \"Starting daily SSH keystore sync\"}" $SLACK_HOOK

/usr/bin/rclone sync $SSH_KEYSTORE_DIR $S3_URL 
RET=$?

if [ "$RET" -eq "0" ]; then
	MESSAGE="SSH keystore synced to S3."
else
	MESSAGE="Problem syncing SSH keystore to S3."
fi

if [ ! -z "$MESSAGE" ]; then
	curl -X POST --data-urlencode "payload={\"text\": \"$MESSAGE\"}" $SLACK_HOOK
fi
