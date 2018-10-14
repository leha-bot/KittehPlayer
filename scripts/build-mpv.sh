#!/bin/bash
git clone --depth 1 https://github.com/mpv-player/mpv-build
cd mpv-build

echo --enable-libmpv-shared --prefix=/usr > mpv_options
echo --disable-caca --disable-wayland --disable-gl-wayland --disable-libarchive  --disable-zlib  --disable-tv --disable-debug-build --disable-manpage-build --disable-vapoursynth --disable-libsmbclient > mpv_options

./rebuild -j`nproc`
sudo ./install
cd ..
