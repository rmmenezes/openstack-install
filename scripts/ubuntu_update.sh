#!/bin/bash
set -x #echo on

# Carregando as variaveis no ambiente
chmod 777 ../variables.sh
../variables.sh
source ~/.bashrc


sudo add-apt-repository cloud-archive:wallaby -y
sudo apt-get update -y
sudo apt-get upgrade -y

echo "FIM !"