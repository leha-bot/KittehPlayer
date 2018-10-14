#!/bin/bash
set -ex



CFLAGS="-fPIC -Os"

rm -rf mpv-build && git clone --depth 1 https://github.com/mpv-player/mpv-build mpv-build
cd mpv-build

git clone --depth 1 https://aomedia.googlesource.com/aom
mkdir build && cd build
cmake ../aom -G "Unix Makefiles"
make -j`nproc`
sudo make install
cd ..

rm -rf ffmpeg && git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ffmpeg
rm -rf mpv && git clone --depth 1 https://github.com/mpv-player/mpv.git mpv 
rm -rf libass && git clone --depth 1 https://github.com/libass/libass.git libass

echo "--enable-libaom" > ffmpeg_options

echo "--enable-libmpv-shared --prefix=/usr" > mpv_options
echo "--disable-caca --disable-wayland --disable-gl-wayland --disable-libarchive  --disable-zlib  --disable-tv --disable-debug-build --disable-manpage-build --disable-vapoursynth --disable-libsmbclient" >> mpv_options

./rebuild -j`nproc`
sudo ./install
cd ..
