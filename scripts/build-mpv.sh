#!/bin/bash
#git clone --depth 1 https://github.com/mpv-player/mpv-build
#cd mpv-build
export PATH="/usr/lib/ccache:$PATH"
git clone --depth 1 https://github.com/mpv-player/mpv
cd mpv

echo --enable-libmpv-shared --prefix=/usr  >> mpv_options
echo --disable-caca --disable-wayland --disable-gl-wayland --disable-libarchive  --disable-zlib  --disable-tv --disable-debug-build --disable-manpage-build --disable-vapoursynth --disable-libsmbclient >> mpv_options


./bootstrap.py
./waf configure `cat mpv_options`
./waf -j`nproc`
sudo ./waf install

cd ..
