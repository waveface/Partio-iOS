#!/bin/bash

UNUSED="wammer/Resources/Unused"

mkdir -p $UNUSED

for i in `find wammer -name "*.png" -o -name "*.jpg" | grep -v Libraries | grep -v "Default-" | grep -v Icon`; do 
    file=`basename -s .jpg "$i" | xargs basename -s .png | xargs basename -s @2x`
    result=`ack -i "$file"`
    if [ -z "$result" ]; then
    	echo "$i"
    	mv "$i" $UNUSED
    fi
done