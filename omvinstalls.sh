#!/bin/bash
set -u
clear;
# My Junk Stuff #
################################################################################
#Setup Downloaders Miller style
#wget https://raw.github.com/cptjhmiller/OMV_Installers/master/omv.sh
#chmod a+x omv.sh
#./omv.sh
#3 5 8 9 10 11 12 15 16 17 18
# > /dev/null 2>&1
#sudo nano /etc/apt/sources.list
#at the end of the file add :
#Code: Select all
#deb http://ftp.debian.org/debian/ squeeze main contrib non-free
#change user #chown -hR $mainuser:$maingroup
#chown -R nobody:nogroup /usr/local/bin/SABnzbd-0.5.6
#adduser --disabled-login --gecos ,,,, --no-create-home downloaders > /dev/null 2>&1
#mkdir /home/downloaders > /dev/null 2>&1
#chown downloaders:downloaders -R/home/downloaders > /dev/null 2>&1
#Obtain the IP of the box
#useradd --user-group downloaders > /dev/null 2>&1
#git config --global http.proxy http://proxy:8080
#// To check the proxy settings
#git config --get http.proxy
#wget http://downloads.sourceforge.net/mediainfo/mediainfo_0.7.64-1_amd64.Debian_6.0.deb
#wget http://downloads.sourceforge.net/mediainfo/libmediainfo0_0.7.64-1_amd64.Debian_6.0.deb
#wget http://downloads.sourceforge.net/zenlib/libzen0_0.4.29-1_amd64.Debian_6.0.deb
#dpkg -i libzen0_0.4.29-1_amd64.Debian_6.0.deb
#dpkg -i libmediainfo0_0.7.64-1_amd64.Debian_6.0.deb
#dpkg -i mediainfo_0.7.64-1_amd64.Debian_6.0.deb
#rm libzen0_0.4.29-1_amd64.Debian_6.0.deb
#rm libmediainfo0_0.7.64-1_amd64.Debian_6.0.deb
#rm mediainfo_0.7.64-1_amd64.Debian_6.0.deb



################################################################################

###################
# SYSTEM varables #
###################
INSTALLDIR=""
mainuser="root"
maingroup="root"
OMV_V=`expr substr "$(cat /etc/issue)" 18 1`
. /etc/default/openmediavault
. /usr/share/openmediavault/scripts/helper-functions
#/usr/local/bin/python2.7
py="/usr/bin/python"
C_FILE=/etc/millers.cfg
PREFIX=MILLERSCONFIG
if [ ! -e $C_FILE ]; then
        IP=`ifconfig | grep "inet addr:" | head -n 1  | cut -d':' -f2 | cut -d' ' -f1`
        echo 'MILLERSCONFIG1=/
MILLERSCONFIG2='${IP}'
MILLERSCONFIG3=n' > $C_FILE
fi

save_variables()
{
    set | grep ^$PREFIX
}

show_variables()
{
    save_variables | while read line; do
      echo $1 $line
    done
}


. $C_FILE
ip=$MILLERSCONFIG2
INSTALLDIR=$MILLERSCONFIG1

screen()
{
clear;
echo "";
echo "    -------------------------------Millers-------------------------------";
echo "              OpenMediaVault Multi Application Installer V1.9.9          ";
echo "";
}

### Functions
f_aborted() {
	whiptail --title "Script cancelled" --backtitle "$BACKTITLE" --msgbox "         Aborted!" 7 32
	exit 0
}

# simple log-output
f_log() {
	echo "$1" >> $OMVLOGFILE
	echo "$1"
}

Clean()
{
## Cleaning script to update OMV savely from 0.4 to 0.5

# R. Lindlein aka Solo0815 in the OMV-Forums
# v 0.8.0

# Bugs fixed / features added:
# - typo
# - added removing js-files from jhmiller's script
# - one date to rule them all ;)
# - creating directory - forget variable (stupid me)
# - only external plugins are removed
# - fixed error in the rename *.js-files section
# - added purging of the website plugin and omv-plugins.org
# - added moving millers.list because the containing linux-mint entries it gave errors with OMV 0.5 
# - added removing other stuff from http://forums.openmediavault.org/viewtopic.php?f=14&t=2262&start=10#p15824
# - moved from sh to bash -> should resolve some errors with [[ ]] - changed it to single [
# - added code to get local.list back
###########################################################################################


SCRIPTDATE="$(date +%y%m%d-%H%M%S)"
TITLE="Clean OMV to upgrade from 0.4 to 0.5"
BACKTITLE="OMV-Upgrade-Cleaner"
OMVFOLDER_DEBS="/root/omv0.4_cleaning_for_0.5/"
OMVLOGFILE="/root/omv-0.5-cleaning_${SCRIPTDATE}.log"
OMVAPT="/etc/apt/sources.list.d"
OLDJSEXT="_omv0.4_$SCRIPTDATE"

###########################################################################################
### Begin of script

echo

whiptail --title "${TITLE}" --backtitle "${BACKTITLE}" --msgbox "This script will clean your OMV-Installation, so that you can upgrade from 0.4 to 0.5\n\nPlease read the following instructions carefully!" 11 78

whiptail --title "${TITLE}" --backtitle "${BACKTITLE}" --yesno --defaultno "To clean up your OMV-installation, the following steps are required:\n1. remove all external plugins.\n   The config is still there\n2. rename *.js-files in $OMV_DOCUMENTROOT_DIR/js/omv/module and admin/\n3. move all *.deb files and local.list in $OMVAPT/\n4. move old-omvplugins.org-lists\n\nDo you want to do this?" 15 78
[ $? = 0 ] || f_aborted

whiptail --title "${TITLE}" --backtitle "${BACKTITLE}" --yesno --defaultno "You are using this script at your own risk!\n\nAre you ready to reinstall OMV if something goes wrong or this script isn't working as expected?" 11 78
[ $? = 0 ] || f_aborted

whiptail --title "${TITLE}" --backtitle "${BACKTITLE}" --yesno --defaultno "You know, what you are doing?\n\nLogfile is $OMVLOGFILE" 8 78
[ $? = 0 ] || f_aborted

f_log "Cleaning started - $SCRIPTDATE"
f_log ""

### 1. remove all external plugins
f_log "1. remove all non- OMV-plugins"
PLUGINSTOREMOVE=$(apt-cache search openmediavault- | awk '{print $1}'| egrep -v 'openmediavault-(clamav|forkeddaapd|iscsitarget|keyring|ldap|lvm2|netatalk|nut|route|usbbackup)')

if [ "$PLUGINSTOREMOVE" = "" ]; then 
	f_log "There are no external PlugIns installed! Nothing to do here!"
else
	f_log "PlugIns to remove:"
	f_log "$PLUGINSTOREMOVE"
	f_log "Working ..."

	# Website-Plugin has to be purged
	if echo "$PLUGINSTOREMOVE" | egrep 'openmediavault-website'; then
		f_log "removing OMV-Website Plugin ... --purge"
		apt-get remove --purge -y -q openmediavault-website >> $OMVLOGFILE
	fi

	if echo "$PLUGINSTOREMOVE" | egrep 'openmediavault-omvpluginsorg'; then
		f_log "removing openmediavault-omvpluginsorg ... --purge"
		apt-get remove --purge -y -q openmediavault-omvpluginsorg >> $OMVLOGFILE
	fi
	
	f_log "removing normal PlugIns ..."
	PLUGINSTOREMOVE_new="$(echo "$PLUGINSTOREMOVE" | egrep -v 'openmediavault-website|omv-plugins.org')"
	apt-get remove -y -q $PLUGINSTOREMOVE_new >> $OMVLOGFILE
fi
sleep 1
f_log ""

### 2. rename *.js-files in $OMV_DOCUMENTROOT_DIR/js/omv/module/admin/"
f_log "2. rename *.js-files in $OMV_DOCUMENTROOT_DIR/js/omv/module/admin/"
if [ -f $OMV_DOCUMENTROOT_DIR/js/omv/module/admin/*.js ]; then
	f_log "Your folder for js-files:"
	ls $OMV_DOCUMENTROOT_DIR/js/omv/module/admin/*.js >> $OMVLOGFILE
	for OLDJSFILES in "$OMV_DOCUMENTROOT_DIR/js/omv/module/admin/"*.js; do
		mv "${OLDJSFILES}" "${OLDJSFILES}${OLDJSEXT}" && f_log "$OLDJSFILES renamed to ${OLDJSFILES}${OLDJSEXT}"
	done
else
	f_log "No old js-files in $OMV_DOCUMENTROOT_DIR/js/omv/module/admin found. Nothing to do here!"
fi
sleep 1
f_log ""

### 2a. Convert side panel items from OMV4 to OMV5
f_log "2a. Convert side panel items from OMV4 to OMV5"
sidepanel="AutoSub BicBucStriim CouchPotato CouchPotatoServer Deluge Extplorer GameZ HeadPhones LazyLibrarian Maraschino MusicCabinet MyLar PyLoad SABnzbd SickBeard SubSonic XDM"
for item in ${sidepanel[@]}; do
   if [ -f /var/www/openmediavault/js/omv/module/"$item".js ]; then
         f_log "Converting $item"
         address=$(sed '/window.open("http:\/\//!d;s//&\n/;s/.*\n//;:a;/","/bb;$!{n;ba};:b;s//\n&/;P;D' /var/www/openmediavault/js/omv/module/$item.js) #)
         rm -Rf /var/www/openmediavault/js/omv/module/$item.js
         mkdir -p /millers_temp/service/$item
         echo '/**
 * This file is not part of OpenMediaVault.
 */
// require("js/omv/WorkspaceManager.js")
// require("js/omv/workspace/form/Panel.js")
/**
 * @class OMV.module.admin.service.'${item}'.'${item}'
 * @derived OMV.workspace.panel.Panel
 */
Ext.define("OMV.module.admin.service.'${item}'.'${item}'", {
        extend: "Ext.panel.Panel",
        initComponent: function() {
                var me = this;
                window.open("'${address}'","blank")
                me.callParent(Ext.panel.panel);
        },
});

OMV.WorkspaceManager.registerNode({
        id: "'${item}'",
        path: "/service",
        text: _("'${item}'"),
        icon16: "images/'${item}'.png",
});

OMV.WorkspaceManager.registerPanel({
        path: "/service/'${item}'",
        className: "OMV.module.admin.service.'${item}'.'${item}'"
});
' > /millers_temp/service/$item/$item.js
         
   fi
done 
if [ -d /millers_temp ]; then
   #create startup script and call to script in rc.local
   sed -i '0,/^[ \t]*exit[ \t]\+0/s//\/millers_temp\/script.sh\n&/' /etc/rc.local
   echo '#!/bin/bash
OMV_V=`expr substr "$(cat /etc/issue)" 18 1`
if [ $OMV_V -gt 4 ]; then
    cp -Ra /millers_temp/service/ /var/www/openmediavault/js/omv/module/admin/
    #remove rc.local call
    sed -i "s#/millers_temp/script.sh##g" /etc/rc.local
    #delete script and temp folder
    rm -Rf /millers_temp   
    #remove rc.local call
fi
exit 0' > /millers_temp/script.sh
   chmod +x /millers_temp/script.sh
exit 0
fi
sleep 1
f_log ""

### 3. move all *.deb files in $OMVFOLDER_DEBS
f_log "3. move all *.deb and openmediavault-local.list in $OMVAPT/"

if [ ! -d $OMVFOLDER_DEBS ]; then 
	mkdir $OMVFOLDER_DEBS && f_log "$OMVFOLDER_DEBS created"
else
	f_log "folder $OMVFOLDER_DEBS already exists!"
fi

if ls $OMV_DPKGARCHIVE_DIR/*.deb >/dev/null 2>&1; then
	mv $OMV_DPKGARCHIVE_DIR/*.deb $OMVFOLDER_DEBS && f_log "moved all manually installed *.deb-files to $OMVFOLDER_DEBS"
else
	f_log "No old deb-files in $OMV_DPKGARCHIVE_DIR found. Nothing to do here!"
fi

if ls $OMVAPT/openmediavault-local.list >/dev/null 2>&1; then
	mv $OMVAPT/openmediavault-local.list $OMVFOLDER_DEBS && f_log "moved $OMVAPT/openmediavault-local.list to $OMVFOLDER_DEBS"
	echo "deb file:$OMV_CACHE_DIR/archives /" > $OMVAPT/openmediavault-local.list && f_log "created a new $OMVAPT/openmediavault-local.list"
else
	f_log "No file: $OMVAPT/openmediavault-local.list found. Nothing to do here!"
fi
sleep 1
f_log ""


### 4. move old-omvplugins.org-lists
f_log "4. move old-omvplugins.org-lists in $OMVAPT/"
if [ -f $OMVAPT/omv-plugins-org-* ]; then
	mv $OMVAPT/omv-plugins-org-* $OMVFOLDER_DEBS && f_log "moved old omvplugins.org-lists in $OMVAPT/ to $OMVFOLDER_DEBS"
else
	f_log "No old lists for omvplugins.org found in $OMVAPT/omv-plugins-org-* found. Nothing to do here!"
fi

if [ -f $OMVAPT/openmediavault-millers.list ]; then
	mv $OMVAPT/openmediavault-millers.list $OMVFOLDER_DEBS && f_log "moved openmediavault-millers.list in $OMVAPT/ to $OMVFOLDER_DEBS"
else 
	f_log "No openmediavault-millers.list found in $OMVAPT. Nothing to do here!"
fi
sleep 1
f_log ""

### 5. clean other stuff
# from thread: http://forums.openmediavault.org/viewtopic.php?f=14&t=2262&start=10#p15824
f_log "5. Clean other stuff"
if [ -f /etc/apache2/openmediavault-webgui.d/git.conf ]; then
	mv /etc/apache2/openmediavault-webgui.d/git.conf $OMVFOLDER_DEBS && f_log "moved git.conf in /etc/apache2/openmediavault-webgui.d/ to $OMVFOLDER_DEBS"
fi
if [ -f /etc/apache2/mods-enabled/authnz_external.load ]; then
	mv /etc/apache2/mods-enabled/authnz_external.load $OMVFOLDER_DEBS && f_log "moved authnz_external.load in /etc/apache2/mods-enabled/ to $OMVFOLDER_DEBS"
fi
sleep 1
f_log ""

f_log "The cleaning of OMV 0.4 for upgrading to 0.5 was successfull! Please reboot. Then you can upgrade to 0.5 at your own risk via \"omv-release upgrade\""
echo
echo "The logfile is $OMVLOGFILE"
menu;
}


changelocation()
{
cd /
WHERE=""
selected=0
echo "";
while [[ "$selected" -eq 0 ]] ; do
	screen;
	echo
	echo "Please choose the folder you wish to use for MOST applications.";
	echo "Use the navigation system below to find the location you wish to use"
	echo "and then confirm it by entering 0. If uninstalling you must choose"
	echo "the same folder you installed to.";
	count=-1 && echo "Current Selected Folder is: $(pwd)" && echo ""
	# Listing content of directory in the GUI
	for item in $(echo -e "$(pwd)\n..\n$(find -L -maxdepth 1 -type d -name [^\.]\* | sed 's:^\./::')"); do
		count=$(( $count + 1 )); var_name="sel$count"; var_val="$item"; eval ${var_name}=`echo -e \""${var_val}"\"`; echo "$count - $item"
	done
	echo "" && echo "Type the ID of the Destination folder or 0 to select current folder:"
	# Asking user for its selection
	read answer && sel_item="$(echo "sel$answer")"
	WHERE=${!sel_item}
	if [ "$WHERE" == "Select current folder" ]; then INSTALLDIR="$(pwd)" && selected=1
	elif [ "$answer" == "0" ]; then INSTALLDIR="$(pwd)" && selected=1
	elif [ "$WHERE" == ".." ]; then cd "$(dirname $(pwd))"
	elif [[ "$(pwd)" == "/" && -d "/$WHERE" ]]; then cd "/$WHERE"
	elif [ -d "$(pwd)/$WHERE" ]; then cd "$(pwd)/$WHERE"
	fi
	echo ""
done
screen;
echo
if [ "$INSTALLDIR" == "/" ]
then
	echo "You have chosen to install MOST apps to the root of your system drive";
	INSTALLDIR=""
else
	echo "You have chosen to install MOST apps to $INSTALLDIR";
fi
if QUESTION; then
	. $C_FILE
	MILLERSCONFIG1=$INSTALLDIR
	save_variables > $C_FILE
	menu;
else
	changelocation;
fi
}

install_PYTHON()
{
if [ ! -e /usr/bin/python2.7 ]; then
	t=9
	appinstall="build-essential libsqlite3-dev libssl-dev ncurses-dev libreadline5-dev libncursesw5-dev libgdbm-dev libbz2-dev libc6-dev tk-dev libdb4.6-dev tk8.5 tk8.5-dev"
	for item in ${appinstall[@]}; do
		echo -ne $t%           \\r
			if [ ! -e /var/lib/dpkg/info/"$item".list ]; then
				/usr/bin/apt-get -qq install "$item" > /dev/null 2>&1
				t=$(($t + 7))
			else
				t=$(($t + 7))
			fi
	done
	cd /tmp
	wget http://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz
	tar zxvf Python-2.7.6.tgz
	rm -f Python-2.7.6.tgz
	cd Python-2.7.6
	./configure
	make altinstall
	rm -f /usr/bin/python2.7-config
	rm -f /usr/bin/python2.7
	ln -s /usr/local/bin/python2.7 /usr/bin/python2.7
	ln -s /usr/local/bin/python2.7-config /usr/bin/python2.7-config
	wget http://pypi.python.org/packages/source/C/Cheetah/Cheetah-2.4.4.tar.gz --no-check-certificate
	tar zxvf Cheetah-2.4.4.tar.gz
	cd Cheetah-2.4.4
	/usr/local/bin/python2.7 setup.py install
	wget https://pypi.python.org/packages/source/s/setuptools/setuptools-0.9.tar.gz --no-check-certificate
	tar zxvf setuptools-0.9.tar.gz
	cd setuptools-0.9
	/usr/local/bin/python2.7 setup.py install
	wget https://pypi.python.org/packages/source/p/pip/pip-1.4.tar.gz --no-check-certificate
	tar xzf pip-1.4.tar.gz
	cd pip-1.4
	/usr/local/bin/python2.7 setup.py install
	wget http://sabnzbd.sourceforge.net/yenc-0.3.tar.gz
	tar zxf yenc-0.3.tar.gz
	cd yenc-0.3
	/usr/local/bin/python2.7 setup.py install   # Need to do this as admin
	wget http://ftp.edgewall.com/pub/babel/Babel-0.9.6.tar.gz
	tar xzf Babel-0.9.6.tar.gz
	cd Babel-0.9.6
	/usr/local/bin/python2.7 setup.py install
	cd /
	rm -Rf /tmp/Python-2.7.6
else
	echo "Python2.7 has been found, skipping compiling.";
fi
}

changeip()
{
screen;
echo
echo "You should only need to change the default IP address if the IP you";
echo "see on the main menu screen is not the correct ip address for the";
echo "machine running OpenMediaVault or if it says localhost.";
echo "You want to alter the IP address?";
if ! QUESTION;then
menu;
fi
screen;
echo
echo "Please enter the correct server address below.";
echo "You should only enter a valid host name or IP address as there is no error checking.";
read -p "New IP/Host name: " ip
	. $C_FILE

	MILLERSCONFIG2=$ip
	save_variables > $C_FILE
menu;
}

QUESTION()
{
read -p "Is this correct? (y/n)" -n 1
[[ ! $REPLY =~ ^[Yy]$ ]] || return 0
return 1
}

Uninstall_CouchPotatov1()
{
uinst="1"
echo "uninstalling................CouchPotato"
service CouchPotato stop > /dev/null 2>&1
update-rc.d -f CouchPotato remove > /dev/null 2>&1
sleep 2
rm -fR /etc/init.d/CouchPotato > /dev/null 2>&1
rm -fR $INSTALLDIR/CouchPotato > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/CouchPotato.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/CouchPotato.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/CouchPotato > /dev/null 2>&1
}

Uninstall_CouchPotatoServer()
{
uinst="1"
echo "uninstalling................CouchPotatoServer"
service CouchPotatoServer stop > /dev/null 2>&1
sleep 2
update-rc.d -f CouchPotatoServer remove > /dev/null 2>&1
rm -fR /etc/init.d/CouchPotatoServer > /dev/null 2>&1
rm -fR $INSTALLDIR/CouchPotatoServer > /dev/null 2>&1
#Settings
rm -fR /root/.couchpotato > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/CouchPotatoServer.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/CouchPotatoServer.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/CouchPotatoServer > /dev/null 2>&1
}

Uninstall_SickBeard()
{
uinst="1"
echo "uninstalling................SickBeard"
service sickbeard stop > /dev/null 2>&1
sleep 2
update-rc.d -f sickbeard remove > /dev/null 2>&1
rm -fR /etc/init.d/sickbeard > /dev/null 2>&1
rm -fR $INSTALLDIR/sickbeard > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/SickBeard.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/SickBeard.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/SickBeard > /dev/null 2>&1
}

Uninstall_Htpc()
{
uinst="1"
echo "uninstalling................HTPC Manager"
service HTPC_Manager stop > /dev/null 2>&1
sleep 2
update-rc.d -f HTPC_Manager remove > /dev/null 2>&1
rm -fR /etc/init.d/HTPC_Manager > /dev/null 2>&1
rm -fR $INSTALLDIR/HTPC_Manager > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/HTPC_Manager.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/HTPC_Manager.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/HTPC_Manager > /dev/null 2>&1
}

Uninstall_HeadPhones()
{
uinst="1"
echo "uninstalling................HeadPhones"
service headphones stop > /dev/null 2>&1
sleep 2
update-rc.d -f headphones remove > /dev/null 2>&1
rm -fR /etc/init.d/headphones  > /dev/null 2>&1
rm -fR $INSTALLDIR/headphones > /dev/null 2>&1
sleep 2
rm -fR /var/run/headphones.pid > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/HeadPhones.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/HeadPhones.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/HeadPhones > /dev/null 2>&1
}

Uninstall_SABnzbd()
{
uinst="1"
echo "uninstalling................SABnzbd"
service SABnzbd stop > /dev/null 2>&1
sleep 2
update-rc.d -f SABnzbd remove > /dev/null 2>&1
rm -fR /etc/init.d/SABnzbd > /dev/null 2>&1
rm -fR $INSTALLDIR/SABnzbd > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/SABnzbd.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/SABnzbd.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/SABnzbd > /dev/null 2>&1
}

Uninstall_SubSonic()
{
uinst="1"
echo "uninstalling................SubSonic"
service subsonic stop > /dev/null 2>&1
sleep 2
update-rc.d -f subsonic remove > /dev/null 2>&1
rm -fR /etc/init.d/subsonic > /dev/null 2>&1
/usr/bin/apt-get -qq remove subsonic
rm -fR /etc/default/subsonic > /dev/null 2>&1
rm -fR /var/subsonic > /dev/null 2>&1
rm -fR /var/lib/dpkg/info/subsonic.list > /dev/null 2>&1
rm -fR /var/lib/dpkg/info/subsonic.postrm > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/SubSonic.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/SubSonic.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/SubSonic > /dev/null 2>&1
}

Uninstall_LazyLibrarian()
{
uinst="1"
echo "uninstalling................LazyLibrarian"
service LazyLibrarian stop > /dev/null 2>&1
sleep 2
update-rc.d -f LazyLibrarian remove > /dev/null 2>&1
rm -fR /etc/init.d/LazyLibrarian > /dev/null 2>&1
rm -fR $INSTALLDIR/LazyLibrarian > /dev/null 2>&1
rm -fR /root/.lazylibrarian > /dev/null 2>&1
rm -fR /var/run/lazylibrarian > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/LazyLibrarian.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/LazyLibrarian.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/LazyLibrarian > /dev/null 2>&1
}

Uninstall_PyLoad()
{
uinst="1"
echo "uninstalling................PyLoad"
service /root/.pyload stop > /dev/null 2>&1
rm -fR /usr/share/pyload > /dev/null 2>&1
/usr/bin/apt-get -qq remove pyload-cli
update-rc.d -f pyload remove > /dev/null 2>&1
sleep 2
rm -fR /etc/init.d/pyload > /dev/null 2>&1
rm -fR /root/.pyload > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/PyLoad.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/PyLoad.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/PyLoad > /dev/null 2>&1
}

Uninstall_newznab_free()
{
uinst="1"
echo "uninstalling................nZEDb"
sed -i "s#screen -dmS nZEDb /var/www/nZEDb/misc/update_scripts/nix_scripts/screen/threaded/start.sh##g" /etc/rc.local
sed -i "s#screen -dmS nZEDb /var/www/nZEDb/misc/update_scripts/nix_scripts/screen/sequential/simple.sh##g" /etc/rc.local
rm -Rf /var/www/nZEDb
rm -Rf /etc/apache2/sites-available/nZEDb
rm -Rf /etc/apache2/sites-available/newznab2
service apache2 restart > /dev/null 2>&1
}

Uninstall_newznab_paid()
{
uinst="1"
echo "uninstalling................newznab +"
sed -i "s#screen -dmS newznab /var/www/newznab/misc/update_scripts/nix_scripts/newznab_screen.sh##g" /etc/rc.local
rm -Rf /var/www/newznab
}

Uninstall_Maraschino()
{
uinst="1"
echo "uninstalling................Maraschino"
service maraschino stop > /dev/null 2>&1
sleep 2
update-rc.d -f maraschino remove > /dev/null 2>&1
rm -fR /etc/init.d/maraschino  > /dev/null 2>&1
rm -fR $INSTALLDIR/maraschino > /dev/null 2>&1
sleep 2
rm -fR /var/run/maraschino.pid > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/Maraschino.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/Maraschino.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/Maraschino > /dev/null 2>&1
}

Uninstall_Deluge()
{
uinst="1"
echo "uninstalling................Deluge"
service deluge-daemon stop > /dev/null 2>&1
sleep 2
update-rc.d -f deluge-daemon remove > /dev/null 2>&1
rm -fR /etc/init.d/deluge-daemon  > /dev/null 2>&1
sleep 2
rm -fR /usr/lib/python2.6/dist-packages/deluge-1.3.5-py2.6-linux-x86_64.egg > /dev/null 2>&1
rm -fR /usr/local/lib/python2.6/dist-packages/deluge-1.3.5-py2.6-linux-x86_64.egg > /dev/null 2>&1
rm -fR /root/.config/deluge > /dev/null 2>&1
rm -fR /var/log/deluge > /dev/null 2>&1
rm -fR /usr/local/bin/deluge > /dev/null 2>&1
rm -fR /usr/local/bin/deluged > /dev/null 2>&1
rm -fR /usr/local/bin/deluge-gtk > /dev/null 2>&1
rm -fR /usr/local/bin/deluge-web > /dev/null 2>&1
rm -fR /usr/local/bin/deluge-console > /dev/null 2>&1
rm -fR /usr/bin/deluge > /dev/null 2>&1
rm -fR /usr/bin/deluged > /dev/null 2>&1
rm -fR /usr/bin/deluge-gtk > /dev/null 2>&1
rm -fR /usr/bin/deluge-web > /dev/null 2>&1
rm -fR /usr/bin/deluge-console > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/Deluge.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/Deluge.js > /dev/null 2>&1
rm -fR /var/lib/deluge > /dev/null 2>&1
userdel deluge > /dev/null 2>&1
rm -fR /home/deluge > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/Deluge > /dev/null 2>&1
}

Uninstall_Auto-Sub()
{
uinst="1"
echo "uninstalling................Auto-Sub"
service Auto-Sub stop > /dev/null 2>&1
update-rc.d -f Auto-Sub remove > /dev/null 2>&1
sleep 2
rm -fR /etc/init.d/auto-sub > /dev/null 2>&1
rm -fR $INSTALLDIR/auto-sub > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/Auto-Sub.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/Auto-Sub.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/Auto-Sub > /dev/null 2>&1
/usr/bin/apt-get -qq purge mercurial
}

Uninstall_Extplorer()
{
uinst="1"
echo "uninstalling................Extplorer"
rm -fR /var/www/openmediavault/extplorer > /dev/null 2>&1
/usr/bin/apt-get -qq remove extplorer
rm -R /etc/extplorer > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/Extplorer.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/Extplorer.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/Extplorer > /dev/null 2>&1
#/etc/extplorer/.htusers.php
#<?php
#/** @version $Id: .htusers.php 135 2009-01-27 21:57:15Z ryu_ms $ */
#/** ensure this file is being included by a parent file */
#if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );

#$GLOBALS["users"]=array(
#        array("admin","21232f297a57a5a743894a0e4a801fc3",empty($_SERVER['DOCUMENT_ROOT'])?realpath(dirname(__FILE__).'/..'):$_SERVER['DOCUMENT_ROOT'],"http://localhost",1,"",7,1),
#); ?>
}

Uninstall_BicBucStriim()
{
uinst="1"
echo "uninstalling................BicBucStriim"
rm -fR /var/www/openmediavault/bbs > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/BicBucStriim.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/BicBucStriim.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/BicBucStriim > /dev/null 2>&1
}

Uninstall_MyLar()
{
uinst="1"
echo "uninstalling................MyLar"
service mylar stop > /dev/null 2>&1
sleep 2
rm -fR /etc/init.d/mylar  > /dev/null 2>&1
update-rc.d -f mylar remove > /dev/null 2>&1
rm -fR $INSTALLDIR/mylar > /dev/null 2>&1
sleep 2
rm -fR /var/run/mylar.pid > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/MyLar.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/MyLar.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/MyLar > /dev/null 2>&1
}

Uninstall_Gamez()
{
uinst="1"
service GameZ stop > /dev/null 2>&1
sleep 2
rm -fR /etc/init.d/GameZ  > /dev/null 2>&1
update-rc.d -f GameZ remove > /dev/null 2>&1
rm -fR $INSTALLDIR/GameZ > /dev/null 2>&1
sleep 2
rm -fR /var/run/GameZ.pid > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/GameZ.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/GameZ.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/GameZ > /dev/null 2>&1
}

Uninstall_XDM()
{
uinst="1"
service xdm stop > /dev/null 2>&1
sleep 2
rm -fR /etc/init.d/xdm  > /dev/null 2>&1
update-rc.d -f xdm remove > /dev/null 2>&1
rm -fR $INSTALLDIR/XDM > /dev/null 2>&1
sleep 2
rm -fR /var/run/xdm.pid > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/XDM.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/XDM.js > /dev/null 2>&1
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/XDM > /dev/null 2>&1
}

Uninstall_MusicCabinet()
{
uinst="1"
echo "uninstalling................MusicCabinet"
service subsonic stop > /dev/null 2>&1
sleep 2
update-rc.d -f subsonic remove > /dev/null 2>&1
rm -fR /etc/init.d/subsonic > /dev/null 2>&1
/usr/bin/apt-get -qq remove subsonic > /dev/null 2>&1
rm -fR /etc/default/subsonic > /dev/null 2>&1
rm -fR /var/subsonic > /dev/null 2>&1
rm -fR /var/lib/dpkg/info/subsonic.list > /dev/null 2>&1
rm -fR /var/lib/dpkg/info/subsonic.postrm > /dev/null 2>&1
rm -fR /var/www/openmediavault/images/MusicCabinet.png > /dev/null 2>&1
rm -fR /var/www/openmediavault/js/omv/module/MusicCabinet.js > /dev/null 2>&1
t=10
appinstall=`dpkg-query -W -f '${package}\n' | grep postgres`
for item in ${appinstall[@]}; do
	echo -ne $t%           \\r
	/usr/bin/apt-get -y remove "$item" > /dev/null 2>&1
	sleep 2
	/usr/bin/apt-get -y purge "$item" > /dev/null 2>&1
	t=$(($t + 20))
done
rm -R /etc/postgresql-common
rm -R /var/lib/postgresql
rm -Rf /var/www/openmediavault/js/omv/module/admin/service/MusicCabinet > /dev/null 2>&1
}

getmysql()
{
screen;
echo "";
echo "    --------------------------------MySql--------------------------------";
echo "    You have an exsisting MySql install, in order to complete the install";
echo "                     we need to know your MySql password                 ";
echo "";
read -s -p "Your MySql password is? >" mypass
until mysql -u root -p$mypass  -e ";" ; do
       read -s -p "Can't connect, please retry: " mypass
done
}

menu()
{
screen;
if [ "$ip" == "localhost" ]; then
	echo "Your current IP address is set to localhost";
	echo "you need to change this to the actual IP address";
	echo "of the OMV machine on the next screen";
	sleep 2
	changeip;
fi

echo "Just checking for any new updates for installed files"
echo "If this is a new install it will take some time"
echo "Please wait..."
apt-get --quiet --quiet update
/usr/bin/apt-get upgrade
SELECT=""
cpv="0"
cpm="0"
cpd="0"
sbm="0"
sbd="0"
sbt="0"
hpm="0"
hpd="0"
sab="0"
asub="0"
llm="0"
pyl="0"
nzbf="0"
nzbp="0"
mar="0"
del="0"
sub="0"
exp="0"
ml="0"
mc="0"
gz="0"
bbs="0"
htpc="0"
uml="0"
xdm="0"
ucpv="0"
ucpm="0"
ucpd="0"
usbm="0"
usbd="0"
usbt="0"
uhpm="0"
uhpd="0"
usab="0"
usub="0"
ullm="0"
upyl="0"
uinst="0"
unzbf="0"
unzbp="0"
umar="0"
udel="0"
uasub="0"
uexp="0"
ugz="0"
ubbs="0"
uxdm="0"
uhtpc="0"
#sleep 3
cd /tmp
#Menu & python option
screen;
p=""
echo "                   Please make a selection (e.g. 1)"
echo "                 Or select multiples (e.g. 1 4 5 7 10)"
echo "                To uninstall use a minus sign (e.g. -1)"
echo "          Change default [F]older or enter a new [I]p address"
echo ""
echo "           1. CouchPotato                   10. Subsonic 4.9 beta3"
echo "           2. CouchPotatoServer (Master)    11. LazyLibrarian"
echo "           3. CouchPotatoServer (Develop)   12. PyLoad"
echo "           4. SickBeard (Master)            13. nZEDb"
echo "           5. SickBeard (Develop)           14. Newznab Paid"
echo "           6. SickBeard Torrent             15. Maraschino"
echo "           7. HeadPhones (Master)           16. Deluge"
echo "           8. HeadPhones (Develop)          17. Auto-Sub"
echo "           9. Sabnzbdplus                   18. Extplorer"
echo "          19. MyLar                         20. Music Cabinet"
echo "          21. GameZ                         22. BicBucStriim"
echo "          23. XDM                           24. HTPC Manager"
echo ""
echo "                                 Q. Quit"
if [ "$INSTALLDIR" == "" ]; then
	echo "           [I]p:${ip}             [F]older:root of drive"
else
	echo "           [I]p:${ip}             [F]older:${INSTALLDIR}"
fi
read -p "Selection:> " SELECT
if [ "$SELECT" == "" ]; then
	menu;
fi
#items=( $SELECT )
for item in ${SELECT[@]}; do
case "$item" in
# Uninstall CouchPotato
-1)
Uninstall_CouchPotatov1;
;;
# Uninstall CouchPotatoServer (Master)
-2)
Uninstall_CouchPotatoServer;
;;
# Uninstall CouchPotatoServer (Develop)
-3)
Uninstall_CouchPotatoServer;
;;
# Uninstall SickBeard (Master)
-4)
Uninstall_SickBeard;
;;
# Uninstall SickBeard (Develop)
-5)
Uninstall_SickBeard;
;;
# Uninstall SickBeard Torrent
-6)
Uninstall_SickBeard;
;;
# Uninstall HeadPhones (Master)
-7)
Uninstall_HeadPhones;
;;
# Uninstall HeadPhones (Develop)
-8)
Uninstall_HeadPhones;
;;
# Uninstall Sabnzbdplus
-9)
Uninstall_SABnzbd;
;;
# Uninstall Subsonic
-10)
Uninstall_SubSonic;
;;
# Uninstall LazyLibrarian
-11)
Uninstall_LazyLibrarian;
;;
# Uninstall PyLoad
-12)
Uninstall_PyLoad;
;;
# Uninstall newznab free
-13)
Uninstall_newznab_free;
;;
# Uninstall newznab +
-14)
Uninstall_newznab_paid;
;;
# Uninstall maraschino
-15)
Uninstall_Maraschino;
;;
# Uninstall deluce
-16)
Uninstall_Deluge;
;;
# Uninstall Auto-Sub
-17)
Uninstall_Auto-Sub;
;;
# Uninstall Extplorer
-18)
Uninstall_Extplorer;
;;
# Uninstall MyLar
-19)
Uninstall_MyLar;
;;
# Uninstall MusicCabinet
-20)
Uninstall_MusicCabinet;
;;
# Uninstall Gamez
-21)
Uninstall_Gamez;
;;
# Uninstall BicBucStriim
-22)
Uninstall_BicBucStriim;
;;
# Uninstall XDM
-23)
Uninstall_XDM;
;;
# Uninstall HTPC Manager
-24)
Uninstall_Htpc;
;;
# CouchPotato
1)
cpv="1"
;;
# CouchPotatoServer (Master)
2)
cpm="1"
;;
# CouchPotatoServer (Develop)
3)
cpd="1"
;;
# SickBeard (Master)
4)
sbm="1"
;;
# SickBeard (Develop)
5)
sbd="1"
;;
# SickBeard Torrent
6)
sbt="1"
;;
# HeadPhones (Master)
7)
hpm="1"
;;
# HeadPhones (Develop)
8)
hpd="1"
;;
# Sabnzbdplus
9)
sab="1"
;;
# Subsonic
10)
sub="1"
;;
# LazyLibrarian
11)
llm="1"
;;
# PyLoad
12)
pyl="1"
;;
# newznab free
13)
nzbf="1"
;;
# newznab +
14)
nzbp="1"
;;
# Maraschino
15)
mar="1"
;;
# Deluge
16)
del="1"
;;
# Auto-Sub
17)
asub="1"
;;
# Extplorer
18)
exp="1"
;;
# MaLar
19)
ml="1"
;;
# MusicCabinet
20)
mc="1"
;;
# GameZ
21)
gz="1"
;;
# BicBucStriim
22)
bbs="1"
;;
# XDM
23)
xdm="1"
;;
# HTPC Manager
24)
htpc="1"
;;
# Change IP address
I|i)
changeip;
;;
# Change default folder
F|f)
changelocation;
;;
# Clean OMV4 - OMV5
clean)
Clean;
;;
# Install python2.7
python)
install_PYTHON;
;;
# Install Bacula
bacula)
install_Bacula;
;;
Q|q)
exit
;;
*)
menu;
;;
esac
done

