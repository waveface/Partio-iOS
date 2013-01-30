#!/bin/sh
IFS='
'
 
# Name of remote repository. Can be edited.
remote=origin
 
printf "git push $remote"
for i in `git branch -r | grep "^ *$remote/sy-" | grep -v HEAD | sed "s;^ *$remote/;;"`
do
    if git rev-parse -q --verify $i >/dev/null
    then
       nothing=
    else
       printf " :%s" "$i"
    fi
done
printf "\n"
