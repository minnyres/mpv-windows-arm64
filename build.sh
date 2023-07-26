#!/bin/bash

set -e
runtime=clang-aarch64
mpv_ver=v0.36.0

workdir=$(pwd)

pacman -S --needed git p7zip mingw-w64-${runtime}-{clang,pkg-config,ffmpeg,libjpeg-turbo,lua51,python,meson,rubberband,cmake,libva}

mkdir -p src
cd src
git clone --depth 1 --branch $mpv_ver https://github.com/mpv-player/mpv.git mpv_$mpv_ver
cd mpv_$mpv_ver

sed -i '6s/^/#undef MemoryBarrier\n/' ./video/out/opengl/ra_gl.c

meson setup build -Dlibmpv=true --prefix=$workdir/install/mpv --buildtype release --strip
meson compile -C build
meson install -C build

cd $workdir/install/mpv/bin
ldd mpv.exe | awk '{print $3}'| grep clangarm64 | xargs -I{} cp -u {} .

cd $workdir/install
7z a -mx9  mpv_${mpv_ver}_arm64.7z mpv