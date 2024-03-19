oid_out="1.3.6.1.2.1.31.1.1.1.10.3"
agent_ip="10.200.1.251"
community="123test123"
filename="/tmp/count.log"

value=$(snmpwalk -v2c -c "$community" "$agent_ip" "$oid_out" | awk -F' ' '{print $4}')

date=$(date "+%s")
if [ -f "$filename" ]; then
  last_date=$(tail -n 1 "$filename" | awk -F ';' '{print $1}')
  last_value=$(tail -n 1 "$filename" | awk -F ';' '{print $2}')
else
  last_date=0
  last_value=0
fi

if [ "$value" -lt "$last_value" ]; then
  debit=$(((value+18446744073709599999-last_value) / (date - last_date)))
else
  debit=$(((value - last_value) / (date - last_date)))
fi

echo "${date};${value};${debit}" >> "$filename" 