if [ "$uinst" = "1" ]; then
	menu;
else
	showinstall;
fi
}

showinstall()
{
cont=""
if [ "$hpm" = "1" -a "$hpd" = "1" ]; then
	sameapp;
fi

if [ "$cpv" = "1" -a "$cpd" = "1" -o "$cpv" = "1" -a "$cpm" = "1" -o "$cpd" = "1" -a "$cpm" = "1" ]; then
	sameapp;
fi

if [ "$sbt" = "1" -a "$sbd" = "1" -o "$sbt" = "1" -a "$sbm" = "1" -o "$sbd" = "1" -a "$sbm" = "1" ]; then
	sameapp;
fi

if [ "$nzbf" = "1" -a "$nzbp" = "1" ]; then
	sameapp;
fi

screen;
echo "    We are now ready to start installing your chossen applications."
echo "    Please look carfully below at what will be installed and either"
echo "                 confirm or deny the install options."
echo "";
echo "             You have Chosen to install the following :-";
echo "";

if [ "$cpv" = "1" ]; then
	echo "               CouchPotato Version 1";
fi

if [ "$cpm" = "1" ]; then
	echo "               CouchPotato Version 2 - Master Branch";
fi

if [ "$cpd" = "1" ]; then
	echo "               CouchPotato Version 2 - Develop Branch";
fi

if [ "$ml" = "1" ]; then
	echo "               MyLar";
fi

if [ "$hpm" = "1" ]; then
	echo "               HeadPhones - Master Branch";
fi

if [ "$hpd" = "1" ]; then
	echo "               HeadPhones - Develop Branch";
fi

if [ "$sab" = "1" ]; then
	echo "               SABnzbd Stable Version";
fi

if [ "$sbm" = "1" ]; then
	echo "               SickBeard - Master Branch";
fi

if [ "$sbd" = "1" ]; then
	echo "               SickBeard - Develop Branch";
fi

if [ "$sbt" = "1" ]; then
	echo "               SickBeard - Torrent Branch";
fi

if [ "$sub" = "1" ]; then
	echo "               SubSonic";
fi

if [ "$mc" = "1" ]; then
	echo "               MusicCabinet";
fi

if [ "$llm" = "1" ]; then
	echo "               LazyLibrarian";
fi

if [ "$pyl" = "1" ]; then
	echo "               PyLoad";
fi

if [ "$nzbf" = "1" ]; then
	echo "               nZEDb";
fi

if [ "$nzbp" = "1" ]; then
	echo "               Newznab+";
fi

if [ "$mar" = "1" ]; then
	echo "               Maraschino";
fi

if [ "$del" = "1" ]; then
	echo "               Deluge";
fi

if [ "$asub" = "1" ]; then
	echo "               Auto-Sub";
fi

if [ "$exp" = "1" ]; then
	echo "               Extplorer";
fi

if [ "$gz" == "1" ]; then 
	echo "               Gamez";
fi

if [ "$bbs" == "1" ]; then 
	echo "               BicBucStriim";
fi

if [ "$xdm" == "1" ]; then 
	echo "               XDM";
fi

if [ "$htpc" == "1" ]; then 
	echo "               HTPC Manager";
fi


echo "";
if QUESTION; then
	installs;
else
	menu;
fi
finish;
}

