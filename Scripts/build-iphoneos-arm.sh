#!/usr/bin/env bash

set -x
set -e

scriptsDirectory=`dirname "$0"`
projectDirectory="$scriptsDirectory/../"

pushd "$projectDirectory"
    sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/IPHONEOS_DEPLOYMENT_TARGET = 11.0;/g' flexdecrypt.xcodeproj/project.pbxproj
    xcodebuild -scheme flexdecrypt -sdk iphoneos -configuration Release -derivedDataPath ./derived
    binDirectory="./Package/usr/bin"
    mkdir -p "$binDirectory"
    cp ./derived/Build/Products/Release-iphoneos/flexdecrypt.app/flexdecrypt "$binDirectory/"
    find ./Package -name ".DS_Store" -depth -exec rm {} \;
    dpkg-deb -b -Zgzip ./Package flexdecrypt.deb
popd
