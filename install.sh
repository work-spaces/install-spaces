#!/bin/bash

REPO="work-spaces" 
BINARY_NAME="spaces"  
VERSION="latest"       
INSTALL_DIR="$HOME/.local/bin"

# Ensure INSTALL_DIR exists
mkdir -p "$INSTALL_DIR"

# Detect the system type
detect_system() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Linux)
            OS="linux"
            ;;
        Darwin)
            OS="macos"
            ;;
        MINGW* | MSYS* | CYGWIN* | Windows_NT)
            OS="windows"
            ;;
        *)
            echo "Error: Unsupported OS $OS"
            exit 1
            ;;
    esac

    case "$ARCH" in
        x86_64)
            ARCH="x86_64"
            ;;
        arm64 | aarch64)
            ARCH="aarch64"
            ;;
        *)
            echo "Error: Unsupported architecture $ARCH"
            exit 1
            ;;
    esac

    SYSTEM="${OS}-${ARCH}"
    echo "Detected system: $SYSTEM"
}

# Function to download using curl or wget
download() {
    local url=$1
    local output=$2
    
    if command -v curl &> /dev/null; then
        curl -fsSL -o "$output" "$url"
    elif command -v wget &> /dev/null; then
        wget -q -O "$output" "$url"
    else
        echo "Error: Neither curl nor wget is available for downloading files."
        exit 1
    fi
}

# Run system detection
detect_system

# Determine the URL for the zip file
if [ "$VERSION" == "latest" ]; then
    VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
fi

ZIP_NAME="${BINARY_NAME}-${SYSTEM}-${VERSION}.zip"  # Zip file named based on system type
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/$ZIP_NAME"

# Download the zip file to a temporary location
TEMP_ZIP=$(mktemp)
download "$DOWNLOAD_URL" "$TEMP_ZIP"

# Check if download was successful
if [ ! -s "$TEMP_ZIP" ]; then
    echo "Error: Failed to download the zip file from $DOWNLOAD_URL"
    exit 1
fi

# Unzip the binary and move it to the installation directory
unzip -o "$TEMP_ZIP" -d /tmp
chmod +x "/tmp/$BINARY_NAME"
mv "/tmp/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"

# Clean up the temporary zip file
rm "$TEMP_ZIP"

echo "$BINARY_NAME has been installed in $INSTALL_DIR"

# Check if INSTALL_DIR is in PATH
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "Warning: $INSTALL_DIR is not in your PATH."
    echo "You may need to add the following to your ~/.bashrc or ~/.zshrc:"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\""
fi
