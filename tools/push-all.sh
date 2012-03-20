#!/usr/bin/env bash --

git show HEAD
git submodules
git push origin develop master
git push origin --tags
