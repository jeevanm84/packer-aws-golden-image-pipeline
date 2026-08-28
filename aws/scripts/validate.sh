#!/usr/bin/env bash
set -euo pipefail

test -s /var/www/html/index.html
test -s /etc/packer-image-release
command -v nginx >/dev/null
command -v curl >/dev/null
sudo nginx -t
systemctl is-enabled --quiet nginx
curl --fail --silent http://127.0.0.1/ | grep --quiet 'Packer golden image is running'
