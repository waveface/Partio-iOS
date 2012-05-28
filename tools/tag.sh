#!/bin/bash --

agvtool bump
TAG=`agvtool what-version -terse`

git pull origin develop
git commit -am 'CFBundleVersion + 1'
git tag -m '$TAG' -a $TAG
git push origin develop
git push --tags