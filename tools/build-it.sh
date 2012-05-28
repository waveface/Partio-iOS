#!/bin/bash --

agvtool bump
TAG=`agvtool what-version -terse`

# * jsa-feature/HealthyJenkins becomes HealthyJenkins
# finish and keep the feature. Don't think that's all. Develop, build, FIXES.
git flow feature finish -Fk ``git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* [a-zA-Z0-9\-]*\/\(.*\)/\1/'``
git pull origin develop
git commit -am --amend '+1'
git tag -m '$TAG' -a $TAG
git push origin develop
git push --tags