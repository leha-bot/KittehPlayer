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

mkdir other_libs
cd other_libs
export OTHER_LIBS=`pwd`


wget -nc "https://github.com/webmproject/libvpx/archive/v1.7.0.tar.gz" && tar xvf "v1.7.0.tar.gz"
cd libvpx*
./configure --prefix=/usr --disable-unit-tests --disable-shared
make -j`nproc`
sudo make install
cd $OTHER_LIBS

wget "http://kent.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz"  && tar xvf "lame-3.100.tar.gz"
cd lame-3.100 || exit
./configure --prefix=/usr --disable-shared --enable-static
make -j`nproc`
sudo make install
cd $OTHER_LIBS

wget "http://downloads.xvid.org/downloads/xvidcore-1.3.4.tar.gz" && tar xvf "xvidcore-1.3.4.tar.gz"
cd xvidcore
cd build/generic
./configure --prefix=/usr --disable-shared --enable-static
make -j`nproc`
sudo make install
cd $OTHER_LIBS


wget "http://ftp.videolan.org/pub/x264/snapshots/x264-snapshot-20180531-2245.tar.bz2" && tar xvf "x264-snapshot-20180531-2245.tar.bz2"
cd x264-snapshot-*
./configure --prefix=/usr --enable-static --enable-pic CXXFLAGS="-fPIC"
make -j`nproc`
sudo make install
sudo make install-lib-static
cd $OTHER_LIBS


wget "http://downloads.xiph.org/releases/ogg/libogg-1.3.3.tar.gz" && tar xvf "libogg-1.3.3.tar.gz"
cd libogg-1.3.3 || exit
./configure --prefix=/usr --disable-shared --enable-static
make -j`nproc`
sudo make install
cd $OTHER_LIBS

wget "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.6.tar.gz" && tar xvf "libvorbis-1.3.6.tar.gz"
cd libvorbis-1.3.6
./configure --prefix=/usr --enable-static --disable-shared --disable-oggtest
make -j`nproc`
sudo make install
cd $OTHER_LIBS


wget "http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.gz" && tar xvf "libtheora-1.1.1.tar.bz"
cd libtheora-1.1.1
sed "s/-fforce-addr//g" -i configure
./configure --prefix=/usr --enable-static --disable-shared --disable-oggtest --disable-vorbistest --disable-examples --disable-asm
make -j`nproc`
sudo make install
cd $OTHER_LIBS


cd $MPVDIR

#rm -rf ffmpeg mpv libass
git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ffmpeg
git clone --depth 1 https://github.com/mpv-player/mpv.git mpv
git clone --depth 1 https://github.com/libass/libass.git libass
#--enable-libaom
echo "--pkg-config-flags=\"--static\" --extra-libs=\"-lpthread -lm\" --enable-static --disable-debug --disable-shared --disable-ffplay --disable-doc --enable-gpl --enable-version3 --enable-nonfree --enable-pthreads --enable-libvpx --enable-libmp3lame --enable-libtheora --enable-libvorbis --enable-libx264 --enable-avfilter --enable-filters" > ffmpeg_options
echo "--disable-programs --disable-runtime-cpudetect --enable-small" >> ffmpeg_options
echo "--enable-libmpv-shared --prefix=/usr" > mpv_options
echo "--disable-caca --disable-wayland --disable-gl-wayland --disable-libarchive  --disable-zlib  --disable-tv --disable-debug-build --disable-manpage-build --disable-vapoursynth --disable-libsmbclient --disable-wayland" >> mpv_options

./rebuild -j`nproc`
sudo ./install
ccache -s

cd $OLDDIR
