set -x
set -e

scriptsDirectory=`dirname "$0"`
projectDirectory="$scriptsDirectory/../"

pushd "$projectDirectory"
    xcodebuild -scheme flexdecrypt -sdk iphoneos -configuration Release -derivedDataPath ./derived
    binDirectory="$projectDirectory/Package/usr/bin"
    mkdir -p "$binDirectory"
    cp ./derived/Build/Products/Release-iphoneos/flexdecrypt.app/flexdecrypt "$binDirectory/"
    find ./Package -name ".DS_Store" -depth -exec rm {} \;
    dpkg-deb -b -Zgzip "$projectDirectory/Package" flexdecrypt-1.0.deb
popd
