#!/bin/bash
#
#  Run client playbook on a list of hosts
#
PNAME=${0##*\/}
inv="$1"
shift
hosts="$@"

if [ -z "$inv" ] || [ -z "$hosts" ]; then
    echo "No hosts provided"
    echo ""
    echo "Usage: $PNAME [inventory_name] [host1] <host2> <host3> ..."
    echo "Where [inventory_name] is the environment ./inventory/[name]"
    echo ""
    exit 1
fi

hosts=$( echo $hosts | sed -e 's/[[:space:]][[:space:]]*/,/g' )

echo "( ansible-playbook -i $inv kdc-clients.yml --extra-vars \"@inventory/$inv/group_vars/all/vars" )"
( ansible-playbook -i $inv kdc-clients.yml --extra-vars "@inventory/$inv/group_vars/all/vars" )

exit $?    
