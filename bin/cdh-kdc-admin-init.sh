#!/bin/bash
#
#  KDC setup for a CDH Cluster.
#   Creates the CDH Admin principal and adds groups to hosts
#
PNAME=${0##*\/}
cdhprinc="cloudera-scm/admin"
realm=$(cat /etc/krb5.conf | grep "default_realm" | awk '{ print $3 }')

cdh_groups="hdfsadmin hdfsusers"
gid_start=5000
gcp_groups=$(groups)
def_groups="adm video google-sudoers"

pwfile=
pw=

# ---------------------------------------------------------------------

usage()
{
    echo "Usage: $PNAME [-p file] host1 host2 ..."
    echo "  -p|--pwfile [file]  :  Read Admin password from file to not prompt"
    echo "  Alternatively set CDH_HOSTS to the cluster host list"
    echo ""
}


read_password()
{
    local prompt="Password: "
    local pass=
    local pval=

    read -s -p "$prompt" pass
    echo ""
    read -s -p "Repeat $prompt" pval
    echo ""

    if [[ "$pass" != "$pval" ]]; then
        return 1
    fi

    pwfile=$(mktemp /tmp/kdc-adminpw.XXXXXXXX)
    echo $pass > $pwfile

    return 0
}


# ---------------------------------------------------------------------
# MAIN
#
rt=

# Usage
if [ -z "$pwfile" ]; then
    usage
    exit 1
fi


while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit $rt
            ;;
        -p|--pwfile)
            pwfile="$2"
            shift
            ;;
        *)
            hosts="$@"
            shift $#
            ;;
    esac
    shift
done

if [ -z "$pwfile" ]; then
    echo "--pwfile not specified. Please provide the admin password."
    read_password
fi

# Check pwfile
if ! [ -e "$pwfile" ]; then
    echo "ERROR. File does not exist. '$pwfile'"
    exit 1
fi

pw=$(cat $pwfile)
unlink $pwfile

# Check pw
if [ -z "$pw" ]; then
    echo "Empty password not allowed"
    exit 1
fi

echo "Creating CDH Admin principal: ${cdhprinc}@${realm}"
( sudo kadmin.local -q "addprinc -pw $pw $cdhprinc" )

# Add Groups
for host in $hosts; do
    gid=$gid_start
    for group in $cdh_groups; do
        echo "( ssh $host sudo groupadd -g $gid $group )"
        ( ssh $host sudo groupadd -g $gid $group )
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Error in ssh groupadd"
            break
        fi
        ((gid++))
    done
done

echo "$PNAME Finished."

exit $rt