OMV_Installers
==============
Updated script based on my old script that was here,

http://forums.openmediavault.org/viewtopic.php?f=13&t=6

To use this script you only need to do the following.

This assuming you have a working OMV server and have SSH enabled.

1) SSH into your servers IP address via your chosen terminal program: I use Putty for Windows but the normal Terminal in Linux or MAC Osx would do it just as good. If using Linux or Mac OS you would use the following command in the terminal

[code]ssh root@<ip address> - replace "<ip address>" with the IP address of your server[/code]

When prompted enter the password for the root user (chosen during the OMV install)

2) Once your logged in via SSH type following commands 1 by 1 and in this order:

[code]cd /
wget http://ADDRESS STILL TO COME/omv.sh
chmod +x /omv.sh
./omv.sh[/code]

3) This is just a base script that will download and run the latest version of the main script, you should not delete this script as it will save you downloading it again later if you need to update or add any other programs.

4) Once the main screen starts you should see a screen like this.

<a target='_blank' title='ImageShack - Image And Video Hosting' href='http://imageshack.us/photo/my-images/14/mainmenut.jpg/'><img src='http://img14.imageshack.us/img14/6950/mainmenut.jpg' border='0'/></a>

On this screen you will see a list of programs that can be installed. You will also see at the bottom of the screen the current IP address and the folder MOST
programs will be installed to. 

5) Press i or I [Enter] to change the IP address (only needs to be done if not the correct IP for your OMV system) 

6) Press f or F [Enter] to change the folder MOST programs will be installed to.

<a target='_blank' title='ImageShack - Image And Video Hosting' href='http://imageshack.us/photo/my-images/845/folder1c.jpg/'><img src='http://img845.imageshack.us/img845/6748/folder1c.jpg' border='0'/></a>

This looks complicated but trust me its not. You will see a list of folder in the root of your system drive (like above) if you wanted to install your
programs here you would just enter 0 [Enter], if you want to install inside /opt you would do 23 [Enter] this will put you inside /opt you just
do 0 [Enter] to select this folder. If you go to a folder and want to go back, just do 1 [Enter] and you will be taken back 1 level.

7) Once you have the correct IP and folder setup you can then proceed to start installing programs. From the list you can choose 1 or more programs to install.
    Eg. 1 [Enter] will only install CouchPotato, 1 5 10 [Enter] will install CouchPotato, SickBeard (Develop) and Subsonic 4.8

8) Once you have selected the program(s) you wish to install you will see a confirmation screen like this

<a target='_blank' title='ImageShack - Image And Video Hosting' href='http://imageshack.us/photo/my-images/689/confirmq.jpg/'><img src='http://img689.imageshack.us/img689/558/confirmq.jpg' border='0'/></a>

all you have to do now is either press y to start the install(s) pressing n will return you to the main window.

9) After each program is installed you will be asked if you would like a link added to the side menu of the OMV webui (see below)
    This links once clicked will open the webui for that program in a new tab.

<a target='_blank' title='ImageShack - Image And Video Hosting' href='http://imageshack.us/photo/my-images/19/omve.jpg/'><img src='http://img19.imageshack.us/img19/3452/omve.jpg' border='0'/></a>

10) When all programs have been installed you will see a end menu that will show what was installed and what address you can access its webui from.

<a target='_blank' title='ImageShack - Image And Video Hosting' href='http://imageshack.us/photo/my-images/11/finishqe.jpg/'><img src='http://img11.imageshack.us/img11/6769/finishqe.jpg' border='0'/></a>

I used some of mcloum's guide from the old thread (hope you don't mind)