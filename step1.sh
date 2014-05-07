#!/bin/bash
#
# Agent I/O preparation "Step 1".
# Creates a raw instance that can be saved as an image.
# Users and tools can repeatedly deploy this image to create agents.
#
# MUST be run as root.
#

#
# Part 1: Runtime environment (Objective-C, GNUstep, Nu)
#
# Use this in a bare Ubuntu distribution to install 
# clang, libobjc2, GNUstep, and other dependencies that
# will allow you to build and run Nu.
#
# libobjc2 is an updated runtime that seeks compatibility 
# with Apple's modern Objective-C runtime. This new runtime
# allows Nu to be ported to Linux+GNUstep without difficulty.
#
# Tested with ubuntu-12.04.2-server-amd64.iso. 
# Other Ubuntu and Debian installations may also work well.
#

sudo apt-get update
sudo apt-get install curl -y
sudo apt-get install ssh -y
sudo apt-get install git -y
sudo apt-get install libreadline-dev -y
sudo apt-get install libicu-dev -y
sudo apt-get install openssl -y
sudo apt-get install build-essential -y
sudo apt-get install clang -y
sudo apt-get install libblocksruntime-dev -y
sudo apt-get install libkqueue-dev -y
sudo apt-get install libpthread-workqueue-dev -y
sudo apt-get install gobjc -y
sudo apt-get install libxml2-dev -y
sudo apt-get install libjpeg-dev -y
sudo apt-get install libtiff-dev -y
sudo apt-get install libpng12-dev -y
sudo apt-get install libgnutls-dev -y

sudo apt-get remove libdispatch-dev -y
sudo apt-get install gdb -y

#
# Build libobjc2 and GNUstep
#
# A few modifications were needed to fix problems with 
# libobjc2 and gnustep-base. To maintain stability, we
# work with a fork on github.
#
git clone https://github.com/timburks/gnustep-libobjc2.git
git clone https://github.com/timburks/gnustep-make.git
git clone https://github.com/timburks/gnustep-base.git

echo Installing libobjc2
export CC=clang

cd gnustep-libobjc2
make clean
make
sudo make install
cd ..

cd gnustep-make
./configure
make clean
make
sudo make install
cd ..

cd gnustep-base
./configure
make clean
make
sudo make install
cd ..

sudo apt-get install libdispatch-dev -y

#
# Build Nu
#
git clone https://github.com/timburks/nu.git

cd nu
git checkout master
make
./mininush tools/nuke install
cd ..

#
# Build Agent component frameworks
#
sudo apt-get install libevent-dev -y
sudo apt-get install uuid-dev -y
sudo apt-get install libssl-dev -y
sudo apt-get install cmake -y

git clone https://github.com/timburks/libevhtp
cd libevhtp/build
cmake ..
make
make install
cd ../..

git clone https://github.com/timburks/agent-frameworks.git

cd agent-frameworks/AgentHTTP
nuke install
cd ../AgentJSON
nuke install
cd ../AgentXML
nuke install
cd ../AgentCrypto
nuke install
cd ../AgentMongoDB
nuke install
cd ../AgentKit
nuke install
cd ../..

#
# Part 2: Third-party Agent I/O components
#
# This installs nginx, mongodb, postfix, dovecot
# and any other third-party necessities not previously
# installed.
#

apt-get install nginx -y
apt-get install unzip -y

# mail setup
aptitude remove exim4 && aptitude install postfix && postfix stop
aptitude install dovecot-core dovecot-imapd
# aptitude install dovecot-common # might not be necessary

# this is installed earlier, but we don't need to keep it
apt-get uninstall whoopsie

# get mongodb from the official mongodb repository, we want 2.6 or later
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | 
tee /etc/apt/sources.list.d/mongodb.list
apt-get update
apt-get install mongodb-org

#
# Part 3: Install CONTROL, the Agent I/O monitor
# 
# This web service provides an API for remotely administering an agent.
# It also includes tools that configure nginx as a container for agent HTTP services.
#

adduser --system -disabled-login control 
addgroup control

# replace /home/control with the agent-control repository
rm -rf /home/control
git clone https://github.com/timburks/agent-control.git
cp -r agent-control /home/control

cd /home/control
mkdir -p nginx/logs
mkdir -p var
mkdir -p workers
chown -R control /home/control
chgrp -R control /home/control

cp upstart/agentio-control.conf /etc/init
initctl start agentio-control

#
# That's it! Now save your image or remotely configure it (Step 2).
#
echo "Agent training is complete."


