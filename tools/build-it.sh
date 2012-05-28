#!/bin/bash --

if [ "`git branch --no-color 2> /dev/null | grep '*' | grep -c feature`" != "1" ]; then
    echo 'You must build this from feature branch.'
fi

# * jsa-feature/HealthyJenkins becomes HealthyJenkins
# finish and keep the feature. Don't think that's all. Develop, build, FIXES.
git flow feature finish -Fk `git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* [a-zA-Z0-9\-]*\/\(.*\)/\1/'`

git fetch
git pull origin develop

agvtool bump
git commit -am '+1' --amend 
git push origin develop

TAG=`agvtool what-version -terse`
git tag -m '$TAG' -a $TAG
git push --tags
