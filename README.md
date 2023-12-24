# mpv-windows-arm64
[mpv](https://mpv.io/) is a free, open source, and cross-platform media player. This repository builds mpv for Windows on ARM64 (WoA).

The downloads are available on the [releases](https://github.com/minnyres/mpv-windows-arm64/releases) page.

## How to build
We support two methods to build [mpv](https://mpv.io/) for Windows ARM64:
+ native build on a Windows 11 ARM64 device with MSYS2, with the thirty-party dependencies dynamically linked
+ cross compile on a GNU/Linux system, which can statically link thirty-party dependencies and does not require an ARM64 device

The installation path of mpv is `./install/mpv`. 

### Native build with MSYS2

1. Install [MSYS2-64bit](https://www.msys2.org/).
2. Open the Clang ARM64 environment in MSYS2.
3. Run the build script `./build.sh`.

### Cross compile from GNU/Linux

A [workflow file](https://github.com/minnyres/mpv-windows-arm64/blob/main/.github/workflows/release.yml) is provided for example. First, install necessary tools for building, e.g.

    sudo apt install build-essential cmake ninja-build pkg-config p7zip nasm python3-pip
    sudo python3 -m pip install meson
    
on Debian. Download and install [llvm-mingw](https://github.com/mstorsjo/llvm-mingw) toolchain. Set the installation directory of llvm-mingw:

    export llvm_dir=<your-llvm-path>

Build some dependencies using vcpkg

    git clone https://github.com/microsoft/vcpkg.git
    cd vcpkg
    ./bootstrap-vcpkg.sh
    mkdir triplets_overlay
    cp triplets/community/arm64-mingw-static.cmake triplets_overlay/arm64-mingw-static-release.cmake
    echo "set(VCPKG_BUILD_TYPE release)" >> triplets_overlay/arm64-mingw-static-release.cmake
    packages="ffmpeg[ass,fdk-aac,freetype,fribidi,iconv,mp3lame,openssl,x264,zlib,xml2,opengl,lzma,bzip2,dav1d,fontconfig,openjpeg] xxhash lcms mujs libjpeg-turbo libarchive jack2 vulkan-loader"
    ./vcpkg install --overlay-triplets=triplets_overlay --triplet=arm64-mingw-static-release --allow-unsupported mp3lame
    ./vcpkg install --overlay-triplets=triplets_overlay --triplet=arm64-mingw-static-release --allow-unsupported $packages

Set the root directory of vcpkg:

    export vcpkg_dir=<your-vcpkg-path>

Then run the build script

    chmod 755 ./build-cross.sh
    ./build-cross.sh
