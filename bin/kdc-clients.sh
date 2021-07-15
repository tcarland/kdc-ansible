#!/bin/bash
#
#  Run client playbook on a list of hosts
#
PNAME=${0##*\/}
inv="$1"

usage="
Runs the kdc-clients playbook against the 'clients' inventory group.

Usage: $PNAME [inventory_name] 

Where [inventory_name] is the environment ./inventory/[name]
"

if [ -z "$inv" ] || [ -z "$hosts" ]; then
    echo "$usage"
    exit 1
fi

echo "( ansible-playbook -i inventory/$inv/hosts kdc-clients.yml )"
( ansible-playbook -i inventory/$inv/hosts kdc-clients.yml )

exit $?    