NEWZNABPT()
{
screen;
echo
echo "    ********************You selected to install nZEDb********************";
echo "                                                                         ";
echo
echo "Please input the port you wish ${INSTALLING} to use.                     ";
echo "                                                                         ";
NEWZNABPORT=""
read NEWZNABPORT;
if ! [[ "$NEWZNABPORT" =~ ^[0-9]+$ ]] ; then
	echo "error: Not a number";
   	sleep 3
	NEWZNABPT;
fi

#check if port is in use
if lsof -i tcp@0.0.0.0:$NEWZNABPORT > /dev/null 2>&1; then
	# ask if user want's to set another port
	echo
	echo "Port is already in use!!"
	echo "Trying other ports to run on..."
	# starting a +100 loop to find next availabe port
	while lsof -i tcp@0.0.0.0:$NEWZNABPORT > /dev/null 2>&1; do
		NEWZNABPORT=$(($NEWZNABPORT +1))
	done
fi
# new port found, now set it
echo "$NEWZNABPORT is free, ${INSTALLING} will use this port?"
if ! QUESTION;then
	NEWZNABPT;
fi
}

sameapp()
{
screen;
echo
echo "You can not install the same application twice"
echo "Please choose only 1 version of each application"
sleep 5
menu;
}

allok()
{
screen;
cont=""
echo "";
while [ "$cont" == "" ]; do
	if [ "$INSTALLDIR" == "" ]; then
		echo "Installing to root of system drive."
	else
		echo "Installing to $INSTALLDIR"
	fi
	echo "Continue with install? [Y]/[N] or [Q] to quit"
	read cont;
		echo "";
		case "$cont" in
		y | Y)
		mcont="1"
		;;
		n | N)
		mcont="2"
		;;
		q | Q )
		exit 1;
		;;
		*)
		showinstall;
		echo "";
		echo "Sorry, answer not recognized."
		;;
	esac
done
if [ "$mcont" == "1" ]; then
echo "";
else
menu;
fi
}

installs()
{
. $C_FILE
if [ "$MILLERSCONFIG3" == "n" ]; then
	screen;
	echo
	echo "    ***********************Installing prerequisites**********************";
	echo
	echo "    ****************Installing openmediavault-omvpluginsorg**************";
	echo
	echo "    ***********************and updating your sources*********************";
	echo
	echo "    ***********************Please wait a few moments*********************";
	echo
	source1="deb http://http.us.debian.org/debian/ squeeze main contrib non-free";
	source2="deb-src http://http.us.debian.org/debian/ squeeze main contrib non-free";
	source3="deb http://debian.linuxmint.com/latest/multimedia testing main non-free";
	#source4="deb http://packages.dotdeb.org stable all";
	#source5="deb-src http://packages.dotdeb.org stable all";
	echo -ne 0%         \\r
	if [ ! -e /etc/apt/sources.list.d/openmediavault-millers.list ]; then
		echo '#######Millers - Sources list#######' > /etc/apt/sources.list.d/openmediavault-millers.list
	fi
	echo -ne 5%         \\r
	line=$(grep "$source1" /etc/apt/sources.list.d/openmediavault-millers.list)
	if [ $? == 1 ]; then
		echo $source1 >> /etc/apt/sources.list.d/openmediavault-millers.list
	fi
	echo -ne 10%         \\r
	line=$(grep "$source2" /etc/apt/sources.list.d/openmediavault-millers.list)
	if [ $? == 1 ]; then
		echo $source2 >> /etc/apt/sources.list.d/openmediavault-millers.list
	fi
	echo -ne 15%         \\r
	line=$(grep "$source3" /etc/apt/sources.list.d/openmediavault-millers.list)
	if [ $? == 1 ]; then
		echo $source3 >> /etc/apt/sources.list.d/openmediavault-millers.list
	fi
	echo -ne 20%         \\r
	#line=$(grep "$source4" /etc/apt/sources.list.d/openmediavault-millers.list)
	#if [ $? == 1 ]; then
	#	echo $source4 >> /etc/apt/sources.list.d/openmediavault-millers.list
	#fi
	#echo -ne 20%         \\r
	#line=$(grep "$source5" /etc/apt/sources.list.d/openmediavault-millers.list)
	#if [ $? == 1 ]; then
	#	echo $source5 >> /etc/apt/sources.list.d/openmediavault-millers.list
	#fi
	#echo -ne 20%         \\r
	#line=$(grep "$source4" /etc/apt/sources.list.d/openmediavault-millers.list)
	#if [ $? == 1 ]
	#    then
	#    echo $source4 >> /etc/apt/sources.list.d/openmediavault-millers.list
	#fi
	cd /tmp
	/usr/bin/apt-get --quiet --quiet update > /dev/null 2>&1
	/usr/bin/apt-get --quiet --quiet upgrade > /dev/null 2>&1
	#Add Key
	/usr/bin/apt-get -qq install debian-keyring > /dev/null 2>&1
	gpg --keyring /usr/share/keyrings/debian-keyring.gpg -a --export 07DC563D1F41B907 |apt-key add - > /dev/null 2>&1
	apt-get update > /dev/null 2>&1
	#wget http://www.dotdeb.org/dotdeb.gpg > /dev/null 2>&1
	#cat dotdeb.gpg | sudo apt-key add - > /dev/null 2>&1
	#Get OMV version to install correct plugin.
	if [ ! -f openmediavault-omvpluginsorg.list ]; then
		if [ "$OMV_V" == "2" ]; then
			echo -ne 22%           \\r
			wget http://packages.omv-plugins.org/pool/main/o/openmediavault-omvpluginsorg/openmediavault-omvpluginsorg_0.2.3_all.deb > /dev/null 2>&1
			echo -ne 24%           \\r
			dpkg -i openmediavault-omvpluginsorg_0.2.3_all.deb > /dev/null 2>&1
			rm openmediavault-omvpluginsorg_0.2.3_all.deb > /dev/null 2>&1
			echo -ne 26%           \\r
		elif [ "$OMV_V" == "3" ]; then
			echo -ne 22%           \\r
			wget http://packages.omv-plugins.org/pool/main/o/openmediavault-omvpluginsorg/openmediavault-omvpluginsorg_0.3.5~1.gbp97ef9e_all.deb > /dev/null 2>&1
			echo -ne 24%           \\r
			dpkg -i openmediavault-omvpluginsorg_0.3.5~1.gbp97ef9e_all.deb > /dev/null 2>&1
			rm openmediavault-omvpluginsorg_0.3.5~1.gbp97ef9e_all.deb > /dev/null 2>&1
			echo -ne 26%           \\r
		elif [ "$OMV_V" == "4" ]; then
			echo -ne 22%           \\r
			wget http://packages.omv-plugins.org/pool/main/o/openmediavault-omvpluginsorg/openmediavault-omvpluginsorg_0.4.2-10~1.gbpefc0a1_all.deb > /dev/null 2>&1
			echo -ne 24%           \\r
			dpkg -i openmediavault-omvpluginsorg_0.4.2-10~1.gbpefc0a1_all.deb > /dev/null 2>&1
			rm openmediavault-omvpluginsorg_0.4.2-10~1.gbpefc0a1_all.deb > /dev/null 2>&1
			echo -ne 26%           \\r
		elif [ "$OMV_V" == "5" ]; then
			echo -ne 26%           \\r
			wget http://omv-extras.org/debian/pool/main/o/openmediavault-omvextrasorg/openmediavault-omvextrasorg_0.5.15_all.deb > /dev/null 2>&1
			dpkg -i openmediavault-omvextrasorg_0.5.15_all.deb > /dev/null 2>&1
			rm openmediavault-omvextrasorg_0.5.15_all.deb > /dev/null 2>&1
			echo -ne 26%           \\r
		fi
	fi
	echo -ne 26%           \\r
	t=26
	appinstall="lsof inotify-tools subversion at curl python par2 unzip unrar git git-core aptitude python-support python-software-properties python-openssl python-yenc python-cheetah python-beautifulsoup python-dbus python-html5lib  python-lxml python-configobj python-feedparser screen"
	#items=( $appinstall )
	for item in ${appinstall[@]}; do
		echo -ne $t%           \\r
		if [ ! -e /var/lib/dpkg/info/"$item".list ]; then
			/usr/bin/apt-get -qq install "$item" > /dev/null 2>&1
			t=$(($t + 2))
		else
			t=$(($t + 2))
		fi
	done
	if [ ! -e /var/lib/dpkg/info/unrar.list ]; then
		RUNNING=`expr "$(uname -m)"`
		if [ "$RUNNING" == "x86_64" ]; then
			cd /tmp > /dev/null 2>&1
			wget http://http.us.debian.org/debian/pool/non-free/u/unrar-nonfree/unrar_4.2.4-0.3_amd64.deb > /dev/null 2>&1
			dpkg -i unrar_4.2.4-0.3_amd64.deb > /dev/null 2>&1
			rm unrar_4.2.4-0.3_amd64.deb > /dev/null 2>&1
		elif [ "$RUNNING" == "i686" ]; then
			cd /tmp > /dev/null 2>&1
			wget http://http.us.debian.org/debian/pool/non-free/u/unrar-nonfree/unrar_4.2.4-0.3_i386.deb > /dev/null 2>&1
			dpkg -i unrar_4.2.4-0.3_i386.deb > /dev/null 2>&1
			rm unrar_4.2.4-0.3_i386.deb > /dev/null 2>&1
		fi
	fi
	/usr/bin/apt-get -qyf install  > /dev/null 2>&1
	t=$(($t + 5))
	echo -ne $t%           \\r
	/usr/bin/apt-get -qyf upgrade  > /dev/null 2>&1
	t=$(($t + 5))
	echo -ne $t%           \\r
	. $C_FILE

	MILLERSCONFIG3=y
	save_variables > $C_FILE
fi
if [ "$ml" == "1" ]; then
	install_ML;
fi

if [ "$hpm" == "1" -o "$hpd" == "1" ]; then
	install_HP;
fi

if [ "$sbm" == "1" -o "$sbd" == "1" -o "$sbt" == "1" ]; then
	install_SB;
fi

if [ "$sub" == "1" ]; then
	install_SUB;
fi

if [ "$cpv" == "1" ]; then
	install_CP;
fi

if [ "$cpm" == "1" -o "$cpd" == "1" ]; then
	install_CPS;
fi

if [ "$sab" == "1" ]; then
	install_SAB;
fi

if [ "$llm" == "1" ]; then
	install_LL;
fi

if [ "$pyl" == "1" ]; then
	install_PY;
fi

if [ "$nzbf" == "1" ]; then
	INSTALLING="nZEDb" && install_NZBF;
fi

if [ "$nzbp" == "1" ]; then
	INSTALLING="Newznab" && install_NZBP;
fi

if [ "$mar" == "1" ]; then
	install_MAR;
fi

if [ "$del" == "1" ]; then
	install_DEL;
fi

if [ "$asub" == "1" ]; then
	install_ASUB;
fi

if [ "$exp" == "1" ]; then
	install_EXP;
fi

if [ "$mc" == "1" ]; then
	install_MC;
fi

if [ "$gz" == "1" ]; then 
	install_GZ;
fi

if [ "$bbs" == "1" ]; then 
	install_BBS;
fi

if [ "$xdm" == "1" ]; then 
	install_XDM;
fi

if [ "$htpc" == "1" ]; then 
	install_HTPC_Manager;
fi
}

install_GZ()
{
service Gamez stop > /dev/null 2>&1
screen;
cd /tmp
echo
echo "*****************You selected to install Gamez***********************";
echo
echo "Downloading and installing GameZ...";
git clone git://github.com/avjui/Gamez.git new_GZ > /dev/null 2>&1
if [ -d $INSTALLDIR/GameZ ]; then
cp -fRa /tmp/new_GZ/. $INSTALLDIR/GameZ
rm -fR /tmp/new_GZ
else
mv /tmp/new_GZ $INSTALLDIR/GameZ
echo '[global]
server.socket_host = "0.0.0.0"' > $INSTALLDIR/GameZ/Gamez.ini
fi
#rm -fR $INSTALLDIR/GameZ/.git
echo "Setting up startup options"
echo '#! /bin/sh

### BEGIN INIT INFO
# Provides:          GameZ
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts instance of GameZ
# Description:       starts instance of GameZ using start-stop-daemon
### END INIT INFO

############### EDIT ME ##################
# startup args
DAEMON_OPTS="Gamez.py -d --nolaunch"

# script name
NAME=GameZ

# app name
DESC=GameZ

# user
RUN_AS='${mainuser}'
# path to app
APP_PATH='${INSTALLDIR}'/GameZ
# path to python bin
DAEMON='${py}'
PID_FILE=/var/run/GameZ.pid

############### END EDIT ME ##################

test -x $DAEMON || exit 0

set -e

case "$1" in
  start)
        echo "Starting $DESC"
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE  --make-pidfile --exec $DAEMON -- $DAEMON_OPTS
        ;;
  stop)
        echo "Stopping $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE | rm -rf $PID_FILE
        ;;

  restart|force-reload)
        echo "Restarting $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE
        sleep 15
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE  --make-pidfile --exec $DAEMON -- $DAEMON_OPTS
        ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0' > /etc/init.d/GameZ
sudo chmod 755 /etc/init.d/GameZ > /dev/null 2>&1
update-rc.d GameZ defaults > /dev/null 2>&1
sudo chmod -R a+x $INSTALLDIR/GameZ > /dev/null 2>&1
sudo chown -hR $mainuser:$maingroup $INSTALLDIR/GameZ > /dev/null 2>&1
service GameZ start > /dev/null 2>&1
sleep 5
service GameZ stop > /dev/null 2>&1
sudo chmod -R a+x $INSTALLDIR/GameZ > /dev/null 2>&1
service GameZ start > /dev/null 2>&1
service="GameZ"
address="http://$ip:8085"
port=":8085"
panel;
echo "Finished"
sleep 1
}

install_ASUB()
{
service Auto-Sub stop > /dev/null 2>&1
screen;
cd /tmp
echo
echo "    ****************You selected to install Auto-Sub*********************";
echo "                                                                         ";
echo "Downloading and installing Auto-Sub...";
if [ ! -e /var/lib/dpkg/info/mercurial.list ]; then
	/usr/bin/apt-get -qy install mercurial > /dev/null 2>&1
fi
if [ ! -e /var/lib/dpkg/info/python-cheetah.list ]; then
	/usr/bin/apt-get -qy install python-cheetah > /dev/null 2>&1
fi
if [ -e $INSTALLDIR/auto-sub ]; then
	hg pull $INSTALLDIR/auto-sub
else
	hg clone https://code.google.com/p/auto-sub/ $INSTALLDIR/auto-sub
fi
if [ ! -e $INSTALLDIR/auto-sub/config.properties ]; then
	echo '[config]
path = '${INSTALLDIR}'/auto-sub
downloadeng = True
minmatchscore = 8
minmatchscorerss = 14
scandisk = 3600
checksub = 28800
checkrss = 1500
rootpath = /
fallbacktoeng = False
subeng =
subnl = nl
notifyen = False
notifynl = False
logfile = AutoSubService.log
postprocesscmd =
configversion = 2
launchbrowser = False

[logfile]
loglevel = info
loglevelconsole = error
logsize = 1000000
lognum = 1

[webserver]
webserverip = 0.0.0.0
webserverport = 8083
username =
password =
webroot =

[notify]
notifymail = False
mailsrv = smtp.gmail.com:587
mailfromaddr = example@gmail.com
mailtoaddr = example@gmail.com
mailusername = example@gmail.com
mailpassword = mysecretpassword
mailsubject = Subs info
mailencryption = TLS
mailauth =
notifygrowl = False
growlhost = 127.0.0.1
growlport = 23053
growlpass = mysecretpassword
notifynma = False
nmaapi = API key
notifytwitter = False
twitterkey = token key
twittersecret = token secret
notifyprowl = False
prowlapi =
prowlpriority = -2

[skipshow]
' > $INSTALLDIR/auto-sub/config.properties
fi
echo "Setting up startup options"
echo '#! /bin/sh
### BEGIN INIT INFO
# Provides: AutoSub
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: AutoSub
# Description: Script to control AutoSub
### END INIT INFO

## START EDIT ##

NAME=AutoSub
INIT_DIR=/etc/init.d
DAEMON=/usr/bin/python
#DAEMON_OPTS=" '${INSTALLDIR}'/auto-sub/AutoSub.py -d -l"
DAEMON_OPTS=" '${INSTALLDIR}'/auto-sub/AutoSub.py -c '${INSTALLDIR}'/auto-sub/config.properties -d -l"
## STOP EDIT ##

autosub_start() {
	echo "Starting $NAME"
	$DAEMON ${DAEMON_OPTS}
}
autosub_stop() {
	echo "Stopping $NAME"
	for pid in $(/bin/pidof python); do
		/bin/grep -q "AutoSub.py" /proc/$pid/cmdline && /bin/kill $pid
	done
	/bin/sleep 2
}

case "$1" in
	start)
		autosub_start
	;;
	stop)
		autosub_stop
	;;
	restart|force-reload)
		echo "Restarting $NAME"
		autosub_stop
		autosub_start
	;;
	*)
		echo "Usage: $0 {start|stop|restart|force-reload}" >&2
		exit 1
	;;
esac
exit 0' > /etc/init.d/Auto-Sub
chmod 755 /etc/init.d/Auto-Sub > /dev/null 2>&1
update-rc.d Auto-Sub defaults > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/auto-sub > /dev/null 2>&1
chown -hR $mainuser:$maingroup $INSTALLDIR/auto-sub > /dev/null 2>&1
service Auto-Sub start > /dev/null 2>&1
sleep 5
service Auto-Sub stop > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/auto-sub > /dev/null 2>&1
service Auto-Sub start > /dev/null 2>&1
service="AutoSub"
address="http://$ip:8083"
port=":8083"
panel;
echo "";
echo "Finished";
sleep 1
}

install_HTPC_Manager()
{
service HTPC_Manager stop > /dev/null 2>&1
screen;
cd /tmp
echo
echo "    *****************You selected to install HTPC Manager****************";
echo
echo "Install python2.7? (it will take some time)"
if QUESTION; then
	install_PYTHON
	echo "Downloading and installing HTPC Manager...";
	t=0
	echo -n ""
	appinstall="libjpeg62 libjpeg62-dev libpng12-dev libfreetype6 libfreetype6-dev zlib1g-dev python-pip libpython2.6 python-dev python2.6-dev python-imaging build-essential"
	#items=( $appinstall )
	for item in ${appinstall[@]}; do
		echo -ne $t%           \\r
		if [ ! -e /var/lib/dpkg/info/"$item".list ]; then
			/usr/bin/apt-get -qq install "$item" > /dev/null 2>&1
			t=$(($t + 8))
		else
			t=$(($t + 8))
		fi
	done
	/usr/local/bin/pip-2.7 install PIL > /dev/null 2>&1
	git clone git://github.com/styxit/HTPC-Manager.git new_HTPC > /dev/null
	ret=$?
	if ! test "$ret" -eq 0; then
		echo >&2 "git clone HTPC Manager failed with exit status $ret"
		exit 1
	fi
	if [ -d $INSTALLDIR/HTPC_Manager ]; then
		cp -fRa /tmp/new_HTPC/. $INSTALLDIR/HTPC_Manager
		rm -fR /tmp/new_HTPC
	else
		mv /tmp/new_HTPC $INSTALLDIR/HTPC_Manager
	fi
	echo "Setting up startup options"
	echo '#! /bin/sh

### BEGIN INIT INFO
# Provides:          htpc_manager
# Required-Start:    $local_fs $network $remote_fs
# Required-Stop:     $local_fs $network $remote_fs
# Should-Start:      $NetworkManager
# Should-Stop:       $NetworkManager
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts instance of htpc_manager
# Description:       starts instance of htpc_manager using start-stop-daemon
### END INIT INFO

############### EDIT ME ##################
# startup args
DAEMON_OPTS="Htpc.py --daemon --port 8089"

# script name
NAME=HTPC_Manager

# app name
DESC=HTPC_Manager

# user
RUN_AS='${mainuser}'
# path to app
APP_PATH='${INSTALLDIR}'/HTPC_Manager
# path to python bin
DAEMON=/usr/local/bin/python2.7
PID_FILE=/var/run/HTPC_Manager.pid

############### END EDIT ME ##################

test -x $DAEMON || exit 0

set -e

case "$1" in
  start)
        echo "Starting $DESC"
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --pidfile $PID_FILE  --make-pidfile --exec $DAEMON -- $DAEMON_OPTS
        ;;
  stop)
        echo "Stopping $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE | rm -rf $PID_FILE
        ;;

  restart|force-reload)
        echo "Restarting $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE
        sleep 15
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --pidfile $PID_FILE  --make-pidfile --exec $DAEMON -- $DAEMON_OPTS
        ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0' > /etc/init.d/HTPC_Manager
	chmod 755 /etc/init.d/HTPC_Manager > /dev/null 2>&1
	update-rc.d HTPC_Manager defaults > /dev/null 2>&1
	chmod -R a+x $INSTALLDIR/HTPC_Manager > /dev/null 2>&1
	chown -hR $mainuser:$maingroup $INSTALLDIR/HTPC_Manager > /dev/null 2>&1
	service HTPC_Manager start > /dev/null 2>&1
	sleep 5
	service HTPC_Manager stop > /dev/null 2>&1
	chmod -R a+x $INSTALLDIR/HTPC_Manager > /dev/null 2>&1
	service HTPC_Manager start > /dev/null 2>&1
	service="HTPC_Manager"
	address="http://$ip:8089"
	port=":8089"
	panel;
	echo "";
	echo "Finished";
	sleep 1
else
	xdm="0"
fi
}

