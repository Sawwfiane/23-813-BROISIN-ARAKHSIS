#!/bin/env bash

oid_out="1.3.6.1.2.1.31.1.1.1.10.3"
agent_ip="10.200.1.251"
community="123test123"
filename="/tmp/count.log"

value=$(snmpwalk -v2c -c "$community" "$agent_ip" "$oid_out" | awk -F' ' '{print $4}')
date=$(date "+%s") # Unix timestamp
if [ -f "$filename" ]; then
  last_date=$(tail -n 1 "$filename" | awk -F ';' '{print $1}')
  last_value=$(tail -n 1 "$filename" | awk -F ';' '{print $2}')
else
  last_date=0
  last_value=0
fi

debit=$((($value - $last_value) / ($date - $last_date)))
echo "${date};${value};${debit}" >> "$filename" 

# Output:
# cat /tmp/count.log 
# 1710838235;325093612;0