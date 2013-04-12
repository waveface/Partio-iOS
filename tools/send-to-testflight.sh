#!/usr/local/bin/zsh
#!/bin/zsh

function usage() {
    echo "Usage: [options]"
    echo
    echo "Options"
    echo "  -f        Force Push"
    echo "  -t [Tag]  Prefix (dev|rel), default (dev)"
    exit 1
}


PROJECT_NAME="Partio-iOS"

VERSION_MARKETING="`agvtool mvers -terse1`"
VERSION_BUILD="`agvtool vers -terse`"
COMMIT_SHA="`git rev-parse HEAD`"

BUILD_CONFIGURATION="Release"
BUILD_SDK="iphoneos"
SYMROOT="Deploy"
PRODUCT_NAME="$PROJECT_NAME.app"
TARGET_NAME="wammer-iOS"

IPA_NAME=`find . -name "*.ipa" -print0`
DSYM_ZIP_NAME=`find . -name "*dSYM.zip" -print0`

GIT_LATEST_TAG="`git describe --abbrev=0 --tags`"
GIT_INFO="`git log --stat --summary HEAD...$GIT_LAST_TAG`"

TF_API_TOKEN="267d14b54906a94ec9b58d775a4641e0_OTkxODY"
TF_TEAM_TOKEN="2e0589c9a03560bfeb93e215fdd9cbbb_MTg2ODAyMDExLTA5LTIyIDA0OjM4OjI1LjMzNTEyNg"
TF_API_URI="http://testflightapp.com/api/builds.json"
TF_NOTES="$PROJECT_NAME $VERSION_MARKETING ($VERSION_BUILD) # $COMMIT_SHA\n$GIT_INFO"
TF_NOTIFY="True"
TF_DIST_LISTS="Developer"

FORCE_PUSH=
TAG_PREFIX="dev"

while getopts ":ft:" opt; do
  case $opt in
    f ) FORCE_PUSH=1 ;;
    t ) TAG_PREFIX=$OPTARG ;;
    \? ) echo "Invalid option: -$OPTARG" >&2
        usage;;
  esac
done

if [[ -z `git tag -l $TAG_PREFIX-$VERSION_BUILD` ]]; then
    `git tag $TAG_PREFIX-$VERSION_BUILD`
    `git push origin $TAG_PREFIX-$VERSION_BUILD`
    FORCE_PUSH=1
else
    echo "tag '$TAG_PREFIX-$VERSION_BUILD' already exists";
fi

if [[ $FORCE_PUSH == 1 ]]; then
    curl  http://testflightapp.com/api/builds.json \
     -F file=@"$IPA_NAME" \
     -F dsym=@"$DSYM_ZIP_NAME" \
     -F api_token="$TF_API_TOKEN" \
     -F team_token="$TF_TEAM_TOKEN" \
     -F notes="$TF_NOTES" \
     -F notify="$TF_NOTIFY" \
     -F distribution_lists="$TF_DIST_LISTS"
fi
