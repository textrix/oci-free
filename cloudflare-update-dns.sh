#!/bin/bash

# ./oci-free PROFILE ip-list | awk -F, '{ print $2 " " $3 }' | xargs -L1 ./cloudflare-update-dns.sh

AUTH_EMAIL=example@example.com
API_KEY=CF_Authorization_key
ZONE_ID=CF_Zone_ID

source ".cloudflare-update-dns.conf"

#echo $AUTH_EMAIL
#echo $AUTH_KEY
#echo $ZONE_ID

A_RECORD_NAME=$1
PUBLIC_IP=$2
A_RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$A_RECORD_NAME" \
	     -H "Host: api.cloudflare.com" \
	          -H "User-Agent: ddclient/3.9.0" \
		       -H "Connection: close" \
     -H "X-Auth-Email: $AUTH_EMAIL" \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json")
echo $A_RECORD_ID

# Record the new public IP address on Cloudflare using API v4
RECORD=$(cat <<EOF
{ "type": "A",
  "name": "$A_RECORD_NAME",
  "content": "$PUBLIC_IP",
  "ttl": 180,
  "proxied": false }
EOF
)
curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$A_RECORD_ID" \
     -X PUT \
     -H "Content-Type: application/json" \
     -H "X-Auth-Email: $AUTH_EMAIL" \
     -H "Authorization: Bearer $API_KEY" \
     -d "$RECORD"
