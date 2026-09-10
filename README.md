# mpv-windows-arm64
[mpv](https://mpv.io/) is a free, open source, and cross-platform media player. This repository builds mpv for Windows on ARM64 (WoA).

The downloads are available on the [releases](https://github.com/minnyres/mpv-windows-arm64/releases) page.

We also support [SMPlayer for WoA](https://github.com/minnyres/smplayer-windows-arm64), which is based on mpv and has a more convenient GUI.

## How to build
There are two methods to build [mpv](https://mpv.io/) for Windows ARM64:
+ cross compile on x64 Windows with MSVC and Clang, see the [MSVC workflow](https://github.com/minnyres/mpv-windows-arm64/blob/main/.github/workflows/release_msvc.yml)
+ cross compile on a GNU/Linux system with the llvm-mingw toolchain, see the [llvm-mingw workflow](https://github.com/minnyres/mpv-windows-arm64/blob/main/.github/workflows/release_mingw.yml)

The latest release is built with the MSVC workflow.
