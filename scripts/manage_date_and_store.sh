#!/bin/env bash

oid_out="1.3.6.1.2.1.31.1.1.1.10.3"
agent_ip="10.200.1.251"
community="123test123"
filename="/tmp/count.log"

value=$(snmpwalk -v2c -c "$community" "$agent_ip" "$oid_out" | awk '{print $4}')
date=$(date "+%s") # Get time in seconds since 1970-01-01 00:00:00 UTC
echo "${date};${value}" >> "$filename"

# Output:
# cat /tmp/count.log:
# 1234567890;1234567890