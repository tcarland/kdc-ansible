#!/bin/bash
#
#  Wrapper script for running the install playbook
#
GCP_ENV="$1"

if [ -z "$GCP_ENV" ]; then
    echo "Please provide the inventory name/environment"
    exit 1
fi

( ansible-playbook -i inventory/$GCP_ENV/hosts kdc-install.yml )

exit $?