install_ML()
{
service mylar stop > /dev/null 2>&1
screen;
cd /tmp
echo
echo "    *****************You selected to install MyLar***********************";
echo
echo "Downloading and installing MyLar...";
git clone git://github.com/evilhero/mylar.git new_ML > /dev/null
ret=$?
if ! test "$ret" -eq 0; then
    echo >&2 "git clone mylar failed with exit status $ret"
    exit 1
fi
if [ -d $INSTALLDIR/mylar ]; then
	cp -fRa /tmp/new_ML/. $INSTALLDIR/mylar
	rm -fR /tmp/new_ML
else
	mv /tmp/new_ML $INSTALLDIR/mylar
	#echo '[global]
	#server.socket_host = "0.0.0.0"' > $INSTALLDIR/mylar/Mylar.ini
fi
#rm -fR $INSTALLDIR/mylar/.git
echo "Setting up startup options"
echo '#! /bin/sh

### BEGIN INIT INFO
# Provides:          mylar
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts instance of mylar
# Description:       starts instance of mylar using start-stop-daemon
### END INIT INFO

############### EDIT ME ##################
# startup args
DAEMON_OPTS="Mylar.py -q"

# script name
NAME=mylar

# app name
DESC=mylar

# user
RUN_AS='${mainuser}'
# path to app
APP_PATH='${INSTALLDIR}'/mylar
# path to python bin
DAEMON='${py}'
PID_FILE=/var/run/mylar.pid

############### END EDIT ME ##################

test -x $DAEMON || exit 0

set -e

case "$1" in
  start)
        echo "Starting $DESC"
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE  --make-pidfile --exec $DAEMON -- $DAEMON_OPTS
        ;;
  stop)
        echo "Stopping $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE | rm -rf $PID_FILE
        ;;

  restart|force-reload)
        echo "Restarting $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE
        sleep 15
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE  --make-pidfile --exec $DAEMON -- $DAEMON_OPTS
        ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0' > /etc/init.d/mylar
chmod 755 /etc/init.d/mylar > /dev/null 2>&1
update-rc.d mylar defaults > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/mylar > /dev/null 2>&1
chown -hR $mainuser:$maingroup $INSTALLDIR/mylar > /dev/null 2>&1
service mylar start > /dev/null 2>&1
sleep 5
service mylar stop > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/mylar > /dev/null 2>&1
service mylar start > /dev/null 2>&1
service="MyLar"
address="http://$ip:8090"
port=":8090"
panel;
echo "";
echo "Finished";
sleep 1
}

install_Bacula()
{
service bacula stop > /dev/null 2>&1
screen;
cd /tmp
echo
echo "    *****************You selected to install Bacula***********************";
echo
echo "Downloading and installing Bacula and Webacula...";
#http://cheatsheet.logicalwebhost.com/bacula-howto/ & http://tipstricks.itmatrix.eu/?p=612

mypass="1234"
appinstall="build-essential libpq-dev libncurses5-dev libssl-dev psmisc libmysql++-dev php5-gd php5-mysql libapache2-mod-php5 zendframework"
if [ -e /var/lib/dpkg/info/mysql-server.list ]; then
	getmysql;
else
	echo mysql-server mysql-server/root_password password $mypass | sudo debconf-set-selections
	echo mysql-server mysql-server/root_password_again password $mypass | sudo debconf-set-selections
	appinstall="build-essential libpq-dev libncurses5-dev libssl-dev psmisc libmysql++-dev php5-gd php5-mysql libapache2-mod-php5 zendframework mysql-server"
fi

echo "Downloading and installing Bacula...";
t=0
echo -n ""
for item in ${appinstall[@]}; do
	echo -ne $t%           \\r
	if [ ! -e /var/lib/dpkg/info/"$item".list ]; then
		/usr/bin/apt-get -qq install "$item" > /dev/null 2>&1
		t=$(($t + 7))
	else
		t=$(($t + 7))
	fi
done

wget http://downloads.sourceforge.net/project/bacula/bacula/5.2.13/bacula-5.2.13.tar.gz > /dev/null 2>&1
t=$(($t + 4))
tar fvxz bacula-5.2.13.tar.gz > /dev/null 2>&1
cd bacula-5.2.13 > /dev/null 2>&1
t=$(($t + 4))

./configure --prefix=/usr --sbindir=/usr/sbin --sysconfdir=/etc/bacula --with-scriptdir=/etc/bacula \
--enable-smartalloc --enable-conio --with-mysql --with-openssl --with-dir-user=bacula \
--with-dir-group=bacula --with-sd-user=bacula --with-sd-group=bacula --with-fd-user=root \
--with-fd-group=bacula --with-working-dir=/var/lib/bacula --with-pid-dir=/var/run \
--with-subsys-dir=/var/run/subsys > /dev/null 2>&1
t=$(($t + 4))
make && make install > /dev/null 2>&1
t=$(($t + 4))
MYSQL=$(which mysql)

#/etc/bacula/grant_mysql_privileges -u root -p
/etc/bacula/create_mysql_database -p$mypass > /dev/null 2>&1
/etc/bacula/make_mysql_tables -p$mypass > /dev/null 2>&1
/etc/bacula/grant_bacula_privileges -p$mypass > /dev/null 2>&1
echo "SET PASSWORD FOR 'bacula'@'localhost' = PASSWORD('bacula');FLUSH PRIVILEGES;" | mysql -p$mypass > /dev/null 2>&1




groupadd bacula > /dev/null 2>&1
useradd -p bacula -g bacula -d /var/lib/bacula -c "Bacula User" -s /bin/bash bacula > /dev/null 2>&1
#passwd bacula



chown root:bacula /var/lib/bacula > /dev/null 2>&1
mkdir /var/run/subsys > /dev/null 2>&1
chown -R bacula:bacula /var/run/subsys > /dev/null 2>&1
mkdir -p /backup/bacula-restores > /dev/null 2>&1
chown -R bacula:bacula /backup > /dev/null 2>&1
chmod 700 /backup -R
touch /var/log/bacula.log > /dev/null 2>&1
chown bacula:bacula /var/log/bacula.log > /dev/null 2>&1
head -n 11 /etc/init.d/skeleton > /etc/init.d/bacula
sed -e '1 d' -e 's/skeleton/bacula/' /etc/bacula/bacula >> /etc/init.d/bacula
chmod 755 /etc/init.d/bacula > /dev/null 2>&1
update-rc.d bacula defaults > /dev/null 2>&1
/etc/init.d/bacula start > /dev/null 2>&1

echo "Downloading and installing Bacula...";

wget http://sourceforge.net/projects/webacula/files/webacula/5.5.1/webacula-5.5.1.tar.gz > /dev/null 2>&1
tar zxf webacula-5.5.1.tar.gz > /dev/null 2>&1
mv webacula-5.5.1 /usr/share/webacula > /dev/null 2>&1

chown www-data:www-data /usr/share/webacula -R > /dev/null 2>&1
chown www-data:www-data /etc/bacula/bconsole.conf > /dev/null 2>&1
chown root:www-data /usr/sbin/bconsole

#cd /usr/share/webacula/install
#php check_system_requirements.php


echo '# See also application/config.ini

# bacula settings
db_name="bacula"
db_user="bacula"

# CHANGE_THIS
db_pwd="bacula"
webacula_root_pwd="bacula"' > /usr/share/webacula/install/db.conf
TZ=$(echo "$(omv_config_get "//system/time/timezone")" | sed 's.\/.\\\/.g')
sed -i "s#db.config.username = root#db.config.username = bacula#g" /usr/share/webacula/application/config.ini > /dev/null 2>&1
sed -i "s#db.config.password =#db.config.password = bacula#g" /usr/share/webacula/application/config.ini > /dev/null 2>&1
sed -i "s#def.timezone = \"Europe/Minsk\"#def.timezone = \"$TZ\"#g" /usr/share/webacula/application/config.ini > /dev/null 2>&1
sed -i "s#bacula.sudo = \"/usr/bin/sudo\"#bacula.sudo = \"\"#g" /usr/share/webacula/application/config.ini > /dev/null 2>&1
sed -i "s#bacula.bconsole = \"/sbin/bconsole\"#bacula.bconsole = \"/usr/sbin/bconsole\"#g" /usr/share/webacula/application/config.ini > /dev/null 2>&1
sed -i "s#'BACULA_VERSION', 12#'BACULA_VERSION', 14#g" /usr/share/webacula/html/index.php > /dev/null 2>&1
sed -i "s#Archive Device = /tmp#Archive Device = /backup#g" /etc/bacula/bacula-sd.conf > /dev/null 2>&1
sed -i "s#/tmp/bacula-restores#/backup/bacula-restores#g" /etc/bacula/bacula-dir.conf > /dev/null 2>&1
sed -i "s#dbpassword = \"\"#dbpassword = \"bacula\"#g" /etc/bacula/bacula-dir.conf > /dev/null 2>&1
sed -i "s#dbuser = \"\"; dbpassword = \"\"#dbuser = \"bacula\"; dbpassword = \"bacula\"#g" /etc/bacula/bacula-dir.conf > /dev/null 2>&1
#	Change this also?
#	mail = root@localhost = all, !skipped
#nano /usr/share/webacula/application/config.ini


cd /usr/share/webacula/install/MySql/ > /dev/null 2>&1
./10_make_tables.sh > /dev/null 2>&1
./20_acl_make_tables.sh > /dev/null 2>&1


echo '#
# Webacula - Web interface of a Bacula backup system
# Apache conf
#
# Allows only localhost by default
#

LoadModule rewrite_module /usr/lib/apache2/modules/mod_rewrite.so

AccessFileName .htaccess
RewriteLog "/var/log/apache2/mod_rewrite.log"
RewriteLogLevel 3

# SetEnv APPLICATION_ENV development
SetEnv APPLICATION_ENV production

Alias /webacula  /usr/share/webacula/html
<Directory /usr/share/webacula/html>
   RewriteEngine On

   RewriteBase   /webacula
   RewriteCond %{REQUEST_FILENAME} -s [OR]
   RewriteCond %{REQUEST_FILENAME} -l [OR]
   RewriteCond %{REQUEST_FILENAME} -d
   RewriteRule ^.*$ - [NC,L]
   RewriteRule ^.*$ index.php [NC,L]

   php_flag magic_quotes_gpc off
   php_flag register_globals off

   Options Indexes FollowSymLinks
   AllowOverride All
   Order allow,deny

   Allow from all
   # Allow from <your network>
</Directory>


<Directory /usr/share/webacula/docs>
   Order allow,deny
   Allow from all
</Directory>

<Directory /usr/share/webacula/application>
   Order allow,deny
   Allow from all
</Directory>

<Directory /usr/share/webacula/languages>
   Order allow,deny
   Allow from all
</Directory>

<Directory /usr/share/webacula/library>
   Order allow,deny
   Allow from all
</Directory>

<Directory /usr/share/webacula/install>
   Order allow,deny
   Allow from all
</Directory>

<Directory /usr/share/webacula/tests>
   Order allow,deny
   Allow from all
</Directory>

<Directory /usr/share/webacula/data>
   Order allow,deny
   Allow from all
</Directory>



#
# test mod_rewrite
#
<Directory /usr/share/webacula/html/test_mod_rewrite>
RewriteEngine On
   # for test mod_rewritee
RewriteBase   /webacula/test_mod_rewrite
RewriteRule ^testlink([^/]*).html$  index.php?testlink=$1 [L]

   php_flag magic_quotes_gpc off
   php_flag register_globals off

   Options Indexes FollowSymLinks
   AllowOverride All
   Order allow,deny

   Allow from all
   # Allow from <your network>
</Directory>' > /etc/apache2/openmediavault-webgui.d/webacula.conf

usermod -aG bacula www-data > /dev/null 2>&1
touch /var/log/apache2/webacula.error.log > /dev/null 2>&1
/etc/init.d/apache2 restart > /dev/null 2>&1

#/etc/bacula 777 perms
service="webacula"
port="/Webacula/"
panel;
echo "";
echo "Finished";
sleep 1


menu;
}

install_HP()
{
service headphones stop > /dev/null 2>&1
screen;
cd /tmp
if [ -f /etc/init.d/hpinit ]; then
	service hpinit stop > /dev/null 2>&1
	rm /etc/init.d/hpinit
	update-rc.d -f hpinit remove
fi
echo
echo "    ************You selected to install Headphones***********************";
echo
if [ "$hpm" == "1" ]; then
	echo "                           MASTER BRANCH"
	echo "Downloading and installing Headphones...";
	git clone git://github.com/rembo10/headphones.git new_HP > /dev/null
	ret=$?
	if ! test "$ret" -eq 0; then
		echo >&2 "git clone Headphones failed with exit status $ret"
		exit 1
	fi
elif [ "$hpd" == "1" ]; then
	echo "                           DEVELOP BRANCH"
	echo "Downloading and installing Headphones....";
	git clone git://github.com/rembo10/headphones.git -b develop new_HP > /dev/null
	ret=$?
	if ! test "$ret" -eq 0; then
		echo >&2 "git clone Headphones failed with exit status $ret"
		exit 1
	fi
fi
if [ -d $INSTALLDIR/headphones ]; then
	cp -fRa /tmp/new_HP/. $INSTALLDIR/headphones
	#a='git_path = ""'
	#b='git_path = \/usr\/bin\/git'
	#sed -i "s/$a/$b/g" $INSTALLDIR/headphones/config.ini
	rm -fR /tmp/new_HP
	#add check for git_path
else
	mv /tmp/new_HP $INSTALLDIR/headphones
	#add basic confid settings inc git_path
	echo "[General]
config_version = 2
http_port = 8181
http_host = 0.0.0.0
launch_browser = 0
log_dir = /headphones/logs
check_github_interval = 360" > $INSTALLDIR/headphones/config.ini
fi
rm -fR $INSTALLDIR/headphones/.git
echo "Setting up startup options"
echo '#! /bin/sh

### BEGIN INIT INFO
# Provides:          Headphones
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts instance of Headphones
# Description:       starts instance of Headphones using start-stop-daemon
### END INIT INFO

############### EDIT ME ##################
# startup args
DAEMON_OPTS=" Headphones.py -q"

# script name
NAME=headphones

# app name
DESC=headphones

# user
RUN_AS='${mainuser}'

# path to app
APP_PATH='${INSTALLDIR}'/headphones

# path to python bin
DAEMON='${py}'
PID_FILE=/var/run/headphones.pid

############### END EDIT ME ##################

test -x $DAEMON || exit 0

set -e

case "$1" in
  start)
        echo "Starting $DESC"
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE  --make-pidfile --exec $DAEMON -- $DAEMON_OPTS
        ;;
  stop)
        echo "Stopping $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE
        ;;

  restart|force-reload)
        echo "Restarting $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE
        sleep 15
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE  --make-pidfile --exec $DAEMON -- $DAEMON_OPTS
        ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0' > /etc/init.d/headphones
chmod 755 /etc/init.d/headphones > /dev/null 2>&1
update-rc.d headphones defaults > /dev/null 2>&1
chmod -R 777 $INSTALLDIR/headphones > /dev/null 2>&1
chown -hR $mainuser:$maingroup $INSTALLDIR/headphones > /dev/null 2>&1
service headphones start > /dev/null 2>&1
sleep 5
service headphones stop > /dev/null 2>&1
chmod -R 777 $INSTALLDIR/headphones > /dev/null 2>&1
service headphones start > /dev/null 2>&1
service="HeadPhones"
address="http://$ip:8181"
port=":8181"
panel;
echo "";
echo "Finished";
sleep 1
}

install_SB()
{
service sickbeard stop > /dev/null 2>&1
screen;
cd /tmp
if [ -f /etc/init.d/sbinit ]; then
	service sbinit stop > /dev/null 2>&1
	rm /etc/init.d/sbinit
	update-rc.d -f sbinit remove
fi
echo
echo "    *****************You selected to install SickBeard********************";
echo
if [ "$sbm" == "1" ]; then
	echo "                           MASTER BRANCH"
	echo "Downloading and installing SickBeard....";
	git clone git://github.com/midgetspy/Sick-Beard.git -b master new_SB > /dev/null
	ret=$?
	if ! test "$ret" -eq 0; then
		echo >&2 "git clone SickBeard failed with exit status $ret"
		exit 1
	fi
elif [ "$sbd" == "1" ]; then
	echo "                           DEVELOP BRANCH"
	echo "Downloading and installing SickBeard.....";
	git clone git://github.com/midgetspy/Sick-Beard.git -b development new_SB > /dev/null
	ret=$?
	if ! test "$ret" -eq 0; then
		echo >&2 "git clone SickBeard failed with exit status $ret"
		exit 1
	fi
elif [ "$sbt" == "1" ]; then
	echo "                           TORRENT BRANCH"
	echo "Downloading and installing SickBeard.....";
	git clone git://github.com/mr-orange/Sick-Beard.git new_SB > /dev/null
	ret=$?
	if ! test "$ret" -eq 0; then
		echo >&2 "git clone SickBeard failed with exit status $ret"
		exit 1
	fi
fi
if [ -d $INSTALLDIR/sickbeard ]; then
	cp -fRa /tmp/new_SB/. $INSTALLDIR/sickbeard
	a='git_path = "git"'
	b='git_path = \/usr\/bin\/git'
	sed -i "s/$a/$b/g" $INSTALLDIR/sickbeard/config.ini
	rm -fR /tmp/new_SB
else
	mv /tmp/new_SB/ $INSTALLDIR/sickbeard
	echo "[General]
	git_path = /usr/bin/git" > $INSTALLDIR/sickbeard/config.ini
fi
#rm -fR $INSTALLDIR/sickbeard/.git
echo "Setting up startup options"
echo '#! /bin/sh

### BEGIN INIT INFO
# Provides:          sickbeard
# Required-Start:    $local_fs $network $remote_fs
# Required-Stop:     $local_fs $network $remote_fs
# Should-Start:      $NetworkManager
# Should-Stop:       $NetworkManager
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts instance of Sick Beard
# Description:       starts instance of Sick Beard using start-stop-daemon
### END INIT INFO

############### EDIT ME ##################
# Path to store PID file
PID_FILE=/var/run/sickbeard/sickbeard.pid
PID_PATH=`dirname $PID_FILE`

# script name
NAME=sickbeard

# startup args
DAEMON_OPTS=" SickBeard.py -q --daemon --pidfile=${PID_FILE}"

PIDFILE=/var/run/sickbeard.pid
SETTINGS_LOADED=FALSE
RUN_AS='${mainuser}'
DAEMON='${py}'
APP_PATH='${INSTALLDIR}'/sickbeard
############### END EDIT ME ##################

test -x $DAEMON || exit 0

set -e

if [ ! -d $PID_PATH ]; then
    mkdir -p $PID_PATH
    chown $RUN_AS $PID_PATH
fi

if [ -e $PID_FILE ]; then
  PID=`cat $PID_FILE`
  if ! kill -0 $PID > /dev/null 2>&1; then
    echo "Removing stale $PID_FILE"
    rm $PID_FILE
  fi
fi

case "$1" in
  start)
        echo "Starting $DESC"
        cd $APP_PATH
		/usr/bin/git stash
		start-stop-daemon -d $APP_PATH -c $RUN_AS --start --pidfile $PID_FILE --exec $DAEMON -- $DAEMON_OPTS
        ;;
  stop)
        echo "Stopping $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE --retry 15
        ;;

  restart|force-reload)
        echo "Restarting $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE --retry 15
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --pidfile $PID_FILE --exec $DAEMON -- $DAEMON_OPTS
        ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0' > /etc/init.d/sickbeard
chmod 755 /etc/init.d/sickbeard > /dev/null 2>&1
update-rc.d sickbeard defaults > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/sickbeard > /dev/null 2>&1
chown -hR $mainuser:$maingroup $INSTALLDIR/sickbeard > /dev/null 2>&1
service sickbeard start > /dev/null 2>&1
sleep 5
service sickbeard stop > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/sickbeard > /dev/null 2>&1
service sickbeard start > /dev/null 2>&1
service="SickBeard"
address="http://$ip:8081"
port=":8081"
panel;
echo "";
echo "Finished";
sleep 1
}

install_SUB()
{
/etc/init.d/subsonic stop > /dev/null 2>&1
screen;
cd /tmp
echo
echo "    ****************You selected to install SubSonic*********************";
echo
echo "Downloading and installing SubSonic...";
echo "This one takes some time, please wait...";
line=$(grep "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" /etc/apt/sources.list.d/openmediavault-millers.list)
if [ $? == 1 ]; then
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" >> /etc/apt/sources.list.d/openmediavault-millers.list
fi

line=$(grep "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" /etc/apt/sources.list.d/openmediavault-millers.list)
if [ $? == 1 ]; then
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" >> /etc/apt/sources.list.d/openmediavault-millers.list
fi
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 > /dev/null 2>&1
/usr/bin/apt-get --quiet --quiet update
/usr/bin/apt-get -qy install oracle-java7-installer
#lame flac faad vorbis-tools ffmpeg > /dev/null 2>&1
screen;
cd /tmp
echo
echo "    ****************You selected to install SubSonic*********************";
echo
echo "Downloading and installing SubSonic...";
echo "This one takes some time, please wait...";
wget http://switch.dl.sourceforge.net/project/subsonic/subsonic/4.9.beta3/subsonic-4.9.beta3.deb
# -O ./subsonic-4.7.deb > /dev/null 2>&1
dpkg -i subsonic-4.9.beta3.deb > /dev/null 2>&1
echo "Setting up startup options"
#/etc/init.d/subsonic stop > /dev/null 2>&1
rm subsonic-4.9.beta3.deb
if [ "$mc" == "0" ]; then
	service="SubSonic"
	address="http://$ip:4040"
	port=":4040"
	panel;
	echo "";
	echo "Finished";
	sleep 1
fi
}

