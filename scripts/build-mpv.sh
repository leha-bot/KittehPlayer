#!/bin/bash
set -ex

CFLAGS="-fPIC -Os"

git clone --depth 1 https://github.com/mpv-player/mpv-build mpv-build || true
cd mpv-build

git clone --depth 1 http://aomedia.googlesource.com/aom aom || true
mkdir aom-build || true
cd aom-build
  cmake -G Ninja ../aom \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DBUILD_SHARED_LIBS=1 \
    -DENABLE_TESTS=0
  cmake --build .
  sudo cmake --build . --target install
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
