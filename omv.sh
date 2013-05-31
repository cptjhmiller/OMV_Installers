#!/bin/bash
#
#Setup Downloaders Miller style
cd /tmp
rm /tmp/omvinstalls.sh > /dev/null 2>&1
wget https://raw.github.com/cptjhmiller/OMV_Installers/master/omvinstalls.sh --no-check-certificate > /dev/null 2>&1
chmod a+x omvinstalls.sh > /dev/null 2>&1
sudo ./omvinstalls.sh
rm /tmp/omvinstalls.sh > /dev/null 2>&1