install_BBS()
{
screen;
echo
echo "    ***************You selected to install BicBucStriim******************";
echo
echo "Downloading and installing BicBucStriim...";
echo " ";
t=9
echo -ne 9%           \\r
appinstall="php5-sqlite apt-get install php5-gd"
for item in ${appinstall[@]}; do
	echo -ne $t%           \\r
	if [ ! -e /var/lib/dpkg/info/"$item".list ]; then
		/usr/bin/apt-get -qq install  "$item"
		t=$(($t + 7))
	else
		t=$(($t + 7))
	fi
done
#mkdir -p /var/www/openmediavault/bbs > /dev/null 2>&1
cd /var/www/openmediavault > /dev/null 2>&1
wget 'http://projekte.textmulch.de/bicbucstriim/downloads/BicBucStriim-1.1.0.zip' -O /var/www/openmediavault/BicBucStriim-1.1.0.zip > /dev/null 2>&1
unzip -o /var/www/openmediavault/BicBucStriim-1.1.0.zip -d /var/www/openmediavault/ > /dev/null 2>&1
mv /var/www/openmediavault/BicBucStriim-1.1.0 /var/www/openmediavault/bbs > /dev/null 2>&1
rm -Rf /var/www/openmediavault/BicBucStriim-1.1.0.zip > /dev/null 2>&1
chown openmediavault:openmediavault -R /var/www/openmediavault/bbs > /dev/null 2>&1
chmod -R ga+w /var/www/openmediavault/bbs > /dev/null 2>&1
#chmod 777 -R /var/www/openmediavault/extplorer/ftp_tmp > /dev/null 2>&1
service="BicBucStriim"
address="http://$ip/bbs"
port="/bbs"
panel;
echo "";
echo "Finished";
sed -i -e 's/AllowOverride None/AllowOverride All/' /etc/apache2/openmediavault-webgui.d/default.conf > /dev/null 2>&1
a2enmod rewrite
service apache2 restart > /dev/null 2>&1
sleep 1
}

install_EXP()
{
screen;
echo
echo "    ****************You selected to install Extplorer********************";
echo
echo "Downloading and installing Extplorer...";
echo " ";
t=9
echo -ne 9%           \\r
appinstall="php-auth-http php-mail-mime libjs-extjs php-compat php-mime-type php-http-webdav-server libjs-yui php-auth libjs-edit-area php-services-json php-net-ftp php-mail-mimedecode php-geshi"
for item in ${appinstall[@]}; do
	echo -ne $t%           \\r
	if [ ! -e /var/lib/dpkg/info/"$item".list ]; then
		/usr/bin/apt-get -qq install  "$item"
		t=$(($t + 7))
	else
		t=$(($t + 7))
	fi
done
mkdir -p /var/www/openmediavault/extplorer > /dev/null 2>&1
cd /var/www/openmediavault/extplorer > /dev/null 2>&1
wget 'http://netcologne.dl.sourceforge.net/project/extplorer/extplorer/eXtplorer_2.1.3.zip' -O /var/www/openmediavault/extplorer/eXtplorer_2.1.3.zip > /dev/null 2>&1
unzip -o /var/www/openmediavault/extplorer/eXtplorer_2.1.3.zip -d /var/www/openmediavault/extplorer > /dev/null 2>&1
rm -Rf /var/www/openmediavault/extplorer/eXtplorer_2.1.3.zip > /dev/null 2>&1
chown openmediavault:openmediavault -R /var/www/openmediavault/extplorer > /dev/null 2>&1
chmod 755 -R /var/www/openmediavault/extplorer > /dev/null 2>&1
chmod 777 -R /var/www/openmediavault/extplorer/ftp_tmp > /dev/null 2>&1
echo '<?php
/** @version $Id: .htusers.php 135 2009-01-27 21:57:15Z ryu_ms $ */
/** ensure this file is being included by a parent file */
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );

$GLOBALS["users"]=array(
        array("admin","21232f297a57a5a743894a0e4a801fc3",empty($_SERVER['DOCUMENT_ROOT'])?realpath(dirname(__FILE__).'/..'):$_SERVER['DOCUMENT_ROOT'],"http://localhost",1,"",7,1),
); ?>'  > /var/www/openmediavault/extplorer/.htusers.php

#cat /usr/share/doc/extplorer/example.dot.htusers.php >/etc/extplorer/.htusers.php
service="Extplorer"
address="http://$ip/extplorer"
port="/extplorer"
panel;
echo "";
echo "Finished";
sleep 1
}

install_CP()
{
service CouchPotato stop > /dev/null 2>&1
screen;
cd /tmp
if [ -f /etc/init.d/cpinit ]; then
	service cpinit stop > /dev/null 2>&1
	rm /etc/init.d/cpinit
	update-rc.d -f cpinit remove
fi
echo
echo "    ************You selected to install CouchPotato Version 1*************";
echo
echo "Downloading and installing CouchPotato...";
git clone git://github.com/RuudBurger/CouchPotato.git new_CP > /dev/null
ret=$?
if ! test "$ret" -eq 0; then
	echo >&2 "git clone CouchPotato Version 1 failed with exit status $ret"
    exit 1
fi
if [ -d $INSTALLDIR/CouchPotato ]; then
	cp -fRa /tmp/new_CP/. $INSTALLDIR/CouchPotato
	rm -fR /tmp/new_CP
else
	mv /tmp/new_CP $INSTALLDIR/CouchPotato
fi
echo "Setting up startup options"
echo '#!/bin/bash
#
# Copyright (C) 2008-2010 by JCF Ploemen <linux@jp.pp.ru>
# released under GPL, version 2 or later

### BEGIN INIT INFO
# Provides:          couchpotato
# Required-Start:    $local_fs $network $remote_fs
# Required-Stop:     $local_fs $network $remote_fs
# Should-Start:      NetworkManager
# Should-Stop:       NetworkManager
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Couchpotato
### END INIT INFO

# main variables
DESC="CouchPotato"
DEFOPTS="-d"
PIDFILE=/var/run/couchpotato.pid
SETTINGS_LOADED=FALSE
USER='${mainuser}'
PYTHONEXEC='${py}'
DAEMON='${INSTALLDIR}'/CouchPotato/CouchPotato.py
# these are only accepted from the settings file
#unset USER CONFIG HOST PORT EXTRAOPTS

. /lib/lsb/init-functions

check_retval()
{
        if [ $? -eq 0 ]; then
                log_end_msg 0
                return 0
        else
                log_end_msg 1
                exit 1
        fi
}

is_running()
{
        # returns 0 when running, 1 otherwise
        PID="$(pgrep -f -x -u $USER "$PYTHONEXEC $DAEMON $DEFOPTS.*")"
        RET=$?
        [ $RET -gt 1 ] && exit 1 || return $RET
}

load_settings()
{
                PORT=$(grep -m 1 "^port" /couchpotato/config.ini | awk "{print $3}")
                HOST="0.0.0.0" #Set CouthPotato address here.
                EXTRAOPTS=" > /dev/null 2>&1 &"
                OPTIONS="$DEFOPTS"
               # [ -n "$CONFIG" ] && OPTIONS="$OPTIONS --config-file $CONFIG"
               #[ -n "$HOST" ] && SERVER="$HOST" || SERVER=
               #[ -n "$PORT" ] && SERVER="$SERVER:$PORT"
               # [ -n "$SERVER" ] && OPTIONS="$OPTIONS"
                [ -n "$EXTRAOPTS" ] && OPTIONS="$OPTIONS $EXTRAOPTS"
                SETTINGS_LOADED=TRUE
        return 0
}

start_sab()
{
        load_settings || exit 0
        if ! is_running; then
                log_daemon_msg "Starting $DESC"
		start-stop-daemon --quiet --chuid $USER --start --exec $DAEMON -- $OPTIONS
                check_retval
                # create a pidfile; we dont use it but some monitoring app likes to have one
                [ -w $(dirname $PIDFILE) ] && \
                        pgrep -f -x -n -u $USER "$PYTHONEXEC $DAEMON $OPTIONS" > $PIDFILE
        else
                log_success_msg "$DESC: already running (pid $PID)"
        fi
}

stop_sab()
{
        load_settings || exit 0
        if is_running; then
                TMPFILE=$(mktemp /tmp/couchpotato.XXXXXXXXXX || exit 1)
                trap "[ -f $TMPFILE ] && rm -f $TMPFILE" EXIT
                echo "$PID" > $TMPFILE
                log_daemon_msg "Stopping $DESC"
                start-stop-daemon --stop --user $USER --pidfile $TMPFILE --retry 30
                check_retval
        else
                log_success_msg "$DESC: not running"
        fi
        [ -f $PIDFILE ] && rm -f $PIDFILE
}

case "$1" in
        start)
                start_sab
        ;;
        stop)
                stop_sab
        ;;
        force-reload|restart)
                stop_sab
                start_sab
        ;;
        status)
                if is_running; then
                        log_success_msg "$DESC: running (pid $PID)"
                else
                        log_success_msg "$DESC: not running"
                        [ -f $PIDFILE ] && exit 1 || exit 3
                fi
        ;;
        *)
                log_failure_msg "Usage: $0 {start|stop|restart|force-reload|status}"
                exit 3
        ;;
esac

exit 0' > /etc/init.d/CouchPotato
chmod 755 /etc/init.d/CouchPotato > /dev/null 2>&1
update-rc.d CouchPotato defaults > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/CouchPotato > /dev/null 2>&1
chown -hR $mainuser:$maingroup $INSTALLDIR/CouchPotato > /dev/null 2>&1
service CouchPotato start > /dev/null 2>&1
sleep 5
service CouchPotato stop > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/CouchPotato > /dev/null 2>&1
service CouchPotato start > /dev/null 2>&1
service="CouchPotato"
address="http://$ip:5000"
port=":5000"
panel;
echo "";
echo "Finished";
sleep 1
}

install_CPS()
{
screen;
cd /tmp
echo
echo "    ************You selected to install CouchPotato Version 2*************";
if [ "$cpm" == "1" ]; then
	echo "                           MASTER BRANCH"
	echo "Downloading and installing CouchPotato...";
	git clone git://github.com/RuudBurger/CouchPotatoServer.git new_CP > /dev/null
	ret=$?
	if ! test "$ret" -eq 0; then
		echo >&2 "git clone CouchPotato Version 2 failed with exit status $ret"
		exit 1
	fi
elif [ "$cpd" == "1" ]; then
	echo "                           DEVELOP BRANCH"
	echo "Downloading and installing CouchPotato...";
	git clone git://github.com/RuudBurger/CouchPotatoServer.git -b develop new_CP > /dev/null
	ret=$?
	if ! test "$ret" -eq 0; then
		echo >&2 "git clone CouchPotato Version 2 failed with exit status $ret"
		exit 1
	fi
fi
if [ -d $INSTALLDIR/CouchPotatoServer ]; then
	cp -fRa /tmp/new_CP/. $INSTALLDIR/CouchPotatoServer
	rm -fR /tmp/new_CP
	new="1"
else
	mv /tmp/new_CP $INSTALLDIR/CouchPotatoServer
	new="0"
fi
service CouchPotatoServer stop > /dev/null 2>&1
if [ -f /etc/init.d/cpinit ]; then
	service cpinit stop > /dev/null 2>&1
	rm /etc/init.d/cpinit
	update-rc.d -f cpinit remove
fi
echo "Setting up startup options"
echo '#! /bin/sh

### BEGIN INIT INFO
# Provides:          CouchPotatoServer
# Required-Start:    $local_fs $network $remote_fs
# Required-Stop:     $local_fs $network $remote_fs
# Should-Start:      $NetworkManager
# Should-Stop:       $NetworkManager
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts instance of CouchPotatoServer
# Description:       starts instance of CouchPotatoServer using start-stop-daemon
### END INIT INFO

set -e

############### EDIT ME ##################
RUN_AS='${mainuser}'
RUN_GRP='${maingroup}'
APP_PATH='${INSTALLDIR}'/CouchPotatoServer/
DAEMON='${py}'
PID_FILE=/var/run/couchpotato/server.pid
PID_PATH=$(dirname $PID_FILE)
NAME=CouchPotatoServer
DESC=CouchPotatoServer
DAEMON_OPTS=" CouchPotato.py --daemon --pid_file=${PID_FILE}"
############### END EDIT ME ##################

test -x $DAEMON || exit 0

# Get lsb functions
. /lib/lsb/init-functions

# Create PID directory if not exist and ensure the CouchPotato user can write to it
if [ ! -d $PID_PATH ]; then
    mkdir -p $PID_PATH
    chown $RUN_AS $PID_PATH
fi

if [ ! -d $DATA_DIR ]; then
    mkdir -p $DATA_DIR
    chown $RUN_AS $DATA_DIR
fi

if [ -e $PID_FILE ]; then
    PID=`cat $PID_FILE`
    if ! kill -0 $PID > /dev/null 2>&1; then
        echo "Removing stale $PID_FILE"
        rm $PID_FILE
    fi
fi

case "$1" in
  start)
        echo "Starting $DESC"
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --pidfile $PID_FILE --exec $DAEMON -- $DAEMON_OPTS
        ;;
  stop)
        echo "Stopping $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE --retry 15
        ;;
  restart|force-reload)
        echo "Restarting $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE --retry 15
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --pidfile $PID_FILE --exec $DAEMON -- $DAEMON_OPTS
        ;;
  status)
       status_of_proc -p $PID_FILE "$DAEMON" "$NAME"
       ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0' > /etc/init.d/CouchPotatoServer

chmod 755 /etc/init.d/CouchPotatoServer > /dev/null 2>&1
update-rc.d CouchPotatoServer defaults > /dev/null 2>&1
#mkdir /root/.couchpotato/ > /dev/null 2>&1
#chmod -R a+x /root/.couchpotato
chmod -R a+x $INSTALLDIR/CouchPotatoServer > /dev/null 2>&1
chown -hR $mainuser:$maingroup $INSTALLDIR/CouchPotatoServer > /dev/null 2>&1
service CouchPotatoServer start > /dev/null 2>&1
sleep 5
#service CouchPotatoServer stop > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/CouchPotatoServer > /dev/null 2>&1
if [ -d $INSTALLDIR/CouchPotatoServer ]; then
	rm -Rf ~/.couchpotato > /dev/null 2>&1
	service CouchPotatoServer restart > /dev/null 2>&1
fi
service="CouchPotatoServer"
address="http://$ip:5050"
port=":5050"
panel;
echo "";
echo "Finished";
sleep 1
}

