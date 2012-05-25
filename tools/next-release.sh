#!/usr/bin/env bash --

CurrentVersion=`agvtool vers -terse`
NextVersion=`expr $CurrentVersion + 1`

echo $NextVersion

git flow feature start $NextVersion
agvtool new-version $NextVersion
git commit -a -m "Punt"
git commit --amend
git flow feature finish $NextVersion
