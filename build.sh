#!/bin/bash

set -e
runtime=clang-aarch64
mpv_ver=v0.35.0

workdir=$(pwd)

pacman -S --needed git python mingw-w64-${runtime}-{clang,pkg-config,ffmpeg,libjpeg-turbo,lua51}

mkdir -p src
cd src
git clone --depth 1 --branch $mpv_ver https://github.com/mpv-player/mpv.git mpv_$mpv_ver
cd mpv_$mpv_ver

sed -i '6s/^/#undef MemoryBarrier\n/' ./video/out/opengl/ra_gl.c

/usr/bin/python3 bootstrap.py
/usr/bin/python3 waf configure CC=clang --check-c-compiler=clang --enable-libmpv-shared --prefix=$workdir/install/mpv
/usr/bin/python3 waf install

cd $workdir/install/mpv/bin
cp $(ldd mpv.exe | grep -v /c/WINDOWS) ./