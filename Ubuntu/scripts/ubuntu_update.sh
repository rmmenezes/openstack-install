#!/bin/bash
set -x #echo on

sudo apt-get update -y
sudo apt-get upgrade -y
sudo add-apt-repository cloud-archive:wallaby -y

echo "FIM !"