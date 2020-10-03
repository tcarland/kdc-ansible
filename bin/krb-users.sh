#!/bin/bash
#
PNAME=${0##*\/}

infile=
action=
princ=
pw=


usage() {
    echo ""
    echo "Usage: $PNAME [-f infile]  [action]  <princ> "
    echo "  -f|--file <file> : Performs the action on a list of principals"
    echo "  -h|--help        : Show help and exit"
    echo "    [action]       : [ add|del|list ]"
    echo "    <princ> <pw>   "
    echo "" 
    echo " If '--file' is not provided, the script will perform a one-time"
    echo " action on the provided principal prompting for a password."
    echo "" 
}


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
            usage
            exit $rt
            ;;
        -f|--file)
            infile="$2"
            shift
            ;;
        --dryrun)
            dryrun=1
            ;;
        'version'|-V|--version)
            version
            exit $rt
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
    usage
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
                echo "Error reading password."
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
        echo "Action not recognized. '$action'"
        ;;
esac

exit $?