#!/bin/bash

export REPO="work-spaces/spaces" 
export BINARY_NAME="spaces"  
export INSTALL_DIR="$HOME/.local/bin"

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

# Run system detection
detect_system

# Determine the URL for the zip file
LATEST_URL=https://api.github.com/repos/$REPO/releases/latest
echo "Get version for latest release from: $LATEST_URL"
curl -fsSL $LATEST_URL > latest.txt
VERSION=$(curl -fsSL "$LATEST_URL" | sed -n 's/.*"tag_name": "\(.*\)".*/\1/p')

 # Zip file named based on system type
ZIP_NAME=$BINARY_NAME-$SYSTEM-$VERSION.zip 
DOWNLOAD_URL=https://github.com/$REPO/releases/download/$VERSION/$ZIP_NAME
echo "Downloading $DOWNLOAD_URL"

# Download the zip file to a temporary location
TEMP_ZIP=$(mktemp)
curl -fsSL -o "$TEMP_ZIP" "$DOWNLOAD_URL"

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
