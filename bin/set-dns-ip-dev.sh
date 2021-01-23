#!/bin/bash

# To automate, add a cron:
# * * * * * (~/bin/set-dns-ip.sh) 2>&1 | logger

CONFIG=$LIGHTSAILDIR/config.sh

if [ -z "$LIGHTSAILDIR" ]; then
	echo "No LIGHTSAILDIR specified";
	exit 255
fi

. $CONFIG

if [ -z "$ZONEID" ]; then
	echo "No ZONEID specified";
	exit 254
fi

RECORDSET=$1

if [ -z "$RECORDSET" ]; then
	echo "No RECORDSET specified";
	exit 253
fi

DEVICE=$2

if [ -z "$DEVICE" ]; then
	echo "No DEVICE specified";
	exit 253
fi

# More advanced options below
# The Time-To-Live of this recordset
TTL=60
# Change this if you want
COMMENT="Auto updating @ `date`"
# Change to AAAA if using an IPv6 address
TYPE="A"

# Get the external IP address from OpenDNS (more reliable than other providers)
if [ -f /sbin/ifconfig ]; then 
	IP=`/sbin/ifconfig $DEVICE | grep "inet " | awk '{print $2}' 2>/dev/null`
else
	IP=`/sbin/ip -br addr | grep -e "^$DEVICE" | awk '{print $3}' | awk -F "/" '{print $1}' 2>/dev/null`
fi 

if [ -z "$IP" ]; then
  echo "No IP is set :("
  exit 123
fi

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Get current dir
# (from http://stackoverflow.com/a/246128/920350)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IPFILE="/tmp/update-route53-$DEVICE.ip"

if ! valid_ip $IP; then
    echo "Invalid IP address: $IP" 2>&1 | logger
    exit 1
fi

# Check if the IP has changed
if [ ! -f "$IPFILE" ]
    then
    touch "$IPFILE"
fi

if grep -Fxq "$IP" "$IPFILE"; then
    # code if found
    echo "IP $DEVICE is still $IP" 2>&1 | logger
    exit 0
else
    echo "IP $DEVICE has changed to $IP" 2>&1 | logger
    # Fill a temp file with valid JSON
    TMPFILE=$(mktemp /tmp/temporary-file.XXXXXXXX)
    cat > ${TMPFILE} << EOF
    {
      "Comment":"$COMMENT",
      "Changes":[
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value":"$IP"
              }
            ],
            "Name":"$RECORDSET",
            "Type":"$TYPE",
            "TTL":$TTL
          }
        }
      ]
    }
EOF

    # Update the Hosted Zone record
    aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONEID \
        --change-batch file://"$TMPFILE" 2>&1 | logger

    # Clean up
    rm $TMPFILE
fi

# All Done - cache the IP address for next time
echo "$IP" > "$IPFILE"
