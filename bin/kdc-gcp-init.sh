#!/bin/bash
#
#  Initialize KDC Master and Slave(s) Compute Instances
#  This script is a templated wrapper to tdh-gcp-compute.sh
#  with defaults provided.
#
PNAME=${0##*\/}
version="v0.1.5"

tdh_path=
bootsize="32G"
network="tdh-net"
subnet="tdh-net-west1"
mtype="n1-standard-1"
zone=
prefix=
dryrun=0

usage() {
    echo ""
    echo "Usage: $PNAME [options] [action] [path/to/tdh-gcp]"
    echo "  [-bpnNtz]  :  options available from tdh-gcp-compute.sh"
    echo "    refer to \$TDH_GCP_PATH/tdh-gcp-compute.sh --help"
    echo "  --dryrun   :  Enable dryrun mode on compute script"
    echo "  [action]   :  Any action other tnan 'run' enables dryrun"
    echo ""
}

# Main
rt=0

while [ $# -gt 0 ]; do
    case "$1" in
        -b|--bootsize)
            bootsize="$2"
            shift
            ;;
        -h|--help)
            usage
            exit $rt
            ;;
        -p|--prefix)
            prefix="$2"
            shift
            ;;
        --dryrun)
            dryrun=1
            ;;
        -N|--network)
            network="$2"
            shift
            ;;
        -n|--subnet)
            subnet="$2"
            shift
            ;;
        -t|--type)
            mtype="$2"
            shift
            ;;
        -z|--zone)
            zone="$2"
            shift
            ;;
        -V|--version)
            version
            exit $rt
            ;;
        *)
            action="$1"
            tdh_path="$2"
            shift $#
            ;;
    esac
    shift
done

if [ -z "$tdh_path" ] && [ -n "$TDH_GCP_PATH" ]; then
    tdh_path="$TDH_GCP_PATH"
fi

if [ -z "$tdh_path" ]; then
    echo "Usage: $PNAME [path/to/tdh-gcp] <machine-type>"
    echo "  Default machine-type is 'n1-standard-1'"
    exit 1
fi

if [ -z "$mtype" ]; then
    mtype="n1-standard-1"
fi

# default hostnames as tdh-kdc01 and tdh-kdc02
cmd="${tdh_path}/bin/tdh-gcp-compute.sh \\
 --bootsize $bootsize --machine-type $mtype \\
 --network $network --subnet $subnet"

if [ -n "$zone" ]; then
    cmd="$cmd --zone $zone"
fi
if [ -n "$prefix" ]; then
    cmd="$cmd --prefix $prefix"
fi
if [ $dryrun -eq 1 ]; then
    cmd="$cmd --dryrun"
fi

cmd="$cmd create kdc01 kdc02"

echo ""
echo " ( $cmd ) "
echo ""

if [ "$action" == "run" ] && [ $dryrun -eq 0 ]; then
    ( $cmd )
fi

host="tdh-kdc01"
if [ -n "$prefix" ]; then
    host="${prefix}-kdc01"
fi

if [ $dryrun -eq 0 ]; then
    sleep 10
    for x in {1..3}; do 
        yf=$( $gssh $host --command 'uname -n' )
        if [[ $yf == $host ]]; then
            echo " It's ALIIIIVE!!!"
            break
        fi 
        echo -n ". "
        sleep 5
    done

    ( $gssh $host --command 'yum install -y ansible' )
    ( $tdh_path/bin/gcp-push.sh . kdc-ansible $host )
fi

echo ""
echo "Finished."

exit $?
