#!/bin/bash --

if [ "`git branch --no-color 2> /dev/null | grep '*' | grep -c feature`" != "1" ]; then
    echo 'You must build this from feature branch.'
fi

#TODO: need to make sure everything is checked in.

agvtool bump
git commit -am '+1'

# * jsa-feature/HealthyJenkins becomes HealthyJenkins
# finish and keep the feature. Don't think that's all. Develop, build, FIXES.
git flow feature finish -k `git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* [a-zA-Z0-9\-]*\/\(.*\)/\1/'`

git fetch
git pull origin develop

git push origin develop 

TAG=`agvtool what-version -terse`
git tag -m '$TAG' -a $TAG
git push --tags
