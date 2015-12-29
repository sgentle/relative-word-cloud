#!/bin/sh
echo '{'
cat "$@" |\
 sed "s/[^a-zA-Z0-9'’ ]/ /g" |\
 tr '[A-Z]' '[a-z]' | tr ' ' '\n' |\
 grep -v '^$' |\
 sort |\
 uniq -c |\
 sort -n |\
 awk '{print "\"" $2 "\": " $1 ","}'
echo '"": 0' # gross
echo '}'
