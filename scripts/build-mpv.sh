#!/bin/bash
set -ex

CFLAGS="-fPIC -Os"

git clone --depth 1 https://github.com/mpv-player/mpv-build mpv-build || true
cd mpv-build

git clone --depth 1 https://github.com/mozilla/aom aom || true
mkdir aom-build || true
cd aom-build
../aom/configure --enable-pic --enable-av1 --enable-shared --prefix=/usr --disable-sse --disable-runtime-cpu-detect --disable-optimizations --enable-small --disable-mmx --disable-examples --disable-docs --disable-tools 
make -j`nproc`
sudo make install
cd ..

git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ffmpeg || true
git clone --depth 1 https://github.com/mpv-player/mpv.git mpv || true
git clone --depth 1 https://github.com/libass/libass.git libass || true

echo "--enable-libaom" > ffmpeg_options

echo "--enable-libmpv-shared --prefix=/usr" > mpv_options
echo "--disable-caca --disable-wayland --disable-gl-wayland --disable-libarchive  --disable-zlib  --disable-tv --disable-debug-build --disable-manpage-build --disable-vapoursynth --disable-libsmbclient" >> mpv_options

./rebuild -j`nproc`
sudo ./install
cd ..
