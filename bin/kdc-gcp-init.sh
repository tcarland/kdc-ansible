#!/bin/bash
#
#  Initialize KDC Master and Slave(s) Compute Instances
#
PNAME=${0##*\/}
version="v0.1.1"

tdh_path="$1"
mtype="$2"

if [ -z "$tdh_path" ]; then
    echo "Usage: $PNAME [path/to/tdh-gcp]"
    exit 0
fi

if [ -z "$mtype" ]; then
    mtype="n1-standard-1"
fi

# default hostnames as tdh-kdc01 and tdh-kdc02
( ${tdh_path}/bin/tdh-gcp-compute.sh -t $mtype kdc01 kdc02 )

exit 0
