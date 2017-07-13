#!/bin/bash
# Author: @grigruss:matrix.org

echo "Starting the system setup to install matrix-synapse"
echo
echo "The following sources will be added to /etc/apt/sources.list"
echo " 1.http://ftp.debian.org/debian jessie-backports main"
echo " 2.http://matrix.org/packages/debian/ jessie main"
echo

aptq(){
    echo "Confirm the changes? [Y/n]:"
    read -n 1 varapt
    aptif
}

aptc(){
    if grep "jessie-backports" /etc/apt/sources.list;
    then
	echo "Have backports"
    else
	echo "Add backports"
	echo "# Inserted for installing matrix-synapse & Riot-web">>/etc/apt/sources.list
	echo "deb http://ftp.debian.org/debian jessie-backports main">>/etc/apt/sources.list
	echo >>/etc/apt/sources.list
    fi

    if grep "http://matrix.org/packages/debian/ jessie main" /etc/apt/sources.list;
    then
	echo "Have matrix.org repo"
    else
	echo "Add matrix.org repo-key"
	wget http://matrix.org/packages/debian/repo-key.asc
	apt-key add repo-key.asc
	rm -rf repo-key.asc
	echo "Add matrix.org repo"
	echo "# Inserted for installing matrix-synapse">>/etc/apt/sources.list
	echo "deb http://matrix.org/packages/debian/ jessie main">>/etc/apt/sources.list
	echo >>/etc/apt/sources.list
    fi
    apt-get update
}

aptif(){
    if [ $varapt == "y" ]
    then
	echo
	aptc
    elif [ $varapt != "n" ]
    then
	echo
	echo "Only \"y\" or \"n\""
	aptq
    else
	echo
	echo "Action canceled, no further installation is not possible."
	exit 0
    fi
}

aptq
instq(){
    echo
    echo "Do you want to install matrix-synapse now? [Y/n]"
    read -n 1 inst
    instif
}
instif(){
    if [ $inst == "y" ]
    then
	echo
	apt-get install jq curl matrix-synapse
    elif [ $inst != "n" ]
    then
	echo
	echo "Only \"y\" or \"n\""
	instq
    else
	echo
	echo "Action canceled, no further installation is not possible."
	exit 0
    fi
}
instq

riotq(){
    echo
    echo "Do you want to install Riot on your site now? [Y/n]"
    read -n 1 riot
    riotif
}

echo
echo "Enter site path [/var/www/html/]:"
read WWW

echo
if [ -z $WWW ]
then
    WWW="/var/www/html/"
    echo "Use the default path"
fi
echo $WWW

content=$(curl https://api.github.com/repos/grigruss/Riot-web-server-update/releases/latest)
download=$(jq -r '.tarball_url' <<<"$content")
echo "Download Riot updator shell script"
curl -Ls "$download" | tar xz --strip-components=1 -C ./
FILE="riot-update.sh"
while read LINE; do
    if [ ${LINE:5:10} == "/www/html/" ]
    then
	www="/www/html/"
	echo ${LINE/$www/$WWW}>>$FILE.new
    else
	echo $LINE>>$FILE.new
    fi
done < $FILE
mv $FILE.new $FILE
chmod +x $FILE

echo "Download latest version of Riot-web"
./riot-update.sh

echo
echo "Matrix-synapse and Riot-web are installed."
echo
echo "To automatically update the Riot-web, add the following line to cron (crontab -e):"
echo "============================================================================"
p=$(pwd)
echo "0 0 * * * $p/$FILE"
echo "============================================================================"
echo "This line will cause the update to run every day at 00:00."
echo "The update will only be performed if a new version of Riot-web is available."
echo
