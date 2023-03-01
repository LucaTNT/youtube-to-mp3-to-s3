#!/usr/bin/env bash
set -euo pipefail
IMAGE=${IMAGE:-"lucatnt/youtube-to-mp3-to-s3"}
PLATFORMS=${PLATFORMS:-"linux/amd64,linux/arm64,linux/arm/v7"}

tags=""
if [ $# -eq 0 ]
then
    echo "You need to supply the tag(s) for the image"
    echo "$0 TAG1 TAG2 ..."
    exit 1
else
    for tag in "${@}"; do
        tags="$tags -t $IMAGE:$tag"
    done
fi
docker buildx build $tags \
    --pull \
    --platform "$PLATFORMS" \
    -f Dockerfile \
    --push \
    .
