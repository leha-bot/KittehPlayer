#!/bin/bash
set -ex

mkdir -p $HOME/.cache/apt/partial
sudo rm -rf /var/cache/apt/archives
sudo ln -s $HOME/.cache/apt /var/cache/apt/archives
sudo add-apt-repository ppa:beineri/opt-qt-5.11.1-xenial -y
sudo apt-get update 

sudo apt-get -y install libxpm-dev libcurl3 libcurl4-openssl-dev automake libtool desktop-file-utils libjack0 libjack-dev nasm ccache qt511-meta-minimal qt511quickcontrols qt511quickcontrols2 qt511imageformats qt511svg libgl1-mesa-dev checkinstall
sudo apt-get build-dep libmpv1
source /opt/qt*/bin/qt*-env.sh

bash scripts/build-mpv.sh
bash scripts/makeappimage.sh

bash scripts/upload.sh