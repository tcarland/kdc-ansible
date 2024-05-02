#!/usr/bin/env bash
#
# Perform basic KDC actions against a list of principals
# 
PNAME=${0##*\/}

infile=
action=
princ=
pw=


usage="
A script for performing basic add, delete, and list actions on a 
set of user principals.

Synoposis:
  $PNAME [-f infile] [action]  <princ> <pw>

Options:
  -f|--file <file> : Performs the action on a list of principals
  -h|--help        : Show help and exit
   [action]        : add|del|list 
   <princ> <pw>   
 
If '--file' is not provided, the script will perform a one-time
action on the provided principal prompting for a password.
File format is newline separated user and pw. 
On [add] the script will prompt for password if not provided.
" 


# reads and sets a password
read_password()
{
    local prompt="Password: "
    local REPLY=
    local valpw=

    read -s -p "$prompt" REPLY
    echo ""
    read -s -p "Repeat $prompt" valpw

    if [[ "$REPLY" != "$valpw" ]]; then
        echo ""
        echo "Passwords do not match! Abort."
        exit 1
    fi

    pw="$valpw"
    echo ""
}


# Main
rt=0

while [ $# -gt 0 ]; do
case "$1" in
    'help'|-h|--help)
        echo "$usage"
        exit $rt
        ;;
    -f|--file)
        infile="$2"
        shift
        ;;
    --dryrun)
        dryrun=1
        ;;
    *)
        action="$1"
        princ="$2"
        pw="$3"
        shift $#
        ;;
esac
shift
done


if [ -z "$infile" ] && [ "$princ" ]; then
    echo "$usage"
    exit 1
fi


case "$action" in 
add)
    if [ -n "$infile" ]; then
        ( awk '{ print "ank +needchange -pw", $2, $1 }' < $infile | \
        time /usr/sbin/kadmin.local )
    else
        if [ -z "$pw" ]; then
            read_password
        fi
        if [ -z "$pw" ]; then
            echo "$PNAME Error obtaining password."
            exit 1
        fi
        ( kadmin.local -q "addprinc -pw $pw $princ" )
    fi
    ;;
del)
    if [ -n "$infile" ]; then
        ( awk '{ print "delprinc ", $1 }' < $infile | \
        time /usr/sbin/kadmin.local )
    else
        ( kadmin.local -q "delprinc $princ" )
    fi
    ;;
list)
    ( kadmin.local -q "listprincs" )
    ;;
*)
    echo "$PNAME Action not recognized. '$action'"
    ;;
esac

exit $?