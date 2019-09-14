#!/bin/bash
#
#  Run client playbook on a list of hosts
#
PNAME=${0##*\/}
hosts="$@"

if [ -z "$hosts" ]; then
    echo "Usage: $PNAME [host1] <host2> <host3> ..."
    exit 1
fi

inv=$( echo $hosts | sed -e 's/[[:space:]][[:space:]]*/,/g' )
echo "( ansible-playbook -i $inv kdc-client.yml )"

( ansible-playbook -i $inv kdc-client.yml )

exit $?    
