#!/bin/env bash

oid_out="1.3.6.1.2.1.31.1.1.1.10.3"
agent_ip="10.200.1.251"
community="123test123"

value=$(snmpwalk -v2c -c "$community" "$agent_ip" "$oid_out" | awk -F' ' '{print $4}')
echo "$value"

# Output:
# 1234567890