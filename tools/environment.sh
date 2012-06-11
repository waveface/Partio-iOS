#!/bin/bash --

PROJECT_NAME="Wammer-iOS"
PROVISIONING_PROFILE="D46DBA4C-1BDC-40CB-8713-ECBADB3B2AF1"
CODE_SIGN_IDENTITY="iPhone Developer: CI Waveface (JLVTY33BNU)"
TF_API_TOKEN="25d06f90b105f81cec6ca700832f91a0_Mzc5NDk"
TF_TEAM_TOKEN="2e0589c9a03560bfeb93e215fdd9cbbb_MTg2ODAyMDExLTA5LTIyIDA0OjM4OjI1LjMzNTEyNg"

VERSION_MARKETING="`agvtool mvers -terse1`"
VERSION_BUILD="`agvtool vers -terse`"
COMMIT_SHA="`git rev-parse HEAD`"

BUILD_CONFIGURATION="Release"
BUILD_SDK="iphoneos"
SYMROOT="Deploy"
PRODUCT_NAME="$PROJECT_NAME.app"
TARGET_NAME="wammer-iOS"
DSYM_NAME="$PROJECT_NAME.app.dSYM"
IPA_NAME="$PROJECT_NAME.app.ipa"
DSYM_ZIP_NAME="$PROJECT_NAME.app.dSYM.zip"

GIT_LATEST_TAG="`git describe --abbrev=0 --tags`"
GIT_INFO="`git log --stat --summary HEAD...$GIT_LATEST_TAG`"

TF_API_URI="http://testflightapp.com/api/builds.json"
TF_NOTES="$PROJECT_NAME $VERSION_MARKETING ($VERSION_BUILD) # $COMMIT_SHA\n$GIT_INFO"
TF_NOTIFY="True"
TF_DIST_LISTS="CI Responder"

function AFTER_BUILD () {

	if [ $VERSION_BUILD != $GIT_LATEST_TAG ]; then

		git tag $VERSION_BUILD
		git push origin $VERSION_BUILD

		xcodebuild build -target "wammer-iOS-Test" -configuration $BUILD_CONFIGURATION -sdk iphonesimulator SYMROOT="$TEMP_DIR"

		cd $PRODUCT_DIR

		curl -F key="$PROJECT_NAME $VERSION_MARKETING ($VERSION_BUILD) $COMMIT_SHA.dSYM.zip" -F file="@$DSYM_NAME" -F AWSAccessKeyId=AKIAJHAB2VXT477YWXRA -F acl=public-read -F filename="$DSYM_NAME" -F policy="CnsiZXhwaXJhdGlvbiI6ICIyMDIwLTAxLTAxVDAwOjAwOjAwWiIsCiAgImNvbmRpdGlvbnMiOiBbIAogICAgeyJidWNrZXQiOiAid2F2ZWZhY2UtYmxvYiIgfSwKICAgIHsic3VjY2Vzc19hY3Rpb25fcmVkaXJlY3QiOiAiaHR0cDovL2xvY2FsaG9zdC8iIH0sCiAgICB7ImFjbCI6ICJwdWJsaWMtcmVhZC13cml0ZSIgfSwKICAgIFsic3RhcnRzLXdpdGgiLCAiJENvbnRlbnQtVHlwZSIsICIiXQogIF0KfQoK" -F signature="idOKxQk6jL3rOviWQnIFxoLZkiM=" http://waveface-blob.s3.amazonaws.com
	
		curl -F key="$PROJECT_NAME $VERSION_MARKETING ($VERSION_BUILD) $COMMIT_SHA.ipa" -F file="@$IPA_NAME" -F AWSAccessKeyId=AKIAJHAB2VXT477YWXRA -F acl=public-read -F filename="$IPA_NAME" -F policy="CnsiZXhwaXJhdGlvbiI6ICIyMDIwLTAxLTAxVDAwOjAwOjAwWiIsCiAgImNvbmRpdGlvbnMiOiBbIAogICAgeyJidWNrZXQiOiAid2F2ZWZhY2UtYmxvYiJ9LCAKICAgIHsic3VjY2Vzc19hY3Rpb25fcmVkaXJlY3QiOiAiaHR0cDovL2xvY2FsaG9zdC8ifSwKICAgIFsic3RhcnRzLXdpdGgiLCAiJENvbnRlbnQtVHlwZSIsICIiXSwKICBdCn0KCg==" -F signature="M+Ysm3CVZSWvQ1kZUfZu8s3+1Qw=" http://waveface-blob.s3.amazonaws.com

	fi

}