install_SAB()
{
screen;
cd /tmp
echo
echo "    ************You selected to install latest SABnzbd Stable************";
echo ""
STABLE=$(wget -q -O - https://raw.github.com/cptjhmiller/OMV_Installers/master/latest | awk '/0/{gsub(/\06/,"");print}')
#STABLE=($(wget -q -O - https://raw.github.com/cptjhmiller/OMV_Installers/master/latest | awk '/0/{gsub(/\015/,"");print}'))
echo "Downloading latest STABLE SABnzbd $STABLE"
wget -nv http://downloads.sourceforge.net/project/sabnzbdplus/sabnzbdplus/${STABLE}/SABnzbd-${STABLE}-src.tar.gz > /dev/null 2>&1
tar xzf SABnzbd-${STABLE}-src.tar.gz > /dev/null 2>&1
rm SABnzbd*.tar.gz
service SABnzbd stop > /dev/null 2>&1
if [ -d $INSTALLDIR/SABnzbd ]; then
	cp -fRa /tmp/SABnzbd-${STABLE}/. $INSTALLDIR/SABnzbd/
	rm -fR /tmp/SABnzbd-${STABLE}
else
	mv /tmp/SABnzbd-${STABLE} $INSTALLDIR/SABnzbd
fi
if [ -f /etc/init.d/sabinit ]; then
	service sabinit stop > /dev/null 2>&1
	update-rc.d -f sabinit remove
	rm /etc/init.d/sabinit
fi
if [ -f /etc/init.d/sabnzbdplus ]; then
	service sabnzbdplus stop > /dev/null 2>&1
	update-rc.d -f sabnzbdplus remove
	rm /etc/init.d/sabnzbdplus
fi
echo "Setting up startup options";
SABSETTINGS="'1s/^#\! \?\([a-z0-9\.\/]\+\)\(.*\)/\1(\2)?/p'"
FAKE="'{print "'$3'"}'"
echo '#!/bin/bash
#
# Copyright (C) 2008-2010 by JCF Ploemen <linux@jp.pp.ru>
# released under GPL, version 2 or later

################################################
#                                              #
#  TO CONFIGURE EDIT /etc/default/sabnzbdplus  #
#                                              #
################################################

### BEGIN INIT INFO
# Provides:          sabnzbdplus
# Required-Start:    $local_fs $network $remote_fs
# Required-Stop:     $local_fs $network $remote_fs
# Should-Start:      NetworkManager
# Should-Stop:       NetworkManager
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: SABnzbd+ binary newsgrabber
### END INIT INFO
DESC="SABnzbd+ binary newsgrabber"
APPPATH='${INSTALLDIR}'
CONFIG="$APPPATH/SABnzbd/sabnzbd.ini"
PYTHONEXEC="'${py}'"
DAEMON='${INSTALLDIR}'/SABnzbd/SABnzbd.py
USER="'${mainuser}'"
if [ -f "$CONFIG" ]; then
	PORT=$(grep -m 1 "^port" '${INSTALLDIR}'/SABnzbd/sabnzbd.ini | awk '${FAKE}')
else
	PORT="8080"
fi
#sabnzbd_port.pid
PIDFILE="/var/run/sabnzbd-$PORT.pid"
DEFOPTS=" -OO $DAEMON --daemon --pid /var/run/"
#
# these are only accepted from the settings file
#unset USER CONFIG HOST PORT EXTRAOPTS

. /lib/lsb/init-functions

is_running()
{
# returns 0 when running, 1 otherwise
if [ -f $PIDFILE ]; then
	PID=`cat $PIDFILE`
	return 0
fi
return 1
}

load_settings()
{
HOST="0.0.0.0" #Set SABnzbd address here.
EXTRAOPTS=""
OPTIONS="$DEFOPTS"
[ -n "$CONFIG" ] && OPTIONS="$OPTIONS --config-file $CONFIG"
[ -n "$HOST" ] && SERVER="$HOST" || SERVER=
[ -n "$PORT" ] && SERVER="$SERVER:$PORT"
[ -n "$SERVER" ] && OPTIONS="$OPTIONS --server $SERVER"
[ -n "$EXTRAOPTS" ] && OPTIONS="$OPTIONS $EXTRAOPTS"
}

start_sab()
{
load_settings;
if ! is_running; then
	log_daemon_msg "Starting $DESC"
	start-stop-daemon --quiet --pidfile $PIDFILE --chuid $USER --start --exec $PYTHONEXEC -- $OPTIONS
else
	log_success_msg "$DESC: already running (pid $PID)"
fi
}

up_sab()
{
a=""
#Pull latest version number and assign to variable and then display it
STABLE=($(wget -q -O - https://raw.github.com/cptjhmiller/OMV_Installers/master/latest))
echo "Downloading latest STABLE SABnzbd $STABLE"
cd /tmp
wget -nv http://downloads.sourceforge.net/project/sabnzbdplus/sabnzbdplus/${STABLE}/SABnzbd-${STABLE}-src.tar.gz
echo "-- Extracting SABnzbd archive --"
tar xzf SABnzbd-${STABLE}-src.tar.gz
echo "-- Installing SABnzbd --"
rm SABnzbd*.tar.gz
cp -R /tmp/SABnzbd-*/* $APPPATH/SABnzbd/
rm -R /tmp/SABnzbd-${STABLE}
}

stop_sab()
{
load_settings;
if is_running; then
	TMPFILE=$(mktemp /tmp/sabnzbdplus.XXXXXXXXXX || exit 1)
	trap "[ -f $TMPFILE ] && rm -f $TMPFILE" EXIT
	echo "$PID" > $TMPFILE
	log_daemon_msg "Stopping $DESC"
	start-stop-daemon --stop --user $USER --pidfile $TMPFILE --retry 30
else
	log_success_msg "$DESC: not running"
fi
[ -f $PIDFILE ] && rm -f $PIDFILE
}

case "$1" in
        start)
                start_sab
        ;;
        stop)
                stop_sab
        ;;
        force-reload|restart)
                stop_sab
                start_sab
        ;;
        update)
                stop_sab
                up_sab
                start_sab
        ;;
        status)
                if is_running; then
                log_success_msg "$DESC: running (pid $PID)"
					else
                log_success_msg "$DESC: not running"
                [ -f $PIDFILE ] && exit 1 || exit 3
                fi
        ;;
        *)
                log_failure_msg "Usage: $0 {start|stop|restart|force-reload|update|status}"
                exit 3
        ;;
esac

exit 0' > /etc/init.d/SABnzbd
chmod 755 /etc/init.d/SABnzbd > /dev/null 2>&1
update-rc.d SABnzbd defaults > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/SABnzbd > /dev/null 2>&1
chown -hR $mainuser:$maingroup $INSTALLDIR/SABnzbd > /dev/null 2>&1
service SABnzbd start > /dev/null 2>&1
sleep 5
service SABnzbd stop > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/SABnzbd > /dev/null 2>&1
service SABnzbd start > /dev/null 2>&1
service="SABnzbd"
address="http://$ip:8080"
port=":8080"
panel;
echo "";
echo "Finished";
sleep 1
}

install_LL()
{
service LazyLibrarian stop > /dev/null 2>&1
screen;
cd /tmp
echo
echo "    *************You selected to install latest LazyLibrarian*************";
echo ""
echo "Downloading and installing LazyLibrarian...";
git clone git://github.com/herman-rogers/LazyLibrarian-1.git new_ll > /dev/null
ret=$?
if ! test "$ret" -eq 0; then
    echo >&2 "git clone LazyLibrarian failed with exit status $ret"
    exit 1
fi
if [ -d $INSTALLDIR/LazyLibrarian ]; then
	cp -fRa /tmp/new_ll/. $INSTALLDIR/LazyLibrarian
	rm -fR /tmp/new_ll
else
	mv /tmp/new_ll $INSTALLDIR/LazyLibrarian
fi
service LazyLibrarian stop > /dev/null 2>&1
echo "Setting up startup options"
echo '#! /bin/sh

# Copyright (C) 2011- by Mar2zz <LaSi.Mar2zz@gmail.com>
# released under GPL, version 2 or later

### BEGIN INIT INFO
# Provides:          LazyLibrarian
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts instance of LazyLibrarian
# Description:       starts instance of LazyLibrarian using start-stop-daemon
### END INIT INFO

# main variables
DAEMON="'${py}'"
DESC=LazyLibrarian
RUN_AS='${mainuser}'
APP_PATH='${INSTALLDIR}'/LazyLibrarian/
. /lib/lsb/init-functions

[ -x $DAEMON ] || {
    log_warning_msg "$DESC: Cant execute daemon, aborting. See $DAEMON";
    return 1; }

[ -r $SETTINGS ] || {
    log_warning_msg "$DESC: Cant read settings, aborting. See $SETTINGS";
    return 1; }

check_retval() {
    if [ $? -eq 0 ]; then
        log_end_msg 0
        return 0
    else
        log_end_msg 1
        exit 1
    fi
}

load_settings() {
    DAEMON_OPTS="LazyLibrarian.py --quiet -d --nolaunch"
        [ -n "$CONFIG" ] && DAEMON_OPTS="$DAEMON_OPTS --config=$CONFIG"
        [ -z "$CONFIG" ] && DAEMON_OPTS="$DAEMON_OPTS --config=/root/.lazylibrarian/config.ini"
        [ -n "$DATADIR" ] && DAEMON_OPTS="$DAEMON_OPTS --datadir=$DATADIR"
        [ -z "$DATADIR" ] && DAEMON_OPTS="$DAEMON_OPTS --datadir=/root/.lazylibrarian"
        if ! [ -n "$PID_FILE" ]; then
            PID_FILE=/var/run/lazylibrarian/lazylibrarian.pid
        fi
        DAEMON_OPTS="$DAEMON_OPTS --pidfile=$PID_FILE"
    return 0
}

load_settings || exit 0

is_running () {
    # returns 1 when running, else 0.
    PID=$(pgrep -f "$DAEMON_OPTS")
    RET=$?
    [ $RET -gt 1 ] && exit 1 || return $RET
}

handle_pid () {
    PID_PATH=`dirname $PID_FILE`
    [ -d $PID_PATH ] || mkdir -p $PID_PATH && chown -R $RUN_AS $PID_PATH > /dev/null 2>&1 || {
        log_warning_msg "$DESC: Could not create $PID_FILE, aborting.";
        return 1;}
}

enable_updates () {
    chown -R $RUN_AS $APP_PATH > /dev/null 2>&1 || {
        log_warning_msg "$DESC: $APP_PATH not writable for web-updates, See $SETTINGS";
        return 0; }
}

start_lazylibrarian () {
    if ! is_running; then
        log_daemon_msg "Starting $DESC"
        [ "$WEB_UPDATE" = 1 ] && enable_updates
        handle_pid
        start-stop-daemon -o -d $APP_PATH -c $RUN_AS --start --pidfile $PID_FILE --exec $DAEMON -- $DAEMON_OPTS
        check_retval
    else
        log_success_msg "$DESC: already running (pid $PID)"
    fi
}

stop_lazylibrarian () {
    if is_running; then
        log_daemon_msg "Stopping $DESC"
        start-stop-daemon -o --stop --pidfile $PID_FILE --retry 15
        check_retval
    else
        log_success_msg "$DESC: not running"
    fi
}


case "$1" in
    start)
        start_lazylibrarian
        ;;
    stop)
        stop_lazylibrarian
        ;;
    restart|force-reload)
        stop_lazylibrarian
        start_lazylibrarian
        ;;
    *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0' > /etc/init.d/LazyLibrarian
chmod 755 /etc/init.d/LazyLibrarian > /dev/null 2>&1
update-rc.d LazyLibrarian defaults > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/LazyLibrarian > /dev/null 2>&1
chown -hR $mainuser:$maingroup $INSTALLDIR/LazyLibrarian > /dev/null 2>&1
service LazyLibrarian start > /dev/null 2>&1
sleep 5
service LazyLibrarian stop > /dev/null 2>&1
chmod -R a+x $INSTALLDIR/LazyLibrarian > /dev/null 2>&1
service LazyLibrarian start > /dev/null 2>&1
service="LazyLibrarian"
address="http://$ip:5299"
port=":5299"
panel;
echo "";
echo "Finished";
sleep 1
}

install_PY()
{
#https://github.com/pyload/pyload
/etc/init.d/pyload stop > /dev/null 2>&1
screen;
cd /tmp
echo
echo "    *****************You selected to install PyLoad**********************";
echo
echo "Downloading and installing PyLoad.......";
echo "This one takes some time, please wait...";
wget http://download.pyload.org/pyload-cli-v0.4.9-all.deb > /dev/null 2>&1
#dpkg -i pyload-cli-v0.4.9-all.deb > /dev/null 2>&1
t=10
echo -ne 10%           \\r
#appinstall="tesseract-orc"
apt-get -qq install liblcms1 libgmp3c2 libjpeg62 python-central python-imaging python-openssl python-crypto python-pycurl > /dev/null 2>&1
apt-get install -f > /dev/null 2>&1
#for item in ${appinstall[@]}; do
#	echo -ne $t%           \\r
#	if [ ! -e /var/lib/dpkg/info/"$item".list ]; then
#		/usr/bin/apt-get -qq install  "$item"
#		t=$(($t + 25))
#	else
#		t=$(($t + 25))
#	fi
#done
dpkg -i  pyload-cli-v0.4.9-all.deb > /dev/null 2>&1
echo "Setting up startup options"
echo '#!/bin/sh

### BEGIN INIT INFO
# Provides:          pyload
# Required-Start:    $syslog $local_fs $network $remote_fs
# Required-Stop:     $syslog $local_fs $network $remote_fs
# Should-Start:      $remote_fs $named
# Should-Stop:       $remote_fs $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts pyload daemon
# Description:       This script runs the pyload service
### END INIT INFO

# Starts and stops the pyload daemon.

PATH=/bin:/usr/bin:/sbin:/usr/sbin
DAEMON=/usr/share/pyload/pyLoadCore.py
PIDFILE=/root/.pyload/pyload.pid
configdir=/root/.pyload

. /lib/lsb/init-functions

start() {
    log_daemon_msg "Starting pyLoad server"
    $DAEMON --configdir=$configdir --daemon

    if [ $? != 0 ]; then
        log_end_msg 1
        exit 1
    else
        log_end_msg 0
    fi
}

stop() {
    log_daemon_msg "Stoping pyLoad server"

    $DAEMON -q

    if [ $? != 0 ]; then
        log_end_msg 1
#        exit 1
    else
        log_end_msg 0
    fi
}

case "$1" in
    start)
       start
   ;;

    stop)
       stop
   ;;

    force-reload)
      stop
      sleep 5
      start
        ;;

    restart)
       stop
       sleep 2
       start
   ;;

    *)
   echo "Usage: $0 {start|stop|restart|force-reload}"
   exit 1
   ;;
esac

exit 0' > /etc/init.d/pyload
mkdir -p /root/.pyload > /dev/null 2>&1
cd /root/.pyload > /dev/null 2>&1
wget https://raw.github.com/cptjhmiller/OMV_Installers/master/files.tar.gz --no-check-certificate > /dev/null 2>&1
tar zxvf files.tar.gz > /dev/null 2>&1
cd /tmp > /dev/null 2>&1
echo 'version: 1

remote - "Remote":
        bool nolocalauth : "No authentication on local connections" = True
        bool activated : "Activated" = True
        int port : "Port" = 7227
        ip listenaddr : "Adress" = 0.0.0.0

log - "Log":
        int log_size : "Size in kb" = 100
        folder log_folder : "Folder" = Logs
        bool file_log : "File Log" = True
        int log_count : "Count" = 5
        bool log_rotate : "Log Rotate" = True

permission - "Permissions":
        str group : "Groupname" = users
        bool change_dl : "Change Group and User of Downloads" = False
        bool change_file : "Change file mode of downloads" = False
        str user : "Username" = user
        str file : "Filemode for Downloads" = 0644
        bool change_group : "Change group of running process" = False
        str folder : "Folder Permission mode" = 0755
        bool change_user : "Change user of running process" = False

general - "General":
        en;de;fr;it;es;nl;sv;ru;pl;cs;sr;pt_BR language : "Language" = en
        folder download_folder : "Download Folder" = Downloads
        bool checksum : "Use Checksum" = False
        bool folder_per_package : "Create folder for each package" = True
        bool debug_mode : "Debug Mode" = False
        int min_free_space : "Min Free Space (MB)" = 200
        int renice : "CPU Priority" = 0

ssl - "SSL":
        file cert : "SSL Certificate" = ssl.crt
        bool activated : "Activated" = False
        file key : "SSL Key" = ssl.key

webinterface - "Webinterface":
        str template : "Template" = default
        bool activated : "Activated" = True
        str prefix : "Path Prefix" =
        builtin;threaded;fastcgi;lightweight server : "Server" = builtin
        ip host : "IP" = 0.0.0.0
        bool https : "Use HTTPS" = False
        int port : "Port" = 8888

proxy - "Proxy":
        str username : "Username" = None
        bool proxy : "Use Proxy" = False
        str address : "Address" = "localhost"
        password password : "Password" = None
        http;socks4;socks5 type : "Protocol" = http
        int port : "Port" = 7070

reconnect - "Reconnect":
        time endTime : "End" = 0:00
        bool activated : "Use Reconnect" = True
        str method : "Method" = ./reconnect.sh
        time startTime : "Start" = 0:00

download - "Download":
        int max_downloads : "Max Parallel Downloads" = 3
        bool limit_speed : "Limit Download Speed" = False
        str interface : "Download interface to bind (ip or Name)" = None
        bool skip_existing : "Skip already existing files" = False
        int max_speed : "Max Download Speed in kb/s" = -1
        bool ipv6 : "Allow IPv6" = False
        int chunks : "Max connections for one download" = 3

downloadTime - "Download Time":
        time start : "Start" = 0:00
        time end : "End" = 0:00' > /root/.pyload/pyload.conf
chmod 755 /etc/init.d/pyload > /dev/null 2>&1
update-rc.d pyload defaults > /dev/null 2>&1
#update-rc.d pyload start 20 2 3 4 5 . stop 10 0 1 6 . > /dev/null 2>&1
service pyload start > /dev/null 2>&1
service="PyLoad"
address="http://$ip:8888"
port=":8888"
panel;
echo "";
echo "Finished";
service pyload restart > /dev/null 2>&1
}

install_DEL()
{
/etc/init.d/deluge-daemon stop > /dev/null 2>&1
screen;
cd /tmp
t=1
echo -ne 1%           \\r
appinstall="g++ make gettext subversion python-all-dev python-all python-twisted python-twisted-web python-pyopenssl python-simplejson python-setuptools python-xdg python-chardet python-mako libssl-dev zlib1g-dev libboost-dev libasio-dev libboost-python-dev libboost-thread-dev libboost-date-time-dev libboost-filesystem-dev libboost-graph-dev libboost-iostreams-dev"
for item in ${appinstall[@]}; do
	echo -ne $t%           \\r
	if [ ! -e /var/lib/dpkg/info/"$item".list ]; then
		/usr/bin/apt-get -qq install  "$item"
		t=$(($t + 4))
	else
		t=$(($t + 4))
	fi
done
adduser --disabled-password --system --gecos "SamRo Deluge server" --group deluge > /dev/null 2>&1
echo
echo "    *****************You selected to install Deluge**********************";
echo
echo "Downloading and installing Deluge.......";
echo "This one takes some time, please wait...";
if [ ! -e /usr/bin/deluge ]; then
	wget http://download.deluge-torrent.org/source/deluge-1.3.6.tar.gz > /dev/null
	tar xvzf deluge-1.3.6.tar.gz > /dev/null 2>&1
	rm deluge-1.3.6.tar.gz > /dev/null 2>&1
	cd deluge-1.3.6 > /dev/null 2>&1
	screen;
	echo
	echo "    *****************You selected to install Deluge**********************";
	echo
	echo "Downloading and installing Deluge.......";
	echo "Most needed files have been downloaded, Compiling will start";
	echo "shortly. This will take some time, please wait...";
	#python setup.py clean -a > /dev/null 2>&1
	sed -i -e 's/libtorrent.svn.sourceforge.net\/svnroot\/libtorrent/svn.code.sf.net\/p\/libtorrent\/code/' /tmp/deluge-1.3.6/get_libtorrent.sh
	#sed -i -e 's/VERSION=14/VERSION=16/' /tmp/deluge-1.3.6/get_libtorrent.sh
	#https://svn.code.sf.net/p/libtorrent/code
	/tmp/deluge-1.3.6/get_libtorrent.sh
	sleep 2
	python setup.py build
	screen;
	echo
	echo "    *****************You selected to install Deluge**********************";
	echo
	echo "Downloading and installing Deluge.......";
	echo "Compiling has finished";
	echo "Finishing off the installation of Deluge...";
	sleep 2
	python setup.py install --install-layout=deb > /dev/null 2>&1
	ldconfig
	cd ..
	rm -Rf deluge-1.3.6 > /dev/null 2>&1
	wget http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz > /dev/null 2>&1
	gzip -d GeoIPv6.dat.gz > /dev/null 2>&1
	mkdir -p /usr/share/geoip > /dev/null 2>&1
	mv GeoIPv6.dat /usr/share/geoip/ > /dev/null 2>&1
	rm GeoIPv6.dat.gz > /dev/null 2>&1
fi
mkdir -p /var/log/deluge/web/ > /dev/null 2>&1
chown deluge:deluge -R /var/log/deluge > /dev/null 2>&1
echo "Setting up startup options"
echo '#!/bin/sh
### BEGIN INIT INFO
# Provides:          deluge-daemon
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Should-Start:      $network
# Should-Stop:       $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Daemonized version of deluge and webui.
# Description:       Starts the deluge daemon.
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DESC="Deluge Daemon"
NAME1="deluged"
NAME2="deluge"
DAEMON1=/usr/bin/deluged
DAEMON1_ARGS="-d -L warning -l /var/log/deluge/daemon/warning.log"             # Consult `man deluged` for more options
DAEMON2=/usr/bin/deluge-web
DAEMON2_ARGS="-L warning -l /var/log/deluge/web/warning.log"
# Consult `man deluge-web` for more options
PIDFILE1=/var/run/$NAME1.pid
PIDFILE2=/var/run/$NAME2.pid
UMASK=0                     # Change this to 0 if running deluged as its own user
PKGNAME=deluge-daemon
SCRIPTNAME=/etc/init.d/$PKGNAME
DELUGED_USER="deluge"
chown $DELUGED_USER:$DELUGED_USER -R /var/log/deluge
# Exit if the package is not installed
[ -x "$DAEMON1" -a -x "$DAEMON2" ] || exit 0

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
   # Return
   #   0 if daemon has been started
   #   1 if daemon was already running
   #   2 if daemon could not be started
   start-stop-daemon --start --background --quiet --pidfile $PIDFILE1 --exec $DAEMON1 \
      --chuid $DELUGED_USER --user $DELUGED_USER --umask $UMASK --test > /dev/null
   RETVAL1="$?"
   start-stop-daemon --start --background --quiet --pidfile $PIDFILE2 --exec $DAEMON2 \
      --chuid $DELUGED_USER --user $DELUGED_USER --umask $UMASK --test > /dev/null
   RETVAL2="$?"
   [ "$RETVAL1" = "0" -a "$RETVAL2" = "0" ] || return 1

   start-stop-daemon --start --background --quiet --pidfile $PIDFILE1 --make-pidfile --exec $DAEMON1 \
      --chuid $DELUGED_USER --user $DELUGED_USER --umask $UMASK -- $DAEMON1_ARGS
   RETVAL1="$?"
        sleep 2
   start-stop-daemon --start --background --quiet --pidfile $PIDFILE2 --make-pidfile --exec $DAEMON2 \
      --chuid $DELUGED_USER --user $DELUGED_USER --umask $UMASK -- $DAEMON2_ARGS
   RETVAL2="$?"
   [ "$RETVAL1" = "0" -a "$RETVAL2" = "0" ] || return 2
   sudo cat > /etc/logrotate.d/deluge << EOF
/var/log/deluge/*/*.log {
        weekly
        missingok
        rotate 7
        compress
        notifempty
        copytruncate
        create 600
}
EOF

}

#
# Function that stops the daemon/service
#
do_stop()
{
   # Return
   #   0 if daemon has been stopped
   #   1 if daemon was already stopped
   #   2 if daemon could not be stopped
   #   other if a failure occurred

   start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --user $DELUGED_USER --pidfile $PIDFILE2
   RETVAL2="$?"
   start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --user $DELUGED_USER --pidfile $PIDFILE1
   RETVAL1="$?"
   [ "$RETVAL1" = "2" -o "$RETVAL2" = "2" ] && return 2

   rm -f $PIDFILE1 $PIDFILE2

   [ "$RETVAL1" = "0" -a "$RETVAL2" = "0" ] && return 0 || return 1
}

case "$1" in
  start)
   [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME1"
   do_start
   case "$?" in
      0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
      2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
   esac
   ;;
  stop)
   [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME1"
   do_stop
   case "$?" in
      0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
      2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
   esac
   ;;
  restart|force-reload)
   log_daemon_msg "Restarting $DESC" "$NAME1"
   do_stop
   case "$?" in
     0|1)
      do_start
      case "$?" in
         0) log_end_msg 0 ;;
         1) log_end_msg 1 ;; # Old process is still running
         *) log_end_msg 1 ;; # Failed to start
      esac
      ;;
     *)
        # Failed to stop
      log_end_msg 1
      ;;
   esac
   ;;
  *)
   echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
   exit 3
   ;;
esac

exit 0' > /etc/init.d/deluge-daemon
chmod a+x  /etc/init.d/deluge-daemon > /dev/null 2>&1
update-rc.d deluge-daemon defaults > /dev/null 2>&1
/etc/init.d/deluge-daemon start > /dev/null 2>&1
service="Deluge"
address="http://$ip:8112"
port=":8112"
panel;
echo "";
echo "Finished";
/etc/init.d/deluge-daemon restart > /dev/null 2>&1
}

install_MAR()
{
service maraschino stop > /dev/null 2>&1
screen;
cd /tmp
echo
echo "    *****************You selected to install Maraschino*******************";
echo
echo "Downloading and installing Maraschino.......";
git clone https://github.com/mrkipling/maraschino.git new_MAR > /dev/null
ret=$?
if ! test "$ret" -eq 0; then
    echo >&2 "git clone Maraschino failed with exit status $ret"
    exit 1
fi
if [ -d $INSTALLDIR/maraschino ]; then
	cp -fRa /tmp/new_MAR/. $INSTALLDIR/maraschino
	rm -fR /tmp/new_MAR
else
	mv /tmp/new_MAR $INSTALLDIR/maraschino
fi
echo '#! /bin/sh

################################################
### BEGIN INIT INFO
# Provides:          Maraschino
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts instance of Maraschino
# Description:       starts instance of Maraschino using start-stop-daemon
### END INIT INFO


# main variables
DAEMON=/usr/bin/python

SETTINGS_LOADED=FALSE

DESC=Maraschino
NAME=maraschino
DAEMON_OPTS="Maraschino.py --port=9999"

PID_FILE=/var/run/maraschino.pid

RUN_AS='${mainuser}'
DAEMON='${py}'
APP_PATH='${INSTALLDIR}'/maraschino
SETTINGS_LOADED=TRUE

. /lib/lsb/init-functions

[ -x $DAEMON ] || {
    log_warning_msg "$DESC: Cant execute daemon, aborting. See $DAEMON";
    return 1; }

check_retval() {
    if [ $? -eq 0 ]; then
        log_end_msg 0
        return 0
    else
        log_end_msg 1
        exit 1
    fi
}

is_running () {
    # returns 1 when running, else 0.
    PID=$(pgrep -f "$DAEMON_OPTS")
    RET=$?
    [ $RET -gt 1 ] && exit 1 || return $RET
}

handle_pid () {
    PID_PATH=`dirname $PID_FILE`
    [ -d $PID_PATH ] || mkdir -p $PID_PATH && chown -R $RUN_AS $PID_PATH > /dev/null 2>&1 || {
        log_warning_msg "$DESC: Could not create $PID_FILE, aborting.";
        return 1;}
}

enable_updates () {
    chown -R $RUN_AS $APP_PATH > /dev/null 2>&1 || {
        log_warning_msg "$DESC: $APP_PATH not writable for web-updates, See $SETTINGS";
        return 0; }
}

start_maraschino () {
    if ! is_running; then
        log_daemon_msg "Starting $DESC"
        [ "$WEB_UPDATE" = 1 ] && enable_updates
        handle_pid
        start-stop-daemon -o -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE  --make-pidfile --exec $DAEMON -- $DAEMON_OPTS
        check_retval
    else
        log_success_msg "$DESC: already running (pid $PID)"
    fi
}

stop_maraschino () {
    if is_running; then
        log_daemon_msg "Stopping $DESC"
        start-stop-daemon -o --stop --pidfile $PID_FILE --retry 15
        check_retval
    else
        log_success_msg "$DESC: not running"
    fi
}


case "$1" in
    start)
        start_maraschino
        ;;
    stop)
        stop_maraschino
        ;;
    restart|force-reload)
        stop_maraschino
        start_maraschino
        ;;
    *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0' > /etc/init.d/maraschino

