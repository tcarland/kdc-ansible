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
def_groups="adm video google-sudoers"
dryrun=0

pwfile=
pw=

# ---------------------------------------------------------------------

usage="
Usage: $PNAME [-p file] host1 host2 ...
  -h|--help           :  Show usage info and exit.
  -g|--gid-start [n]  :  Starting GID value. Must be > 1010, default is 5000.
  -p|--pwfile [file]  :  Read password from file to avoid interactive prompt.
  -n|--dryrun         :  Enable dry-run, commands are not run.

  The script honors the envvar CDH_HOSTS for the host list.
"



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
        echo " -> password mismatch!"
        return 1
    fi

    pwfile=$(mktemp /tmp/kdc-adminpw.XXXXXXXX)
    echo $pass > $pwfile

    return 0
}


# ---------------------------------------------------------------------
# MAIN
#
rt=0

while [ $# -gt 0 ]; do
    case "$1" in
        'help'|-h|--help)
            echo "$usage"
            exit $rt
            ;;
        -g|--gid-start)
            gid_start=$2
            shift
            ;;
        -n|--dry-run|--dryrun)
            dryrun=1
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
    echo " -> --pwfile not specified. Please provide the admin password."
    read_password
fi

if [ $gid_start -lt 1020 ]; then
    echo "$PNAME Error, GID start range' is to low."
    exit 2
fi

# Check pwfile
if ! [ -e "$pwfile" ]; then
    echo "$PNAME Error, File does not exist. '$pwfile'"
    exit 1
fi

pw=$(cat $pwfile)
unlink $pwfile

# Check pw
if [ -z "$pw" ]; then
    echo "$PNAME Error, Empty password not allowed"
    exit 1
fi

echo "Creating CDH Admin principal: ${cdhprinc}@${realm}"
echo "  ( sudo kadmin.local -q 'addprinc -pw $pw $cdhprinc' )"

if [ $dryrun -eq 0 ]; then
    ( sudo kadmin.local -q "addprinc -pw $pw $cdhprinc" )
fi


# Add Groups
for host in $hosts; do
    gid=$gid_start
    for group in $cdh_groups; do
        echo "( ssh $host sudo groupadd -g $gid $group )"
        if [ $dryrun -eq 0 ]; then
            ( ssh $host sudo groupadd -g $gid $group )
            rt=$?
        fi
        if [ $rt -ne 0 ]; then
            echo "$PNAME Error in ssh groupadd"
            break
        fi
        ((gid++))
    done
done

echo "$PNAME Finished."

exit $rt