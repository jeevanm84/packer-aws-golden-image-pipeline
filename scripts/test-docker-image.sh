#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-packer-learning-web:latest}"

docker image inspect "$IMAGE_NAME" >/dev/null

output="$(docker run --rm "$IMAGE_NAME" bash -c "test -s /var/www/html/index.html && grep 'Packer image verified' /var/www/html/index.html")"

if [[ "$output" != *"Packer image verified"* ]]; then
  printf 'Docker image verification failed.\n' >&2
  exit 1
fi

printf 'Docker image verification passed for %s.\n' "$IMAGE_NAME"
