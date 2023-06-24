#!/usr/bin/env bash

set -x
set -e

scriptsDirectory=`dirname "$0"`
projectDirectory="$scriptsDirectory/../"

pushd "$projectDirectory"
    sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 11.0;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' flexdecrypt.xcodeproj/project.pbxproj
    xcodebuild -scheme flexdecrypt -sdk iphoneos -configuration Release -derivedDataPath ./derived-rootless
    binDirectory="./Package-rootless/var/jb/usr/bin"
    mkdir -p "$binDirectory"
    cp ./derived-rootless/Build/Products/Release-iphoneos/flexdecrypt.app/flexdecrypt "$binDirectory/"
    find ./Package-rootless -name ".DS_Store" -depth -exec rm {} \;
    dpkg-deb -b -Zgzip ./Package-rootless flexdecrypt-rootless.deb
popd
