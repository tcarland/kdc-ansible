#!/bin/bash
#
#  Wrapper script for running the install playbook
#
gcpenv="$1"

if [ -z "$gcpenv" ]; then
    gcpenv="$GCP_ENV"
fi

if [ -z "$gcpenv" ]; then
    echo "Please provide the inventory name/environment"
    exit 1
fi

( ansible-playbook -i inventory/${gcpenv}/hosts kdc-install.yml )

exit $?
