#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install --yes --no-install-recommends ca-certificates curl nginx jq
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

sudo tee /var/www/html/index.html >/dev/null <<HTML
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Packer Golden Image</title></head>
<body>
  <h1>Packer golden image is running</h1>
  <p>Build commit: ${BUILD_COMMIT:-local}</p>
</body>
</html>
HTML

sudo systemctl enable nginx
sudo systemctl restart nginx

printf 'BUILD_COMMIT=%s\nBUILD_TIME=%s\n' \
  "${BUILD_COMMIT:-local}" \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  | sudo tee /etc/packer-image-release >/dev/null
