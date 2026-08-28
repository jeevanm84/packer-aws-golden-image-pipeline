#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --yes --no-install-recommends ca-certificates curl nginx
rm -rf /var/lib/apt/lists/*

printf '%s\n' \
  '<!doctype html>' \
  '<html lang="en">' \
  '<head><meta charset="utf-8"><title>Packer Learning Image</title></head>' \
  '<body><h1>Packer image verified</h1><p>Built by the beginner Docker lab.</p></body>' \
  '</html>' \
  > /var/www/html/index.html

nginx -t
