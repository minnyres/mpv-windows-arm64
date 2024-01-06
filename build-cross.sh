#!/bin/bash -e

shaderc_ver=2023.7
spirv_cross_ver=vulkan-sdk-1.3.268.0
libplacebo_ver=6.338.1
libbluary_ver=1.3.4
libsixel_ver=1.8.6
lua_ver=5.2.4
zimg_ver=3.0.5
mpv_ver=0.37.0

prefix_dir=$PWD/mpv-depends
mkdir -p "$prefix_dir"
[ -z "$vcpkg_dir" ] && vcpkg_dir=$PWD/vcpkg
vcpkg_libs_dir=$vcpkg_dir/installed/arm64-mingw-static-release
[ -z "$llvm_dir" ] && llvm_dir=$PWD/llvm-mingw

wget="wget -nc --progress=bar:force"
gitclone="git clone --depth=1 --recursive"

export PATH=$llvm_dir/bin:$PATH
export TARGET=aarch64-w64-mingw32
export CC=$TARGET-gcc
export CXX=$TARGET-g++
export AR=$TARGET-ar
export NM=$TARGET-nm
export RANLIB=$TARGET-ranlib
export STRIP=$TARGET-strip

export CFLAGS="-O2 -I$prefix_dir/include -I$vcpkg_libs_dir/include"
export CXXFLAGS=$CFLAGS
export CPPFLAGS="-I$prefix_dir/include -I$vcpkg_libs_dir/include"
export LDFLAGS="--static -L$prefix_dir/lib -L$vcpkg_libs_dir/lib"

# anything that uses pkg-config
export PKG_CONFIG=/usr/bin/pkg-config
export PKG_CONFIG_LIBDIR="$prefix_dir/lib/pkgconfig:$vcpkg_libs_dir/lib/pkgconfig"
export PKG_CONFIG_PATH=$PKG_CONFIG_LIBDIR

# autotools(-like)
commonflags="--prefix=$prefix_dir --host=$TARGET --enable-static --enable-shared=no"

# CMake
cmake_args=(
    -G "Ninja" -B "build"
    -Wno-dev
    -DCMAKE_SYSTEM_NAME=Windows
    -DCMAKE_FIND_ROOT_PATH="$prefix_dir;$vcpkg_libs_dir"
    -DCMAKE_RC_COMPILER="${TARGET}-windres"
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=$prefix_dir
)

# Meson
meson_args=(
    --buildtype release --strip
    --cross-file "$prefix_dir/../cross.txt"
)

function cmakeplusinstall {
    cmake --build build
    cmake --install build
}

function gnumakeplusinstall {
    make -j $(nproc)
    make install
}

function mesonmakeplusinstall {
    meson compile -C build
    meson install -C build
}

mkdir -p src
mkdir -p $prefix_dir/lib/pkgconfig/ 
cd src

# zimg
[ -d zimg ] || $gitclone --branch release-$zimg_ver https://github.com/sekrit-twc/zimg.git 
pushd zimg
./autogen.sh
./configure $commonflags
sed -i 's|Windows.h|windows.h|g' src/zimg/common/arm/cpuinfo_arm.cpp
gnumakeplusinstall
popd

# libsixel
[ -d libsixel ] || $gitclone --branch v$libsixel_ver https://github.com/saitoha/libsixel.git
pushd libsixel
cross_compile=yes ./configure $commonflags --disable-debug 
sed -i 's|HAVE_MALLOC 0|HAVE_MALLOC 1|g' config.h
sed -i 's|HAVE_REALLOC 0|HAVE_REALLOC 1|g' config.h
sed -i '/rpl_malloc/d' config.h
sed -i '/rpl_realloc/d' config.h
gnumakeplusinstall
popd

# libbluary
[ -d libbluray ] || $gitclone --branch $libbluary_ver https://code.videolan.org/videolan/libbluray.git
pushd libbluray
./bootstrap 
./configure $commonflags --enable-largefile --disable-bdjava-jar --without-external-libudfread --disable-examples --enable-optimizations
gnumakeplusinstall
popd

# lua52
[ -d lua-$lua_ver ] || $wget https://www.lua.org/ftp/lua-$lua_ver.tar.gz
tar xf lua-$lua_ver.tar.gz
pushd lua-$lua_ver
sed -i 's/strip /'$STRIP' /g' src/Makefile
make CC=$CC AR="$AR rcu" RANLIB=$RANLIB STRIP=$STRIP mingw
make \
    TO_BIN="lua.exe luac.exe lua52.dll" \
    TO_LIB="liblua.a" \
    INSTALL_DATA='cp -d' \
    INSTALL_TOP=$prefix_dir \
    install
popd
cp $prefix_dir/../lua52.pc $prefix_dir/lib/pkgconfig/lua52.pc
sed -i 's|lua_prefix|'$prefix_dir'|g' $prefix_dir/lib/pkgconfig/lua52.pc

# shaderc
[ -d shaderc ] || $gitclone --branch v$shaderc_ver https://github.com/google/shaderc.git
pushd shaderc
./utils/git-sync-deps
cmake "${cmake_args[@]}" \
    -DBUILD_SHARED_LIBS=OFF -DSHADERC_SKIP_TESTS=ON
cmakeplusinstall
popd
sed -i 's|-lshaderc_combined|-lshaderc_combined -lc++|g'  $prefix_dir/lib/pkgconfig/shaderc_combined.pc

# SPIRV-Cross
[ -d SPIRV-Cross ] || $gitclone --branch $spirv_cross_ver https://github.com/KhronosGroup/SPIRV-Cross
pushd SPIRV-Cross
git apply $prefix_dir/../patches/spirv-cross-0001-static-linking-hacks.patch
cmake "${cmake_args[@]}" \
    -DSPIRV_CROSS_SHARED=ON -DBUILD_SHARED_LIBS=OFF -DSPIRV_CROSS_CLI=OFF
cmakeplusinstall
git restore .
popd

# libplacebo
[ -d libplacebo ] || $gitclone --branch v$libplacebo_ver https://github.com/haasn/libplacebo.git
pushd libplacebo
meson setup build "${meson_args[@]}"     --prefix=$prefix_dir \
    -D{demos,tests}=false -D{vulkan,d3d11,lcms,shaderc,xxhash}=enabled \
    --default-library=static --prefer-static
mesonmakeplusinstall
popd

# mpv
export CFLAGS="$CFLAGS -I$vcpkg_libs_dir/include/uchardet"
export LDFLAGS="$LDFLAGS -liconv"
[ -d mpv ] || $gitclone --branch v$mpv_ver https://github.com/mpv-player/mpv.git
pushd mpv
sed -i '6s/^/#undef MemoryBarrier\n/' ./video/out/opengl/ra_gl.c
meson setup build "${meson_args[@]}" --prefix=$prefix_dir/../install/mpv  \
    -Dlibmpv=true \
    -D{shaderc,spirv-cross,d3d11}=enabled \
    --prefer-static
mesonmakeplusinstall
popd

sed -i 's|-lshaderc_combined -lc++|-lshaderc_combined|g'  $prefix_dir/lib/pkgconfig/shaderc_combined.pc

cd $prefix_dir/../install
cp $vcpkg_libs_dir/bin/vulkan-1.dll mpv/bin
$STRIP mpv/bin/*.dll
$STRIP mpv/bin/*.dll
7z a -mx9 mpv_${mpv_ver}_arm64.7z mpv
mv mpv_${mpv_ver}_arm64.7z ..