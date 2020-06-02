#!/bin/bash

PROC="some_proc"
PID=$(pidof -s $PROC 2>/dev/null)
TIMEOUT="7200" # seconds

if [[ -z "$PID" ]]; then
	exit
fi

while read -r line; do
	fd=$(echo "$line" | sed -r 's/[[:alnum:]]+=/\n&/g' | awk -F= '$1=="fd"{print $2}' | awk '{print $1}' | sed 's/[^0-9]*//g')
	last_activity=$(echo "$line" | sed -r 's/[[:alnum:]]+:/\n&/g' | awk -F: '$1=="lastsnd"{print $2}' | sed 's/[^0-9]*//g')

	if [[ $last_activity -ge $((TIMEOUT*1000)) ]]; then
		gdb -p "$PID" --batch -ex "call close($fd)" -ex quit
	fi
done < <(ss -t -a -p -n -i | awk '/'"$PROC"'/{printf $0 ;next;}1' | grep "pid=$PID," | grep ESTAB)
