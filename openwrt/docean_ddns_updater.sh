#!/bin/sh

# Copyright (c) 2016 Jeff Schornick <code@schornick.org>
# Licensed under the MIT License
# http://www.opensource.org/licenses/mit-license.php

# Notes:
#
# With Openwrt, the real wget package must be installed
# (busybox doesn't support SSL)

. $(dirname $0)/docean_dns_lib.sh

# Configuration is in /etc/config/ddns
DOMAIN=$(uci get ddns.digitalocean.domain)
HOSTNAME=$(uci get ddns.digitalocean.resource)
API_TOKEN=$(uci get ddns.digitalocean.api_key)

STATE_FILE=/var/state/docean_ddns.$HOSTNAME.$DOMAIN

# Openwrt doesn't have the root certs to verify the remote cert,
# so override the library's default WGET to skip the check
WGET="wget -q -O- --no-check-certificate"

IFACE=$(uci get network.wan.ifname)
WAN_IP=$(ifconfig $IFACE | awk '/inet/ {print $2}' | sed 's/addr://')

echo WAN interface IP: $WAN_IP

if [ -f $STATE_FILE ]; then
  LAST_IP=$(cat $STATE_FILE)
  echo State file: $LAST_IP
fi

if [ "$LAST_IP" = "$WAN_IP" ]; then
  echo "Skipping update"
  echo
  exit 0
fi

echo -n "Polling Digital Ocean DNS API... "
DOCEAN_IP=$(get_record_ip $DOMAIN $HOSTNAME)
echo "done."

echo DNS manager entry for \"$HOSTNAME.$DOMAIN\" : $DOCEAN_IP


if [ "$DOCEAN_IP" = "$WAN_IP" ]; then
  echo "Skipping update"
else
  echo -n "Performing update..."
  RECORD_ID=$(get_record_id $DOMAIN $HOSTNAME)
  response=$(set_record_ip $DOMAIN $RECORD_ID $WAN_IP)
  echo " done."
  # Don't trust, spend an extra API call to get the actual value
  # before saving to state file
  DOCEAN_IP=$(get_record_ip $DOMAIN $HOSTNAME)
  echo DNS manager entry for \"$HOSTNAME.$DOMAIN\" : $DOCEAN_IP
fi

# even if we skipped the update due to a match, we may still
# need to write a state file
echo $DOCEAN_IP > $STATE_FILE

echo

exit 0
