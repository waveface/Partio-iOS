#!/bin/bash --

agvtool bump
tag =`agvtool what-verison -terse`

git commit -am 'CFBundleVersion + 1'
git tag -m '$tag' -a $tag
git push origin develop
git push --tags