#!/bin/bash

# ./oci-free PROFILE ip-list | xargs -P8 -L1 ./cloudflare-update-dns.sh
# ./oci-free PROFILE ipv6-list | xargs -P8 -L1 ./cloudflare-update-dns.sh

DOMAIN=somewhere.com
AUTH_EMAIL=example@example.com
API_KEY=CF_Authorization_key
ZONE_ID=CF_Zone_ID

source ".cloudflare-update-dns.conf"

RECORD_TYPE=$1
RECORD_NAME=$2
PUBLIC_IP=$3

BASE_URI="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records"
GET_ID_URI="$BASE_URI?type=$RECORD_TYPE&name=$RECORD_NAME.$DOMAIN"
HEADERS=(-H "Content-Type: application/json" \
	-H "X-Auth-Email: $AUTH_EMAIL" \
	-H "Authorization: Bearer $API_KEY")
RECORD_DATA=$(cat <<EOF
{ "type": "$RECORD_TYPE",
  "name": "$RECORD_NAME",
  "content": "$PUBLIC_IP",
  "ttl": 180,
  "proxied": false }
EOF
)

RECORD_ID=$(curl -s -X GET "$GET_ID_URI" "${HEADERS[@]}" | jq -r '{"result"}[] | .[0] | .id')

# create record if not exist
if [ "$RECORD_ID" == "null" ]; then
	RECORD_ID=$(curl -s -X POST "$BASE_URI" "${HEADERS[@]}" -d "$RECORD_DATA" | jq -r '.result.id')
fi

ID_URI="$BASE_URI/$RECORD_ID"
RESULT=$(curl -s -X PUT "$ID_URI" "${HEADERS[@]}" -d "$RECORD_DATA" | jq -r '.result.content')

echo $RECORD_TYPE $RECORD_NAME $PUBLIC_IP $RESULT

