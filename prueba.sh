#!/bin/bash
usr=$1
linea=$(grep $usr /etc/passwd)
home=$(echo "${linea}" | cut -d ':' -f6)
echo $home
