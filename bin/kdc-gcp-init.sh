#!/bin/bash
#
#  Initialize KDC Master and Slave(s) Compute Instances
#
PNAME=${0##*\/}

tdh_path="$1"

if [ -z "$tdh_path" ]; then
    echo "Usage: $PNAME [path/to/tdh-gcp]"
    exit 0
fi

# default hostnames as tdh-kdc01 and tdh-kdc02
( tdh-gcp-compute.sh -t n1-standard-1 kdc01 kdc02 )

exit 0
