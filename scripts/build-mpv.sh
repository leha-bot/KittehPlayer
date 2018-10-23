#!/bin/bash
set -x

export OLDDIR=`pwd`
export PATH="/usr/lib/ccache:/usr/lib/ccache/bin:$PATH"

export CFLAGS="-fPIC -Os"


export V=0 VERBOSE=0

#rm -rf mpv-build
git clone --depth 1 https://github.com/mpv-player/mpv-build mpv-build
cd mpv-build

export MPVDIR=`pwd`



cd $MPVDIR

#rm -rf ffmpeg mpv libass
git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ffmpeg
git clone --depth 1 https://github.com/mpv-player/mpv.git mpv
git clone --depth 1 https://github.com/libass/libass.git libass
#--enable-libaom
echo '--disable-debug --disable-shared --disable-ffplay --disable-doc --enable-gpl --enable-version3 --enable-nonfree --enable-pthreads --enable-libvpx --enable-libmp3lame --enable-libtheora --enable-libvorbis --enable-libx264 --enable-avfilter --enable-filters' > ffmpeg_options
echo "--disable-programs --disable-runtime-cpudetect --enable-small" >> ffmpeg_options
echo "--enable-libmpv-shared --prefix=/usr" > mpv_options
echo "--disable-caca --disable-wayland --disable-gl-wayland --disable-libarchive  --disable-zlib  --disable-tv --disable-debug-build --disable-manpage-build --disable-vapoursynth --disable-libsmbclient --disable-wayland" >> mpv_options

sudo ./build -j`nproc`
sudo ./install
ccache -s

cd $OLDDIR