chmod a+x /etc/init.d/maraschino > /dev/null 2>&1
update-rc.d maraschino defaults > /dev/null 2>&1
/etc/init.d/maraschino start > /dev/null 2>&1
service="Maraschino"
address="http://$ip:9999"
port=":9999"
panel;
echo "";
echo "Finished";
sleep 1

}

install_NZBF()
{
cd /tmp
echo
echo "    ********************You selected to install nZEDb********************";
echo
echo
echo "This one takes some time, please wait...";
if [ -d /var/www/nZEDb ]; then
	echo "nZEDb is installed already so we will just make sure it is uptodate";
	echo "Starting update..."
    cd /var/www/nZEDb
	git stash
	git pull
    php /var/www/nZEDb/misc/testing/DB_scripts/patchmysql.php
	rm /var/www/nZEDb/www/lib/smarty/templates_c/*.php > /dev/null
	NEWZNABPORT=$(awk '/Listen/ { print $NF }' /etc/apache2/sites-available/nZEDb)
	echo "Done..."
	sleep 4
else
	screen;
	cd /tmp
	echo
	echo "    ********************You selected to install nZEDb********************";
	echo
	echo
	echo "please wait...";
	NEWZNABPT;
	cd /var/www
	git clone https://github.com/nZEDb/nZEDb.git /var/www/nZEDb
	ret=$?
	if ! test "$ret" -eq 0; then
		echo >&2 "git clone nZEDb failed with exit status $ret"
		exit 1
	fi
	chmod -R 775 /var/www/nZEDb/www/lib/smarty/templates_c
	chmod -R 775 /var/www/nZEDb/www/covers
	chmod -R 775 /var/www/nZEDb/nzbfiles
	chmod 775 /var/www/nZEDb/www
	chmod 775 /var/www/nZEDb/www/install
	chown -R openmediavault:openmediavault /var/www
	easy_install cymysql > /dev/null 2>&1
	setup_NEWZNAB;
	screen;
	cd /tmp
	echo
	echo "    ********************You selected to install nZEDb********************";
	echo
	echo "        nZEDb needs to know what auto start settings you wish to use";
	echo "        This script will use the Sequential runtime script unless you";
	echo "     choose to use the Threaded scripts, these are for multi core systems.";
	echo "                     Change and use the Threaded scripts?";
	if QUESTION;then
		if ! grep -q "screen -dmS nZEDb \/var\/www\/nZEDb\/misc\/update_scripts\/nix_scripts\/screen\/threaded\/start.sh" /etc/rc.local; then
			sed -i '0,/^[ \t]*exit[ \t]\+0/s//screen -dmS nZEDb \/var\/www\/nZEDb\/misc\/update_scripts\/nix_scripts\/screen\/threaded\/start.sh\n&/' /etc/rc.local
		fi
	else
		if ! grep -q "screen -dmS nZEDb \/var\/www\/nZEDb\/misc\/update_scripts\/nix_scripts\/screen\/sequential\/simple.sh" /etc/rc.local; then
			sed -i '0,/^[ \t]*exit[ \t]\+0/s//screen -dmS nZEDb \/var\/www\/nZEDb\/misc\/update_scripts\/nix_scripts\/screen\/sequential\/simple.sh\n&/' /etc/rc.local
		fi
	fi

fi
setup_EXTRAS;
}

install_NZBP()
{
NEWZNABPT;
screen;
cd /tmp
echo
echo "    *************You selected to install Newznab Paid Edition************";
echo
echo "          To use this version you must have donated to the project       ";
echo "     You should have revived a username and password for the SVN download";
echo "                        Enter the password when asked                    ";
#echo "Username:";
#read svnu
#echo "Password:";
#read svnp

svn co svn://svn.newznab.com/nn/branches/nnplus /var/www/newznab --username=svnplus

chown -R openmediavault:openmediavault /var/www/newznab/www
setup_NEWZNAB;
if ! grep -q "screen -dmS newznab \/var\/www\/newznab\/misc\/update_scripts\/nix_scripts\/newznab_screen.sh" /etc/rc.local; then
	sed -i '0,/^[ \t]*exit[ \t]\+0/s//screen -dmS newznab \/var\/www\/newznab\/misc\/update_scripts\/nix_scripts\/newznab_screen.sh\n&/' /etc/rc.local
fi
#sed -i "s#/usr/local/www/newznab/misc/update_scripts#${NEWZNABDIR}/newznab/misc/update_scripts#g" \/var\/www\/newznab\/misc\/update_scripts\/nix_scripts\/newznab_screen.sh


#Sphinx
#cd /tmp
#wget http://sphinxsearch.com/files/sphinx-2.1.1-beta.tar.gz > /dev/null 2>&1
#tar xvfz sphinx-2.1.1-beta.tar.gz > /dev/null 2>&1
#cd sphinx-2.1.1-beta
#wget http://snowball.tartarus.org/dist/libstemmer_c.tgz > /dev/null 2>&1
#tar --strip-components=1 -zxf libstemmer_c.tgz -C libstemmer_c
#./configure --prefix=/usr/local --with-libstemmer > /dev/null 2>&1
#make -j4
#checkinstall --pkgname=sphinx --pkgversion="2.1.1-beta" --backup=no --deldoc=yes --fstrans=no --default
#> /dev/null
#sudo checkinstall --pkgname=sphinx --pkgversion="2.0.2-beta" --backup=no \
#--deldoc=yes --fstrans=no --default > /dev/null 2>&1
#cd .. > /dev/null 2>&1
#screen;
#cd /tmp
#echo "     **IMPORTANT****IMPORTANT****IMPORTANT****IMPORTANT****IMPORTANT**";
#echo "    ***********Please complete the Newznab site wizard****************";
#echo "    ***************then return here and press ENTER*******************";
#echo
#read jwait

#rm sphinx-2.0.6-release.tar.gz > /dev/null 2>&1
#rm sphinx-2.1.1-beta.tar.gz > /dev/null 2>&1
#rm -R sphinx-2.0.6-release > /dev/null 2>&1
#rm -R sphinx-2.1.1-beta > /dev/null 2>&1

chmod -R 777 /var/www/newznab

#Get Sphinx Ready
#killall -9 indexer > /dev/null 2>&1
#killall -9 searchd > /dev/null 2>&1
#sleep 5
#rm -R /var/www/newznab/db/sphinxdata/binlog/ > /dev/null 2>&1
#mkdir -p /var/www/newznab/db/sphinxdata/binlog/ > /dev/null 2>&1
#chmod -R 777 /var/www/newznab/db/sphinxdata/binlog/ > /dev/null 2>&1

#php5 /var/www/newznab/misc/sphinx/nnindexer.php generate
#php5 /var/www/newznab/misc/sphinx/nnindexer.php daemon
#php5 /var/www/newznab/misc/sphinx/nnindexer.php index full all
#php5 /var/www/newznab/misc/sphinx/nnindexer.php index delta all
#php5 /var/www/newznab/misc/sphinx/nnindexer.php daemon --stop
#rm -R /var/www/newznab/db/sphinxdata/binlog/
#mkdir -p /var/www/newznab/db/sphinxdata/binlog/
#chmod -R 777 /var/www/newznab/db/sphinxdata/binlog
#php5 /var/www/newznab/misc/sphinx/nnindexer.php daemon
#php5 /media/ae17113f-d82f-4c67-9e59-5ea9fcb05f63/myapps/newznab/misc/sphinx/nnindexer.php generate
#php5 /media/ae17113f-d82f-4c67-9e59-5ea9fcb05f63/myapps/newznab/misc/sphinx/nnindexer.php daemon
#php5 /media/ae17113f-d82f-4c67-9e59-5ea9fcb05f63/myapps/newznab/misc/sphinx/nnindexer.php index full all
#php5 /media/ae17113f-d82f-4c67-9e59-5ea9fcb05f63/myapps/newznab/misc/sphinx/nnindexer.php index delta all
#php5 /media/ae17113f-d82f-4c67-9e59-5ea9fcb05f63/myapps/newznab/misc/sphinx/nnindexer.php daemon --stop
#php5 /media/ae17113f-d82f-4c67-9e59-5ea9fcb05f63/myapps/newznab/misc/sphinx/nnindexer.php daemon
#ps -ewwo pid,args | grep [s]e
setup_EXTRAS;
}

install_MC()
{
/etc/init.d/subsonic stop > /dev/null 2>&1
screen;
cd /tmp
echo
echo "    **************You selected to install MusicCabinet*******************";
echo
echo "Downloading and installing MusicCabinet...";
echo "This one takes some time, please wait...";
if [ -e /etc/apt/sources.list.d/openmediavault-millers.list ]; then
	line=$(grep "deb http://apt.postgresql.org/pub/repos/apt/ squeeze-pgdg main" /etc/apt/sources.list.d/openmediavault-millers.list)
		if [ $? == 1 ]; then
			echo "deb http://apt.postgresql.org/pub/repos/apt/ squeeze-pgdg main" >> /etc/apt/sources.list.d/openmediavault-millers.list
		fi
else
	echo "deb http://apt.postgresql.org/pub/repos/apt/ squeeze-pgdg main" > /etc/apt/sources.list.d/openmediavault-millers.list
fi
if [ ! -e /var/subsonic ]; then
	echo "SubSonic is not installed";
	sleep 5
	mc="2"
else
	wget http://dilerium.se/musiccabinet/subsonic-installer-standalone.zip
	unzip subsonic-installer-standalone.zip > /dev/null 2>&1
	rm /usr/share/subsonic/*
	cp -f subsonic-installer-standalone/subsonic.sh /usr/share/subsonic
	cp -f subsonic-installer-standalone/subsonic-booter-jar-with-dependencies.jar /usr/share/subsonic
	cp -f subsonic-installer-standalone/subsonic.war /usr/share/subsonic
	chmod 777 -R /usr/share/subsonic
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
		sudo apt-key add -
	/usr/bin/apt-get --quiet --quiet update
	#apt-get install postgresql-9.2 #
	/usr/bin/apt-get install -qq -t squeeze-pgdg postgresql-contrib-9.3
	sudo -u postgres psql -c"ALTER user postgres WITH PASSWORD '1234'"
	sudo service postgresql restart > /dev/null 2>&1
	echo 'MusicCabinetJDBCPassword=31323334' > /var/subsonic/subsonic.properties
	if [ -e /var/subsonic/db ]; then
		rm -R /var/subsonic/db
	fi
	service subsonic start
	service="MusicCabinet"
	address="http://$ip:4040"
	port=":4040"
	panel;
	rm -fR /var/www/openmediavault/images/SubSonic.png > /dev/null 2>&1
	rm -fR /var/www/openmediavault/js/omv/module/SubSonic.js > /dev/null 2>&1
	rm /tmp/subsonic-installer-standalone.zip > /dev/null 2>&1
	rm -R /tmp/subsonic-installer-standalone > /dev/null 2>&1
fi
}

setup_EXTRAS()
{
screen;
echo "";
echo "    **************************Usenet Extras******************************";
echo "";
echo "    To get the most out of your usenet indexer is is suggested to install";
echo "    additional programs that will allow extra functions to work on your  ";
echo "    site. These programs are :-                                          ";
echo "";
echo "";
echo "           1. MediaInfo - used to get infomation from video files.       ";
echo "           2. Ffmpeg - used to get screen shots.                         ";
echo "           3. Lame - used to get previews for user to listen to          ";
echo "";
echo "";
echo "    These programs need to be compiled from scratch in order to work,    ";
echo "    this means it will take some time to complete so before you answer   ";
echo "    yes, just know it could take over 10 minutes to finish               ";
echo "                SO YOU WANT TO INSTALL THESE PROGRAMS?                   ";
if QUESTION; then
	echo "";
	cd /tmp
	RUNNING=`expr "$(uname -m)"`
	if [ "$RUNNING" == "x86_64" ]; then
		cd /tmp > /dev/null 2>&1
		wget http://ftp.us.debian.org/debian/pool/main/e/eglibc/multiarch-support_2.17-96_amd64.deb > /dev/null 2>&1
		dpkg -i multiarch-support_2.17-96_amd64.deb > /dev/null 2>&1
		rm multiarch-support_2.17-96_amd64.deb > /dev/null 2>&1
	elif [ "$RUNNING" == "i686" ]; then
		cd /tmp > /dev/null 2>&1
		wget http://ftp.us.debian.org/debian/pool/main/e/eglibc/multiarch-support_2.17-96_i386.deb > /dev/null 2>&1
		dpkg -i multiarch-support_2.17-96_i386.deb > /dev/null 2>&1
		rm multiarch-support_2.17-96_i386.deb > /dev/null 2>&1
	fi
	t=0
	echo -ne $t%           \\r
	appinstall="ffmpeg x264 libav-tools libvpx-dev libx264-dev yasm"
	for item in ${appinstall[@]}; do
		echo -ne $t%           \\r
		/usr/bin/apt-get -qq remove "$item" > /dev/null 2>&1
		t=$(($t + 3))
	done
	appinstall="nasm gettext automake autoconf build-essential checkinstall git libfaac-dev libass-dev libgpac-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev librtmp-dev libsdl1.2-dev libtheora-dev libtool libvorbis-dev pkg-config texi2html yasm zlib1g-dev libjack-jackd2-dev libva-dev libvdpau-dev libx11-dev libxfixes-dev libdirac-dev libxvidcore-dev mediainfo libgpac2 libjpeg8 libssl-dev"
	for item in ${appinstall[@]}; do
		echo -ne $t%           \\r
			if [ ! -f /var/lib/dpkg/info/"$item".list ]; then
				/usr/bin/apt-get -qq install  "$item" > /dev/null 2>&1
				t=$(($t + 3))
			else
				t=$(($t + 3))
			fi
	done
	#YASM
	cd /tmp
	wget http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz
	tar xzvf yasm-1.2.0.tar.gz
	cd yasm-1.2.0
	./configure
	make
	checkinstall --pkgname=yasm --pkgversion="1.2.0" --backup=no --deldoc=yes --fstrans=no --default
	#X264
	cd /tmp
	wget ftp://ftp.videolan.org/pub/videolan/x264/snapshots/last_stable_x264.tar.bz2
	mkdir /tmp/x264
	tar --strip-components=1 -jxf last_stable_x264.tar.bz2 -C x264
	cd /tmp/x264
	./configure --enable-static
	make
	sudo checkinstall --pkgname=x264 --pkgversion="test1a" --backup=no --deldoc=yes --fstrans=no --default
	#LAME
	cd /tmp
	wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
	tar xzvf lame-3.99.5.tar.gz
	cd /tmp/lame-3.99.5
	./configure --enable-nasm --disable-shared
	make
	sudo checkinstall --pkgname=lame-ffmpeg --pkgversion="3.99.5" --backup=no --default --deldoc=yes
	#fsk-acc
	cd /tmp
	git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git
	cd /tmp/fdk-aac
	autoreconf -fiv
	./configure --disable-shared
	make
	checkinstall --pkgname=fdk-aac --pkgversion="$(date +%Y%m%d%H%M)-git" --backup=no --deldoc=yes --fstrans=no --default
	cd /tmp
	#libvpx
	git clone --depth 1 http://git.chromium.org/webm/libvpx.git
	cd /tmp/libvpx
	./configure --disable-examples --disable-unit-tests
	make
	checkinstall --pkgname=libvpx --pkgversion="1:$(date +%Y%m%d%H%M)-git" --backup=no --deldoc=yes --fstrans=no --default
	cd /tmp
	#Opus
	git clone --depth 1 git://git.xiph.org/opus.git
	cd /tmp/opus
	./autogen.sh
	./configure --disable-shared
	make
	checkinstall --pkgname=libopus --pkgversion="$(date +%Y%m%d%H%M)-git" --backup=no --deldoc=yes --fstrans=no --default
	cd /tmp
	#FFmpeg
	git clone --depth 1 git://source.ffmpeg.org/ffmpeg
	cd /tmp/ffmpeg
	./configure --enable-gpl --enable-libass --enable-libopus --enable-libfaac --enable-libfdk-aac --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-librtmp --enable-libtheora --enable-libvorbis --enable-libvpx --enable-x11grab --enable-libx264 --enable-nonfree --enable-version3 --enable-libxvid --enable-postproc --extra-ldflags=-ldl
	make
	checkinstall --pkgname=ffmpeg --pkgversion="7:$(date +%Y%m%d%H%M)-git" --backup=no --deldoc=yes --fstrans=no --default
	hash x264 ffmpeg ffplay ffprobe
	screen;
	echo "";
	echo "    **************************Usenet Extras******************************";
	echo "";
	echo "                         Compiling has finished";
	echo "";
	echo "    On your site you will need to tell it where this programs can be found";
	echo "    Take note of the following and enter in the admin section of your site";
	echo "";
	echo "           3rd Party Application Paths";
	echo "";
	echo "           Unrar Path = /usr/bin/unrar";
	echo "           Mediainfo Path = /usr/bin/mediainfo";
	echo "           Ffmpeg Path = /usr/local/bin/ffmpeg";
	echo "           Lame Path = /usr/local/bin/lame";
	echo "";
	echo "           Take note off these paths and press any key to continue";
	echo "";
	read -n 1 wait
fi
}

setup_NEWZNAB()
{
mypass="1234"
if [ -e /var/lib/dpkg/info/openmediavault-mysql.list ]; then
	getmysql;
fi
screen;
echo
echo "  ********************Continuing to install ${INSTALLING}********************";
echo
#export DEBIAN_FRONTEND=noninteractive
t=0
echo -ne $t%           \\r
/usr/bin/apt-get --quiet --quiet update
/usr/bin/apt-get --quiet --quiet upgrade


echo mysql-server mysql-server/root_password password $mypass | sudo debconf-set-selections
echo mysql-server mysql-server/root_password_again password $mypass | sudo debconf-set-selections
if [ $OMV_V -gt 4 ]; then
	appinstall="php-apc php5-cli php5-curl php5-gmp php5-gd php5-mcrypt php5-sqlite php-pear axel bwm-ng curl dnsutils ethtool htop iotop iperf mtr-tiny ntp psmisc rsnapshot rsync screen unrar unzip zip make g++ checkinstall libmysqlclient-dev python-mysqldb mysql-server mysql-client libmysqlclient-dev python-pip python-setuptools php5-fpm php5-svn php5-mysql"
else
	appinstall="openmediavault-mysql php-apc php5-cli php5-curl php5-gmp php5-gd php5-mcrypt php5-sqlite php-pear axel bwm-ng curl dnsutils ethtool htop iotop iperf mtr-tiny ntp psmisc rsnapshot rsync screen unrar unzip zip make g++ checkinstall libmysqlclient-dev python-mysqldb mysql-server mysql-client libmysqlclient-dev python-pip python-setuptools php5-fpm php5-svn php5-mysql"
fi
for item in ${appinstall[@]}; do
	echo -ne $t%           \\r
		if [ ! -f /var/lib/dpkg/info/"$item".list ]; then
			/usr/bin/apt-get -qq install  "$item"
			t=$(($t + 2))
		else
			t=$(($t + 2))
		fi
done
screen;
echo "    *************************Packages installed**************************";
echo "    *************Installing ${INSTALLING} & compiling dependencies*************";

/usr/bin/apt-get --quiet --quiet update
/usr/bin/apt-get --quiet --quiet upgrade
if [ "$nzbf" == "1" ]; then
	echo 'NameVirtualHost *:'${NEWZNABPORT}'
Listen '${NEWZNABPORT}'
<VirtualHost *:'${NEWZNABPORT}'>
LoadModule rewrite_module /usr/lib/apache2/modules/mod_rewrite.so
RewriteEngine on
#RewriteBase /

# Do not process images or CSS files further
RewriteRule \.(css|jpe?g|gif|png|js|ico|mp3)$ - [L]

# Leave /admin and /install static
RewriteRule ^(admin|install).*$ - [L]

# Rewrite web pages to one master page
RewriteRule ^([^/\.]+)/?$ index.php?page=$1 [QSA,L]
RewriteRule ^([^/\.]+)/([^/]+)/?$ index.php?page=$1&id=$2 [QSA,L]
RewriteRule ^([^/\.]+)/([^/]+)/([^/]+)/? index.php?page=$1&id=$2&subpage=$3 [QSA,L]
Alias /nZEDb/ /var/www/nZEDb/www/
ServerName nZEDb
DocumentRoot /var/www/nZEDb/www
DirectoryIndex index.php
SuexecUserGroup openmediavault openmediavault
#Alias /extjs/ /usr/share/javascript/extjs3/
#Alias /images/ /var/www/openmediavault/images/
# Set maximum HTTP request length to 25 MiB
FcgidMaxRequestLen 26214400
FcgidIOTimeout 300
<Directory /var/www/nZEDb/www/>
    Options FollowSymLinks
    <FilesMatch \.php$>
        FcgidWrapper /var/www/openmediavault/php-fcgi .php
        SetHandler fcgid-script
        Options +ExecCGI
    </FilesMatch>
    Order Allow,Deny
    Allow from All
    AllowOverride All
</Directory>
LogLevel warn
ErrorLog /openmediavault-webgui_error.log
CustomLog /openmediavault-webgui_access.log combined
</VirtualHost>' > /etc/apache2/sites-available/nZEDb
	#ln -s /etc/apache2/sites-available/nZEDb /etc/apache2/sites-enabled/nZEDb

	chmod 777 -R /var/www/nZEDb
	mysql -u root -p1234 -e "CREATE DATABASE nzedb CHARACTER SET utf8 COLLATE utf8_bin;
CREATE USER 'nzedb'@'%' IDENTIFIED BY PASSWORD '*1866926EB89CFCFA28CCB6D28A8834777C277E57';
GRANT ALL ON nzedb.* TO 'nzedb'@'%';
GRANT CREATE ON nzedb.* TO 'nzedb'@'%';
FLUSH PRIVILEGES;"
elif [ "$nzbp" == "1" ]; then
	echo 'NameVirtualHost *:'${NEWZNABPORT}'
Listen '${NEWZNABPORT}'
<VirtualHost *:'${NEWZNABPORT}'>
LoadModule rewrite_module /usr/lib/apache2/modules/mod_rewrite.so
RewriteEngine on
#RewriteBase /

# Do not process images or CSS files further
RewriteRule \.(css|jpe?g|gif|png|js|ico|mp3)$ - [L]

# Leave /admin and /install static
RewriteRule ^(admin|install).*$ - [L]

# Rewrite web pages to one master page
RewriteRule ^([^/\.]+)/?$ index.php?page=$1 [QSA,L]
RewriteRule ^([^/\.]+)/([^/]+)/?$ index.php?page=$1&id=$2 [QSA,L]
RewriteRule ^([^/\.]+)/([^/]+)/([^/]+)/? index.php?page=$1&id=$2&subpage=$3 [QSA,L]
Alias /newznab/ /var/www/newznab/www/
ServerName newznab
DocumentRoot /var/www/newznab/www
DirectoryIndex index.php
SuexecUserGroup openmediavault openmediavault
#Alias /extjs/ /usr/share/javascript/extjs3/
#Alias /images/ /var/www/openmediavault/images/
# Set maximum HTTP request length to 25 MiB
FcgidMaxRequestLen 26214400
FcgidIOTimeout 300
<Directory /var/www/newznab/www/>
    Options FollowSymLinks
    <FilesMatch \.php$>
        FcgidWrapper /var/www/openmediavault/php-fcgi .php
        SetHandler fcgid-script
        Options +ExecCGI
    </FilesMatch>
    Order Allow,Deny
    Allow from All
    AllowOverride All
</Directory>
LogLevel warn
ErrorLog /openmediavault-webgui_error.log
CustomLog /openmediavault-webgui_access.log combined
</VirtualHost>' > /etc/apache2/sites-available/newznab
#ln -s /etc/apache2/sites-available/newznab /etc/apache2/sites-enabled/newznab
a2ensite newznab > /dev/null 2>&1
chmod 777 -R /var/www/newznab
mysql -u root -p1234 -e "CREATE DATABASE newznab CHARACTER SET utf8 COLLATE utf8_bin;
CREATE USER 'newznab'@'%' IDENTIFIED BY PASSWORD '*38127B8B90DF33A49508ED3908A7EEEF871E18A3';
GRANT ALL ON newznab.* TO 'newznab'@'%';
GRANT CREATE ON newznab.* TO 'newznab'@'%';
FLUSH PRIVILEGES;"
fi



echo "[client]
port = 3306
socket = /var/run/mysqld/mysqld.sock

[mysqld]
bind-address = 127.0.0.1
port = 3306
socket = /var/run/mysqld/mysqld.sock
user = mysql
basedir = /usr
datadir = /var/lib/mysql
language = /usr/share/mysql/english
pid-file = /var/run/mysqld/mysqld.pid
skip-external-locking
tmpdir = /tmp
default-storage-engine = myisam
innodb = off
key_buffer_size = 8M
max_allowed_packet = 1M
max_connections = 20
max_heap_table_size = 4M
net_buffer_length = 2K
query_cache_limit = 256K
query_cache_size = 4M
read_buffer_size = 256K
read_rnd_buffer_size = 256K
sort_buffer_size = 64K
table_open_cache = 256
thread_stack = 128K

[mysqldump]
quick
max_allowed_packet = 16M

[myisamchk]
key_buffer_size = 8M
sort_buffer_size = 8M

!includedir /etc/mysql/conf.d/" > /etc/mysql/my.cnf

# Set php.ini
TZ=$(echo "$(omv_config_get "//system/time/timezone")" | sed 's.\/.\\\/.g')
if [ -f /var/www/openmediavault/cgi/php.ini ]; then
	sed -i -e 's/.*ate.timezone = .*$/date.timezone = '$TZ'/' /var/www/openmediavault/cgi/php.ini
	sed -i -e 's/.*emory_limit = .*$/memory_limit = -1/' /var/www/openmediavault/cgi/php.ini
	sed -i -e 's/.*ax_execution_time = .*$/max_execution_time = 120/' /var/www/openmediavault/cgi/php.ini
fi

if [ -f /etc/php5/fpm/php.ini ]; then
	sed -i -e 's/.*ate.timezone = .*$/date.timezone = '$TZ'/' /etc/php5/fpm/php.ini
	sed -i -e 's/.*emory_limit = .*$/memory_limit = -1/' /etc/php5/fpm/php.ini
	sed -i -e 's/.*ax_execution_time = .*$/max_execution_time = 120/' /etc/php5/fpm/php.ini
fi

if [ -f /etc/php5/cli/php.ini ]; then
	sed -i -e 's/.*ate.timezone = .*$/date.timezone = '$TZ'/' /etc/php5/cli/php.ini
	sed -i -e 's/.*emory_limit = .*$/memory_limit = -1/' /etc/php5/cli/php.ini
	sed -i -e 's/.*ax_execution_time = .*$/max_execution_time = 120/' /etc/php5/cli/php.ini
fi

if [ -f /etc/php5/cgi/php.ini ]; then
	sed -i -e 's/.*ate.timezone = .*$/date.timezone = '$TZ'/' /etc/php5/cgi/php.ini
	sed -i -e 's/.*emory_limit = .*$/memory_limit = -1/' /etc/php5/cgi/php.ini
	sed -i -e 's/.*ax_execution_time = .*$/max_execution_time = 120/' /etc/php5/cgi/php.ini
fi

echo "Change Apache Security"

a2ensite nZEDb > /dev/null 2>&1
a2dissite default > /dev/null 2>&1
a2enmod rewrite > /dev/null 2>&1
service apache2 restart > /dev/null 2>&1
}

panel()
{
link="";
screen;
echo "";
echo "You have installed $service, You can now add a link";
echo "to the side menu in OMV.";
echo "";
if QUESTION; then
	if [ $OMV_V -gt 4 ]; then
		mkdir -p /var/www/openmediavault/js/omv/module/admin/service/${service}
		echo '/**
 * This file was made via jhmillers script. Thanks to mitchtay
 */
Ext.define("OMV.module.admin.service.'${service}'", {
        extend: "Ext.panel.Panel",

        initComponent: function() {
                var me = this;
                var link = window.location.origin + "'${port}'";

                me.html = "<form style='\''overflow: auto; height: 100%;'\''>";
                me.html += "  <iframe src='\''" + link + "'\'' name='\''webclient'\'' longsec='\'''${service}' Web Client'\'' width='\''100%'\'' height='\''100%'\''/>";
                me.html += "<br/></form>";

                me.callParent(arguments);
        }

});
OMV.WorkspaceManager.registerNode({
        id: "'${service}'",
        path: "/service",
        text: _("'${service}'"),
        icon16: "images/'${service}'.png",
        className: "OMV.module.admin.service.'${service}'"
});
' > /var/www/openmediavault/js/omv/module/admin/service/$service/$service.js
			if ! [ -e /var/www/openmediavault/images/$service.png ]; then
				cd /var/www/openmediavault/images
				wget https://raw.github.com/cptjhmiller/OMV_Installers/master/images/$service.png --no-check-certificate > /dev/null 2>&1
				cd /tmp
			fi
	elif [ $OMV_V -lt 5 ]; then
		echo		'/**
 * This file was made via jhmillers script. Thanks to mitchtay
 */
Ext.ns("OMV.Module.Services");
OMV.NavigationPanelMgr.registerMenu("services", "'${service}'", {
        text: _("'${service}'"),
        icon: "images/'${service}'.png",
        position: 10
});
OMV.Module.Services.'${service}' = function(config) {
        var link = window.location.origin + "'${port}'";

        this.html = "<form style='\''overflow: auto; height: 100%;'\''>";
        this.html += "  <iframe src='\''" + link + "'\'' name='\''webclient'\'' longsec='\'''${service}' Web Client'\'' width='\''100%'\'' height='\''100%'\''/>";
        this.html += "<br/></form>";
};
OMV.NavigationPanelMgr.registerPanel("services", "'${service}'", {
        cls: OMV.Module.Services.'${service}'
});' > /var/www/openmediavault/js/omv/module/$service.js
		if ! [ -e /var/www/openmediavault/images/$service.png ]; then
			cd /var/www/openmediavault/images
			wget https://raw.github.com/cptjhmiller/OMV_Installers/master/images/$service.png --no-check-certificate > /dev/null 2>&1
			cd /tmp
		fi
	fi
else
	rm /var/www/openmediavault/images/$service.png > /dev/null 2>&1
	rm /var/www/openmediavault/js/omv/module/$service.js > /dev/null 2>&1
	rm -Rf /var/www/openmediavault/js/omv/module/admin/service/$service	
	link="0"
fi
}

