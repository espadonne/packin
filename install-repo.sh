#!/usr/bin/env bash
# Install script for musicsian repository
set -euo pipefail

REPO_NAME="musicsian"
REPO_URL="https://repos.musicsian.com"
GPG_KEY_URL="$REPO_URL/RPM-GPG-KEY-musicsian"

echo "🎵 Setting up Musicsian Repository"
echo "=================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "❌ Please don't run this script as root"
    echo "   Run: bash install-repo.sh"
    exit 1
fi

# Import GPG key
echo "▶ Importing GPG key..."
if curl -s -f "$GPG_KEY_URL" | sudo rpm --import -; then
    echo "✅ GPG key imported successfully"
else
    echo "❌ Failed to import GPG key"
    echo "   You may need to use --nogpgcheck for package installation"
fi

# Create repository file
echo "▶ Installing repository configuration..."
sudo tee /etc/yum.repos.d/$REPO_NAME.repo > /dev/null << EOF
[$REPO_NAME]
name=$REPO_NAME - Fresh RPM packages for Linux
baseurl=$REPO_URL
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=$GPG_KEY_URL
EOF

echo "✅ Repository configuration installed"

# Test repository
echo "▶ Testing repository access..."
if sudo dnf repolist enabled | grep -q "$REPO_NAME"; then
    echo "✅ Repository is enabled and accessible"
    
    echo "▶ Available packages:"
    sudo dnf list available --repo="$REPO_NAME" | grep -E "parrot|cue|fortbite|gitswitch|shellp|shtick|sultree|waveterm|wezztershier|wmswitch" || true
else
    echo "⚠️  Repository may not be accessible yet"
    echo "   Try: sudo dnf clean all && sudo dnf repolist"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Install packages with:"
echo "  sudo dnf install parrot"
echo "  sudo dnf install cue"
echo "  sudo dnf install gitswitch"
echo "  # ... etc"
echo ""
echo "Update packages with:"
echo "  sudo dnf update"
EOF