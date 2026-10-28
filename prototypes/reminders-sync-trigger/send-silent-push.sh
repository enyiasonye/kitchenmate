#!/bin/sh
# PROTOTYPE — throwaway. Sends one silent push to the Sync Probe app (TestFlight = production APNs).
# Needs an APNs auth key (.p8) from developer.apple.com → Keys, with Apple Push Notifications enabled.
#   APNS_KEY=~/AuthKey_XXXX.p8 APNS_KEY_ID=XXXX DEVICE_TOKEN=<from "Copy push token"> ./send-silent-push.sh
set -eu
TEAM=2XF9ZJU79J
TOPIC=com.roehaus.prototype.SyncTriggerProbe
b64() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
header=$(printf '{"alg":"ES256","kid":"%s"}' "$APNS_KEY_ID" | b64)
claims=$(printf '{"iss":"%s","iat":%s}' "$TEAM" "$(date +%s)" | b64)
# openssl emits a DER signature; APNs wants raw r||s.
sig=$(printf '%s.%s' "$header" "$claims" | openssl dgst -sha256 -sign "$APNS_KEY" | openssl asn1parse -inform DER \
  | awk -F: '/INTEGER/ {h=$NF; while (length(h) < 64) h = "0" h; printf "%s", substr(h, length(h) - 63)}' | xxd -r -p | b64)
curl -sS --http2 -w '\nHTTP %{http_code}\n' \
  -H "authorization: bearer $header.$claims.$sig" \
  -H "apns-topic: $TOPIC" -H "apns-push-type: background" -H "apns-priority: 5" \
  -d '{"aps":{"content-available":1}}' \
  "https://api.push.apple.com/3/device/$DEVICE_TOKEN"
