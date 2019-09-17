#!/bin/bash
#
#  Wrapper script for running the install playbook
#
PNAME=${0##*\/}
gcpenv="$1"

if [ -z "$gcpenv" ]; then
    gcpenv="$GCP_ENV"
fi

if [ -z "$gcpenv" ]; then
    echo "Please provide the inventory name/environment or set GCP_ENV."
    echo ""
    echo "Usage $PNAME <inventory_name>"
    echo ""
    exit 1
fi

( ansible-playbook -i inventory/${gcpenv}/hosts kdc-site.yml )

exit $?
