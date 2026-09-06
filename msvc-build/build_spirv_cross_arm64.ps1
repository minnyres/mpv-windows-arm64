$ErrorActionPreference = "Stop"

# Configuration
$SPIRV_CROSS_REPO = "https://github.com/KhronosGroup/SPIRV-Cross.git"
$SPIRV_CROSS_VERSION = "vulkan-sdk-1.4.357.0"

$WORKSPACE = $pwd
$INSTALL_PREFIX = Join-Path $WORKSPACE "install"

Set-Location $WORKSPACE

# Clone spirv-cross repository
Write-Host "Cloning spirv-cross..." -ForegroundColor Cyan

if (-not (Test-Path "SPIRV-Cross")) {
    git clone --recursive $SPIRV_CROSS_REPO --branch $SPIRV_CROSS_VERSION --depth 1 --recurse-submodules
} else {
    Write-Host "SPIRV-Cross directory already exists, skipping clone..." -ForegroundColor Yellow
}

Set-Location "SPIRV-Cross"

# Configure CMake for ARM64
Write-Host "Configuring CMake for ARM64..." -ForegroundColor Cyan

$cmakeArgs = @(
    "-B", "build",
    "-G", "Visual Studio 18 2026",
    "-A", "ARM64",
    "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX",
    "-DCMAKE_BUILD_TYPE=Release",
    "-DSPIRV_CROSS_STATIC=OFF",
    "-DSPIRV_CROSS_SHARED=ON",
    "-DBUILD_SHARED_LIBS=ON",
    "-DSPIRV_CROSS_CLI=OFF"
)

& cmake @cmakeArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "CMake configuration failed!" -ForegroundColor Red
    exit 1
}

# Build the project
Write-Host "Building spirv-cross..." -ForegroundColor Cyan
& cmake --build build --config Release --parallel

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

# Install the library
Write-Host "Installing spirv-cross..." -ForegroundColor Cyan
& cmake --install build --config Release

Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "Installed to: $INSTALL_PREFIX" -ForegroundColor Green

