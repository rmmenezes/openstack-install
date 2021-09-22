#!/bin/bash
set -x #echo on

sudo add-apt-repository cloud-archive:wallaby -y
sudo apt-get update -y
sudo apt-get upgrade -y

echo "FIM !"