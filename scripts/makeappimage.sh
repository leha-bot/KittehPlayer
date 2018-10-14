#!/bin/bash

set -ex

export PATH="/usr/lib/ccache:/usr/lib/ccache/bin:$PATH"

bash scripts/build-mpv.sh

export QML_SOURCES_PATHS=src/qml

qmake CONFIG+=release PREFIX=/usr
make -j$(nproc)
make INSTALL_ROOT=appdir -j$(nproc) install ; find appdir/
#wget "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
wget -nc "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
wget -nc https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
chmod +x linux*
export VERSION=$(git rev-parse --short HEAD) # linuxdeployqt uses this for naming the file
#mkdir -p appdir/usr/plugins/imageformats
#cp /opt/qt*/plugins/imageformats/libqsvg.so appdir/usr/plugins/imageformats/
#./linuxdeployqt-continuous-x86_64.AppImage appdir/usr/share/applications/*.desktop -qmldir=./src/qml/ -bundle-non-qt-libs
#./linuxdeployqt-continuous-x86_64.AppImage appdir/usr/share/applications/*.desktop -qmldir=./src/qml/ -appimage
./linuxdeploy-x86_64.AppImage --appdir appdir --plugin qt --output appimage
