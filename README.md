# mpv-windows-arm64
[mpv](https://mpv.io/) is a free, open source, and cross-platform media player. This repository builds mpv for Windows on ARM64 (WoA).

The downloads are available on the [releases](https://github.com/minnyres/mpv-windows-arm64/releases) page.

## How to build

It is natively built on Windows 11 ARM64.

1. Install [MSYS2-64bit](https://www.msys2.org/).
2. Enable and open the Clang ARM64 environment in MSYS2, following https://github.com/msys2/MSYS2-packages/issues/1787#issuecomment-980837586.
3. Run the build script `./build.sh`
