#!/usr/bin/env bash

echo "--- Initialize Environment"
if [ -f live-image-amd64.hybrid.iso ]; then
    rm -rf live-image-amd64.hybrid.iso
fi

mkdir -p cache
docker run --privileged --detach --name live-build --volume $(pwd):/repo --volume $(pwd)/cache:/workdir/cache --volume /proc:/proc --workdir /workdir debian:bookworm tail -f /.dockerenv

function runner() {
    echo "> $@"
    docker exec live-build $@
}

echo "--- Installing dependencies"
runner apt-get update
runner apt-get install -y live-build make build-essential wget git unzip colordiff apt-transport-https rename ovmf rsync python3-venv gnupg

echo "--- Creating directory structure"
runner mkdir -p /workdir
runner mkdir -p /workdir/auto
runner mkdir -p /workdir/config
runner cp -r /repo/auto/* /workdir/auto/
runner cp -r /repo/config/* /workdir/config/

echo "--- Grabbing extra packages"
runner mkdir -p /workdir/cache/downloads/ /workdir/config/packages/
runner wget "https://cdn.akamai.steamstatic.com/client/installer/steam.deb" -O /workdir/config/packages/steam.deb
runner wget "https://discord.com/api/download?platform=linux&format=deb" -O /workdir/config/packages/discord.deb
runner dpkg-name /workdir/config/packages/steam.deb
runner dpkg-name /workdir/config/packages/discord.deb

echo "--- Building"
runner lb clean --all
runner lb config
runner lb build

echo "--- Saving the iso"
runner cp /workdir/live-image-amd64.hybrid.iso /repo/live-image-amd64.hybrid.iso

echo "--- Cleaning up"
docker stop live-build
docker rm live-build
