# (optional) You might need to set your PATH variable at the top here
# depending on how you run this script
#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Hosted Zone ID e.g. BJBK35SKMM9OE
ZONEID="SOMEZONE"

# The CNAME you want to update e.g. hello.example.com
RECORDSET="something.example.com"

# Dropbox Sync
DROPBOX_SYNC_SLACK_HOOK="https://hooks.slack.com/services/T123123/B123123/something"
DROPBOX_S3_URL="s3:/some-bucket/"

# ssh Sync
SSH_SYNC_SLACK_HOOK="https://hooks.slack.com/services/T123123/B123123/something"
SSH_S3_URL="s3:/some-bucket/"
SSH_KEYSTORE_DIR="/home/ubuntu/ssh-key-store"
