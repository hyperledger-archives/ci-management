#!/bin/bash

# vim: sw=4 ts=4 sts=4 et :

HOST=$(/bin/hostname)
SYSTEM_TYPE=''

IFS='-' read -r -a HOSTPARTS <<< "${HOST}"

# slurp in the control scripts
FILES=($(find . -maxdepth 1 -type f -iname '*.sh' -exec basename -s '.sh' {} \;))
# remap into an associative array
declare -A A_FILES
for key in "${!FILES[@]}"
do
    A_FILES[${FILES[$key]}]="${key}"
done

# Find our system_type control script if possible
for i in "${HOSTPARTS[@]}"
do
    if [ "${A_FILES[${i}]}" != "" ]
    then
        SYSTEM_TYPE=${i}
        break
    fi
done

# Write out the system type to an environment file to then be sourced
echo "SYSTEM_TYPE=${SYSTEM_TYPE}" > /tmp/system_type.sh
