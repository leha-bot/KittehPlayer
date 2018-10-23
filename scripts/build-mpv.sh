#!/bin/bash
set -x

export OLDDIR=`pwd`
#export PATH="/usr/lib/ccache:/usr/lib/ccache/bin:$PATH"

#export CFLAGS="-Os"

ccache -C


rm -rf mpv-build
git clone --depth 1 https://github.com/mpv-player/mpv-build mpv-build
cd mpv-build

export MPVDIR=`pwd`


rm -rf ffmpeg mpv libass

echo ' ' > ffmpeg_options
echo "--disable-programs --disable-runtime-cpudetect --enable-small" >> ffmpeg_options
echo "--enable-libmpv-shared --prefix=/usr" > mpv_options
echo "--disable-caca --disable-wayland --disable-gl-wayland --disable-libarchive  --disable-zlib  --disable-tv --disable-debug-build --disable-manpage-build --disable-vapoursynth --disable-libsmbclient --disable-wayland" >> mpv_options

sudo ./rebuild -j`nproc`
sudo ./install
ccache -s
cat libass*/config.log

cd $OLDDIR