finish()
{
screen;
check="0"
#ip=`ifconfig | grep "inet addr:" | head -n 1  | cut -d':' -f2 | cut -d' ' -f1`;
echo "";
echo "All your selected applications have been installed and are now running.";
echo "";
echo "Access your new services via the following addresses:";
echo "";

if [ "$ml" == "1" ]; then
	check="1"
	echo "";
	echo "    	MyLar 	      ---     http://$ip:8090";
fi

if [ "$hpm" == "1" -o "$hpd" == "1" ]; then
	check="1"
	echo "    	Headphones    ---     http://$ip:8181";
fi

if [ "$sbm" == "1" -o "$sbd" == "1" -o "$sbt" == "1" ]; then
	check="1"
	echo "    	SickBeard     ---     http://$ip:8081"
fi

if [ "$sub" == "1" -a "$mc" != "1" ]; then
	check="1"
	echo "    	SubSonic      ---     http://$ip:4040";
fi

if [ "$mc" != "2" ]; then
	if [ "$mc" == "1" ]; then
		check="1"
		echo "    	MusicCabinet  ---     http://$ip:4040";
	fi
else
	echo "    	MusicCabinet  ---     NOT INSTALLED";
	echo "    	     INSTALL SUBSONIC FIRST";
fi

if [ "$cpv" == "1" ]; then
	check="1"
	echo "    	CouchPotato   ---     http://$ip:5000";
fi

if [ "$cpm" == "1" -o "$cpd" == "1" ]; then
	check="1"
	echo "    	CouchPotatov2 ---     http://$ip:5050";
fi

if [ "$sab" == "1" ]; then
	check="1"
	echo "    	SABnzbd       ---     http://$ip:8080";
fi

if [ "$llm" == "1" ]; then
	check="1"
	echo "    	LazyLibrarian ---     http://$ip:8082";
fi

if [ "$pyl" == "1" ]; then
	check="1"
	echo "    	PyLoad        ---     http://$ip:8888";
fi

if [ "$nzbf" == "1" ]; then
	check="1"
	echo "    	Newznab        ---     http://$ip:${NEWZNABPORT}";
fi

if [ "$nzbp" == "1" ]; then
	check="1"
	echo "    	Newznab+      ---     http://$ip:${NEWZNABPORT}";
fi

if [ "$mar" == "1" ]; then
	check="1"
	echo "    	Maraschino     ---     http://$ip:9999";
fi

if [ "$del" == "1" ]; then
	check="1"
	echo "    	Deluge         ---     http://$ip:8112";
fi

if [ "$asub" == "1" ]; then
	check="1"
	echo "    	Auto-Sub       ---     http://$ip:8083";
fi

if [ "$exp" == "1" ]; then
	check="1"
	echo "    	Extplorer     ---     http://$ip/extplorer";
fi

if [ "$gz" == "1" ]; then
	check="1"
	echo "    	GameZ         ---     http://$ip:8085";
fi

if [ "$bbs" == "1" ]; then
	check="1"
	echo "    	BicBucStriim  ---     http://$ip/bbs";
fi

if [ "$xdm" == "1" ]; then
	check="1"
	echo "    	XDM           ---     http://$ip:8085";
fi

if [ "$htpc" == "1" ]; then
	check="1"
	echo "    	HTPC Manager  ---     http://$ip:8089";
fi
if [ "$check" == "1" ]; then
	sleep 5
	exit 0
else
	menu;
fi
}

warnRoot()
{
screen;
currentuser=`whoami`;
if [ "$currentuser" != "root" ]; then
	echo
	echo "  This installation script should be run as"
	echo "  user \"root\".  You are currenly running ";
	echo "  as $currentuser.  "
	echo
	echo -n "  Do you wish to continue? [N] "

	read ignoreroot;
	if [ "$ignoreroot" = "" ]; 	then
		ignoreroot="N";
	else
		case "$ignoreroot" in
			Y | yes | y | Yes | YES )
				ignoreroot="Y";
				;;
			[nN]*)
				ignoreroot="N";
				;;
			*)
				ignoreroot="N";
				;;
		esac
	fi

	if [ "$ignoreroot" = "N" ];	then
		echo " Exiting...";
		echo
		exit 1;
	fi

fi
}

install_XDM()
{
screen;
cd /tmp
if [ -f /etc/init.d/xdm ]; then
	service xdm stop > /dev/null 2>&1
	rm /etc/init.d/xdm
	update-rc.d -f xdm remove
fi
echo
echo "    *********************You selected to install XDM**********************";
echo
echo "                    In order to run, this app needs python2.7";
echo "Install python2.7? (it will take some time)"
if QUESTION; then
	install_PYTHON
	cd /tmp
	echo "Downloading and installing XDM...";
	git clone git://github.com/lad1337/XDM.git new_xdm > /dev/null
	ret=$?
	if ! test "$ret" -eq 0; then
		echo >&2 "git clone xdm Version 1 failed with exit status $ret"
		exit 1
	fi
	if [ -d $INSTALLDIR/XDM ]; then
		cp -fRa /tmp/new_xdm/. $INSTALLDIR/XDM
		rm -fR /tmp/new_xdm
	else
		mv /tmp/new_xdm $INSTALLDIR/XDM
	fi
	echo "Setting up startup options"
	echo '#! /bin/sh
### BEGIN INIT INFO
# Provides:          xdm
# Required-Start:    $local_fs $network $remote_fs
# Required-Stop:     $local_fs $network $remote_fs
# Should-Start:      $NetworkManager
# Should-Stop:       $NetworkManager
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts instance of xdm
# Description:       starts instance of xdm using start-stop-daemon
### END INIT INFO

############### EDIT ME ##################
# startup args
# script name
NAME=xdm

# app name
DESC=XDM

# user
RUN_AS='${mainuser}'
# path to app
APP_PATH='${INSTALLDIR}'/XDM
# path to python bin
DAEMON=/usr/bin/python2.7
PID_FILE=/var/run/xdm.pid
DAEMON_OPTS="XDM.py -d --nolaunch --pidfile $PID_FILE"
############### END EDIT ME ##################

test -x $DAEMON || exit 0

set -e

case "$1" in
  start)
        echo "Starting $DESC"
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE  --make-pidfile --exec $DAEMON -- $DAEMON_OPTS
        ;;
  stop)
        echo "Stopping $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE | rm -rf $PID_FILE
        ;;

  restart|force-reload)
        echo "Restarting $DESC"
        start-stop-daemon --stop --pidfile $PID_FILE
        sleep 15
        start-stop-daemon -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE  --make-pidfile --exec $DAEMON -- $DAEMON_OPTS
        ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0' > /etc/init.d/xdm
	cd $INSTALLDIR/XDM
	/usr/local/bin/pip-2.7 install jinja2
	/usr/local/bin/pybabel extract -F babel.cfg -o ./i18n/messages.pot .
	/usr/local/bin/pybabel init -i ./i18n/messages.pot -d i18n -l ``en``
	/usr/local/bin/pybabel update -i ./i18n/messages.pot -d i18n
	/usr/local/bin/pybabel compile -d i18n -f
	chmod 755 /etc/init.d/xdm > /dev/null 2>&1
	update-rc.d xdm defaults > /dev/null 2>&1
	chmod -R a+x $INSTALLDIR/XDM > /dev/null 2>&1
	chown -hR $mainuser:$maingroup $INSTALLDIR/XDM > /dev/null 2>&1
	service xdm start > /dev/null 2>&1
	sleep 5
	service xdm stop > /dev/null 2>&1
	chmod -R a+x $INSTALLDIR/XDM > /dev/null 2>&1
	service xdm start > /dev/null 2>&1
	service="XDM"
	address="http://$ip:8085"
	port=":8085"
	panel;
	echo "";
	echo "Finished";
	sleep 1
else
	xdm="0"
fi
}

warnRoot;
menu;


exit 0

# End of script
CRAP()
{
MYSQL=$(which mysql)

# check password
if ! $($MYSQL mysql -u root --password="$SQLPASSWORD" -e "SHOW DATABASES;" > /dev/null 2>&1); then
	echo "Password is wrong, try again"
	input_PW
fi

# drop DB if it exists
if $($MYSQL mysql -u root --password="$SQLPASSWORD" -e "SHOW DATABASES;" | grep 'newznab' > /dev/null 2>&1); then
	$MYSQL mysql -u root --password="$SQLPASSWORD" -e "DROP DATABASE newznab;" > /dev/null 2>&1
fi

# drop USER if it exists
if $($MYSQL mysql -u root --password="$SQLPASSWORD" -e "select user.user from mysql.user;" | grep 'newznab' > /dev/null 2>&1); then
	$MYSQL mysql -u root --password="$SQLPASSWORD" -e "DROP USER 'newznab'@'localhost';" > /dev/null 2>&1
fi

# create DB
$MYSQL mysql -u root --password="$SQLPASSWORD" -e "
CREATE DATABASE newznab;
CREATE USER 'newznab'@'localhost' IDENTIFIED BY 'newznab';
GRANT ALL PRIVILEGES ON newznab.* TO newznab @'localhost' IDENTIFIED BY 'newznab';"

# check if database and user is created
if ! $($MYSQL mysql -u root --password="$SQLPASSWORD" -e "SHOW DATABASES;" | grep 'newznab' > /dev/null 2>&1); then
	echo
	echo "Creation of database failed, try again"
	error_Msg
fi

if ! $($MYSQL mysql -u root --password="$SQLPASSWORD" -e "select user.user from mysql.user;" | grep 'newznab' > /dev/null 2>&1); then
	echo
	echo "Creation of user failed, try again"
	error_Msg
fi

echo
echo "Created a database named newznab for user newznab with password newznab"
echo

#NEWZNABDIR="/media/ae17113f-d82f-4c67-9e59-5ea9fcb05f63/myapps"
#rm -R /var/www/newznab/db/sphinxdata/binlog/
#mkdir -p /var/www/newznab/db/sphinxdata/binlog/
#chmod -R 777 /var/www/newznab/db/sphinxdata/binlog
#php5 /var/www/newznab/misc/sphinx/nnindexer.php generate
#php5 /var/www/newznab/misc/sphinx/nnindexer.php daemon
#php5 /var/www/newznab/misc/sphinx/nnindexer.php index full all
#php5 /var/www/newznab/misc/sphinx/nnindexer.php index delta all
#php5 /var/www/newznab/misc/sphinx/nnindexer.php daemon --stop
#php5 /var/www/newznab/misc/sphinx/nnindexer.php daemon
#ps -ewwo pid,args | grep [s]e

}

