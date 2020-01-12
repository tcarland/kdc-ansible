#!/bin/bash
#
#  Wrapper script for running the install playbook
#
PNAME=${0##*\/}
kdcenv="$1"

if [ -z "$kdcenv" ]; then
    kdcenv="$KDC_ENV"
fi

if [ -z "$kdcenv" ]; then
    echo "Please provide the ansible inventory name/environment."
    echo ""
    echo "Usage $PNAME <inventory_name>"
    echo ""
    exit 1
fi

( ansible-playbook -i inventory/${kdcenv}/hosts kdc-site.yml )

exit $?
