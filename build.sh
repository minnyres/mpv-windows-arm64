#!/bin/bash

set -e
runtime=clang-aarch64
mpv_ver=v0.37.0
libplacebo_ver=v6.338.1

workdir=$(pwd)

pacman -S --needed git p7zip mingw-w64-${runtime}-{clang,pkgconf,ffmpeg,libjpeg-turbo,luajit,uchardet,python,meson,rubberband,cmake,libva,spirv-cross,shaderc,lcms2,libdovi,vulkan,glslang,xxhash,egl-headers,angleproject}

# fetch sources
mkdir -p src
cd src
git clone --depth 1 --branch $mpv_ver https://github.com/mpv-player/mpv.git mpv_$mpv_ver
git clone --depth 1 --branch $libplacebo_ver https://code.videolan.org/videolan/libplacebo libplacebo_$libplacebo_ver

# build libplacebo
pushd libplacebo_$libplacebo_ver
git submodule update --init
dependsDir="$workdir/install/depends"
meson setup build --prefix=$dependsDir \
    --buildtype release --strip \
    -Ddemos=false \
    -Dtests=false \
    -Dd3d11=enabled \
    -Dlcms=enabled \
    -Dlibdovi=enabled \
    -Dshaderc=enabled \
    -Dvulkan=enabled 
meson compile -C build
meson install -C build
popd

# build mpv
cd mpv_$mpv_ver

sed -i '6s/^/#undef MemoryBarrier\n/' ./video/out/opengl/ra_gl.c
export PKG_CONFIG_PATH="$dependsDir/lib/pkgconfig"
export PATH="$dependsDir/bin:$PATH"
meson setup build -Dlibmpv=true --prefix=$workdir/install/mpv --buildtype release --strip
meson compile -C build
meson install -C build

cd $workdir/install/mpv/bin
ldd mpv.exe | awk '{print $3}'| grep clangarm64 | xargs -I{} cp -u {} .
ldd mpv.exe | awk '{print $3}'| grep $dependsDir | xargs -I{} cp -u {} .

cd $workdir/install
7z a -mx9  mpv_${mpv_ver}_arm64.7z mpv