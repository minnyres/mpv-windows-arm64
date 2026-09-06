$ErrorActionPreference = "Stop"

# Configuration
$MPV_REPO = "https://github.com/mpv-player/mpv.git"
$MPV_VERSION = "v0.41.0"

$WORKSPACE = $pwd
$INSTALL_PREFIX = Join-Path $WORKSPACE "install"
$crossFilePath = Join-Path $WORKSPACE "arm64_cross.txt"
$MPV_INSTALL_PREFIX = Join-Path $WORKSPACE "mpv-arm64"

$PKG_CONFIG_PATH1 = Join-Path $VCPKG_LIB_DIR "lib\pkgconfig"
$PKG_CONFIG_PATH2 = Join-Path $INSTALL_PREFIX "lib\pkgconfig"

# Convert backslashes to forward slashes for Meson
$VCPKG_LIB_DIR = $VCPKG_LIB_DIR -replace '\\', '/'
$PKG_CONFIG_PATH1 = $PKG_CONFIG_PATH1 -replace '\\', '/'
$PKG_CONFIG_PATH2 = $PKG_CONFIG_PATH2 -replace '\\', '/'
$crossFilePath = $crossFilePath -replace '\\', '/'
$INSTALL_PREFIX = $INSTALL_PREFIX -replace '\\', '/'
$MPV_INSTALL_PREFIX = $MPV_INSTALL_PREFIX -replace '\\', '/'

Set-Location $WORKSPACE

# Clone mpv repository
Write-Host "Cloning mpv..." -ForegroundColor Cyan

if (-not (Test-Path "mpv")) {
    git clone --recursive $MPV_REPO --branch $MPV_VERSION --depth 1 --recurse-submodules
} else {
    Write-Host "mpv directory already exists, skipping clone..." -ForegroundColor Yellow
}

Set-Location "mpv"
New-Item -ItemType Directory -Force -Path "build" | Out-Null

# Configure Meson for ARM64
Write-Host "Configuring Meson for ARM64..." -ForegroundColor Cyan

$mesonArgs = @(
    "setup",
    "build",
    "--cross-file", $crossFilePath,
    "--prefix=$MPV_INSTALL_PREFIX",
    "-Ddefault_library=shared",
    "-Dbuildtype=release",
    "-Dlua=luajit",
    "-Dvulkan=enabled",
    "-Ddvdnav=enabled",
    "-Dcdda=disabled",
    "-Djack=disabled",
    "-Dlibarchive=enabled",
    "-Dlua=enabled",
    "-Duchardet=enabled",
    "-Dzimg=disabled",
    "-Dspirv-cross=enabled",
    "-Dshaderc=enabled",
    "-Dd3d11=enabled",
    "-Dopenal=enabled",
    "-Dpkg_config_path=$PKG_CONFIG_PATH1;$PKG_CONFIG_PATH2",
    "-Dc_args=-I$VCPKG_LIB_DIR/include",
    "-Dcpp_args=-I$VCPKG_LIB_DIR/include",
    "-Dc_link_args=-L$VCPKG_LIB_DIR/lib",
    "-Dcpp_link_args=-L$VCPKG_LIB_DIR/lib"
)

& meson @mesonArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "Meson configuration failed!" -ForegroundColor Red
    exit 1
}

# Compile the project
Write-Host "Compiling mpv..." -ForegroundColor Cyan
meson compile -C build

if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed!" -ForegroundColor Red
    exit 1
}

# Install the library
Write-Host "Installing mpv..." -ForegroundColor Cyan
meson install -C build

# Copy required DLL dependencies
Write-Host "Copying DLL dependencies..." -ForegroundColor Cyan
$MPV_INSTALL_BIN = Join-Path $MPV_INSTALL_PREFIX "bin"
$VCPKG_BIN = Join-Path $VCPKG_LIB_DIR "bin"
$MPV_EXE = Join-Path $MPV_INSTALL_BIN "mpv.exe"
Copy-Item -Path $INSTALL_PREFIX/bin/*.dll -Destination $MPV_INSTALL_BIN -Force

$env:path = "$VCPKG_BIN;$env:path"

$output = & ntldd -R $MPV_EXE 2>&1 | Out-String
$imports = [regex]::Matches($output, '(\S+\.dll)\s*=>\s+(?!not found)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

foreach ($dll in $imports) {
    $dllPath = Join-Path $VCPKG_BIN $dll
    Write-Host "Checking: $dllPath"
    if (Test-Path $dllPath) {
        Copy-Item -Path $dllPath -Destination $INSTALL_BIN -Force
    }
}

Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "Installed to: $INSTALL_PREFIX" -ForegroundColor Green