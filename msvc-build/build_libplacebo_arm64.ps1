$ErrorActionPreference = "Stop"

# Configuration
$LIBPLACEBO_REPO = "https://github.com/haasn/libplacebo.git"
$LIBPLACEBO_VERSION = "v7.360.1"

$WORKSPACE = $pwd
$INSTALL_PREFIX = Join-Path $WORKSPACE "install"
$crossFilePath = Join-Path $WORKSPACE "arm64_cross.txt"

$PKG_CONFIG_PATH1= Join-Path $VCPKG_LIB_DIR "lib\pkgconfig"
$PKG_CONFIG_PATH2= Join-Path $INSTALL_PREFIX "lib\pkgconfig"

Set-Location $WORKSPACE

# Clone libplacebo repository
Write-Host "Cloning libplacebo..." -ForegroundColor Cyan

if (-not (Test-Path "libplacebo")) {
    git clone --recursive $LIBPLACEBO_REPO --branch $LIBPLACEBO_VERSION --depth 1 --recurse-submodules
} else {
    Write-Host "libplacebo directory already exists, skipping clone..." -ForegroundColor Yellow
}

Set-Location "libplacebo"
New-Item -ItemType Directory -Force -Path "build" | Out-Null

# Configure Meson for ARM64
Write-Host "Configuring Meson for ARM64..." -ForegroundColor Cyan

$mesonArgs = @(
    "setup",
    "build",
    "--cross-file", $crossFilePath,
    "--prefix=$INSTALL_PREFIX",
    "-Ddefault_library=shared",
    "-Dbuildtype=release",
    "-Ddemos=false",
    "-Dtests=false",
    "-Dvulkan=enabled",
    "-Dd3d11=enabled",
    "-Dlcms=enabled",
    "-Dshaderc=enabled",
    "-Dxxhash=enabled",
    "-Dpkg_config_path=$PKG_CONFIG_PATH1;$PKG_CONFIG_PATH2"
)

# Run meson setup
& meson @mesonArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "Meson configuration failed!" -ForegroundColor Red
    exit 1
}

# Compile the project
Write-Host "Compiling libplacebo..." -ForegroundColor Cyan
meson compile -C build

if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed!" -ForegroundColor Red
    exit 1
}

# Install the library
Write-Host "Installing libplacebo..." -ForegroundColor Cyan
meson install -C build

Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "Installed to: $INSTALL_PREFIX" -ForegroundColor Green

Set-Location $WORKSPACE