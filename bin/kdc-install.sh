#!/bin/bash
#
#  Wrapper script for running the install playbook
#
PNAME=${0##*\/}
version="v20.11"
kdcenv="$1"
rt=0

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

echo "( ansible-playbook -i inventory/${kdcenv}/hosts kdc-site.yml )"
( ansible-playbook -i inventory/${kdcenv}/hosts kdc-site.yml )

echo "( ansible-playbook -i inventory/${kdcenv}/hosts kdc-clients.yml )"
( ansible-playbook -i inventory/${kdcenv}/hosts kdc-clients.yml )

exit $?
