#!/bin/bash

set -ex

export PATH="/usr/lib/ccache:/usr/lib/ccache/bin:$PATH"

bash scripts/build-mpv.sh

export QML_SOURCES_PATHS=src/qml
export V=0 VERBOSE=0

qmake CONFIG+=release PREFIX=/usr
make -j$(nproc)
make INSTALL_ROOT=appdir -j$(nproc) install ; find appdir/
#wget "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
wget -nc "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
wget -nc "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage"
wget -nc "https://raw.githubusercontent.com/TheAssassin/linuxdeploy-plugin-conda/master/linuxdeploy-plugin-conda.sh"
chmod +x linux*
mkdir -p appdir/usr/lib
cp /usr/lib/x86_64-linux-gnu/libjack.so.0 appdir/usr/lib
export VERSION=$(git rev-parse --short HEAD) # linuxdeployqt uses this for naming the file
#mkdir -p appdir/usr/plugins/imageformats
#cp /opt/qt*/plugins/imageformats/libqsvg.so appdir/usr/plugins/imageformats/
#./linuxdeployqt-continuous-x86_64.AppImage appdir/usr/share/applications/*.desktop -qmldir=./src/qml/ -bundle-non-qt-libs
#./linuxdeployqt-continuous-x86_64.AppImage appdir/usr/share/applications/*.desktop -qmldir=./src/qml/ -appimage
export PIP_REQUIREMENTS=youtube-dl
ln -s ../conda/bin/youtube-dl appdir/usr/bin/youtube-dl
./linuxdeploy-x86_64.AppImage --appdir appdir --plugin qt --plugin conda --output appimage
