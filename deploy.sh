#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
STAMP=$(date +%Y-%m-%d-%H%M%S)
OUT=~/builds/repos-musicsian-com/$STAMP
SITE_NAME="repos.musicsian.com"

mkdir -p "$OUT"

echo "▶ Staging files..."
# Only copy the essential files, exclude all the problematic directories
rsync -az --delete \
      --exclude deploy.sh --exclude .git --exclude PROJECT_README.md \
      --exclude current --exclude releases --exclude "*.sh" \
      "$PROJECT_DIR"/ "$OUT"/

echo "▶ Signing RPM packages..."
if command -v rpm >/dev/null 2>&1 && command -v gpg >/dev/null 2>&1; then
    # Sign all unsigned RPM packages
    for rpm_file in "$OUT"/RPMS/*.rpm; do
        if [ -f "$rpm_file" ]; then
            # Check if already signed
            if rpm -qp --qf '%{SIGPGP:pgpsig}' "$rpm_file" 2>/dev/null | grep -q "(none)"; then
                echo "🔐 Signing $(basename "$rpm_file")..."
                rpm --addsign "$rpm_file" 2>/dev/null || echo "⚠️  Failed to sign $(basename "$rpm_file")"
            else
                echo "✓ $(basename "$rpm_file") already signed"
            fi
        fi
    done
    echo "✓ RPM packages processed"
else
    echo "⚠️  RPM signing tools not available, skipping RPM signatures"
fi

echo "▶ Generating repository metadata..."
createrepo_c --update "$OUT"

echo "▶ Signing repository metadata..."
if command -v gpg >/dev/null 2>&1; then
    gpg --detach-sign --armor "$OUT"/repodata/repomd.xml
    echo "✓ Repository metadata signed"
else
    echo "⚠️  GPG not available, skipping signature"
fi

echo "▶ Publishing release..."
sudo mkdir -p /var/www/$SITE_NAME/releases/$STAMP
sudo rsync -az --delete "$OUT"/ /var/www/$SITE_NAME/releases/$STAMP/

echo "▶ Setting permissions..."
sudo chown -R nginx:nginx /var/www/$SITE_NAME/releases/$STAMP
sudo find /var/www/$SITE_NAME/releases/$STAMP -type d -exec chmod 755 {} \;
sudo find /var/www/$SITE_NAME/releases/$STAMP -type f -exec chmod 644 {} \;

echo "▶ Restoring SELinux labels..."
sudo restorecon -Rv /var/www/$SITE_NAME/releases/$STAMP >/dev/null

echo "▶ Flipping current symlink..."
sudo ln -nfs /var/www/$SITE_NAME/releases/$STAMP /var/www/$SITE_NAME/current

echo "▶ Testing nginx config..."
sudo nginx -t

echo "▶ Reloading Nginx..."
sudo systemctl reload nginx

echo "✓ Deployed $STAMP to $SITE_NAME"
echo "🌐 Site available at: https://$SITE_NAME/"

# Test the deployment
echo "▶ Testing site..."
if curl -s -o /dev/null -w "%{http_code}" "https://$SITE_NAME" | grep -q "200\|301\|302"; then
    echo "✅ Site is responding!"
else
    echo "⚠️  Site may not be responding yet (check DNS/firewall)"
fi

echo "▶ Testing repository metadata..."
if curl -s -f "https://$SITE_NAME/repodata/repomd.xml" >/dev/null; then
    echo "✅ Repository metadata accessible"
    
    # Test GPG signature if present
    if curl -s -f "https://$SITE_NAME/repodata/repomd.xml.asc" >/dev/null; then
        echo "✅ GPG signature present"
    else
        echo "⚠️  No GPG signature found"
    fi
else
    echo "❌ Repository metadata not accessible"
fi

echo "▶ Repository update complete!"
echo "Users can now run: sudo dnf update parrot"