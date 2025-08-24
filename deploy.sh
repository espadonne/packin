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

echo "▶ Generating repository metadata..."
createrepo_c --update "$OUT"

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