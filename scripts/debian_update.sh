#!/bin/bash
set -x #echo on

sudo DEBIAN_FRONTEND=noninteractive apt-get update -yq
apt-get install curl -y
curl http://osbpo.debian.net/osbpo/dists/pubkey.gpg | sudo apt-key add -

mv /etc/apt/sources.list /etc/apt/sources.list.original
cat ./files/debian/sources.list > /etc/apt/sources.list 

sudo DEBIAN_FRONTEND=noninteractive apt-get update -yq
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq
sudo DEBIAN_FRONTEND=noninteractive apt dist-upgrade -yq

echo "FIM !"