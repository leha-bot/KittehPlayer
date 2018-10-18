#!/bin/bash
set -e

export TEXT=`git log -1 --pretty=%B`
export UPLOADTOOL_BODY="$TEXT\nTravis CI build log: https://travis-ci.com/$TRAVIS_REPO_SLUG/builds/$TRAVIS_BUILD_ID/"

curl --upload-file KittehPlayer*.AppImage https://transfer.sh/KittehPlayer-git.$(git rev-parse --short HEAD)-x86_64.AppImage
wget -c https://github.com/probonopd/uploadtool/raw/master/upload.sh
bash upload.sh KittehPlayer*.AppImage*
echo "Done!"