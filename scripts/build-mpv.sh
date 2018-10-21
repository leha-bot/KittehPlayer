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
#mkdir aom -p
#cd aom
#git clone --depth 1 https://aomedia.googlesource.com/aom
#cmake aom/ -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=1 -DENABLE_TESTS=0 -G "Unix Makefiles"
#make 
#sudo checkinstall -y --deldoc=yes
#sudo make install
#cd $MPVDIR

#rm -rf ffmpeg mpv libass
git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ffmpeg
git clone --depth 1 https://github.com/mpv-player/mpv.git mpv
git clone --depth 1 https://github.com/libass/libass.git libass
#--enable-libaom
echo " " > ffmpeg_options
echo "--disable-programs --disable-runtime-cpudetect --enable-small" >> ffmpeg_options
echo "--enable-libmpv-shared --prefix=/usr" > mpv_options
echo "--disable-caca --disable-wayland --disable-gl-wayland --disable-libarchive  --disable-zlib  --disable-tv --disable-debug-build --disable-manpage-build --disable-vapoursynth --disable-libsmbclient --disable-wayland" >> mpv_options

./rebuild -j`nproc`
sudo ./install
ccache -s

cd $OLDDIR
