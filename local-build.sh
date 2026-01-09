#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

BRANCH="test"
RUNTIME_VERSION="${RUNTIME_VERSION:-25.08}"

# Function to print error messages
error() {
    echo "Error: $1" >&2
    exit 1
}

# Function to check if a command exists
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        error "$cmd is not installed. Please install $cmd and try again."
    fi
    echo "$cmd is installed."
}

# Default build settings
BUILD_TYPE="release"
CARGO_RELEASE_FLAG="--release"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--debug)
            BUILD_TYPE="debug"
            CARGO_RELEASE_FLAG=""
            echo "Debug build enabled."
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -d, --debug    Build in debug mode"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        *)
            error "Unknown parameter passed: $1"
            ;;
    esac
done

# Check if flatpak is installed
check_command "flatpak"

# Check if flatpak-builder is installed
check_command "flatpak-builder"

# Define required Flatpak packages
REQUIRED_FLATPAK_PACKAGES=(
    "org.freedesktop.Platform//${RUNTIME_VERSION}"
    "org.freedesktop.Sdk//${RUNTIME_VERSION}"
    "org.freedesktop.Sdk.Extension.rust-stable//${RUNTIME_VERSION}"
    "org.freedesktop.Sdk.Extension.llvm21//${RUNTIME_VERSION}"
)

# Function to check if a Flatpak package is installed
is_flatpak_installed() {
    local package="$1"
    flatpak info "$package" &> /dev/null
}

# Install missing Flatpak packages
for package in "${REQUIRED_FLATPAK_PACKAGES[@]}"; do
    if is_flatpak_installed "$package"; then
        echo "Flatpak package '$package' is already installed."
    else
        echo "Flatpak package '$package' is not installed. Installing..."
        flatpak install -y flathub "$package" || error "Failed to install $package"
    fi
done

# Update Flatpak repositories
echo "Updating Flatpak repositories..."
flatpak update -y || error "Failed to update Flatpak repositories"

# Clean previous build artifacts
echo "Cleaning previous build artifacts..."
rm -f org.naev.Naev.flatpak
rm -rf _build _repo
mkdir _build _repo

# Build the Flatpak
echo "Building the Flatpak ($BUILD_TYPE)..."

# Create a temporary manifest to inject build settings
# This is necessary because flatpak-builder does not have a CLI flag to pass environment variables
MANIFEST_BUILD="_build_org.naev.Naev.yaml"
trap "rm -f $MANIFEST_BUILD" EXIT

# We use sed to replace the placeholders in the manifest
# - NAEV_BUILDTYPE: debug or release
# - CARGO_RELEASE_FLAG: empty for debug, --release for release
sed -e "s/\${NAEV_BUILDTYPE:-release}/$BUILD_TYPE/g" \
    -e "s/\${CARGO_RELEASE_FLAG---release}/$CARGO_RELEASE_FLAG/g" \
    org.naev.Naev.yaml > "$MANIFEST_BUILD"

flatpak-builder --ccache --force-clean --default-branch="$BRANCH" \
    _build "$MANIFEST_BUILD" --repo=_repo || error "flatpak-builder failed"

# Bundle the Flatpak
echo "Bundling the Flatpak..."
flatpak build-bundle _repo org.naev.Naev.flatpak org.naev.Naev "$BRANCH" || error "flatpak build-bundle failed"

echo "Flatpak build and bundle completed successfully."
