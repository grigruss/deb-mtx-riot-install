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
	apt-get install python-certbot-apache -t jessie-backports
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

leq(){
    echo
    echo "Do you want to receive and configure the Let's Encrypt certificate for your server? [Y/n]"
    read -n 1 le
    leif
}
lem(){
    echo
    echo "Enter the domain name for matrix-synapse:"
    read led
    if [ -z $led ]
    then
	ler
    else
	certbot certonly -d $led -d www.$led
	ler
    fi
}
ler(){
    echo
    echo "Do you want to use $led for Riot-web?:"
    read -n 1 ledr
    if [ $ledr == "y" ]
    then
	echo "Ok. Use $led."
	lerd=$led
    elif [ $ledr != "n" ]
    then
	echo
	echo "Only \"y\" or \"n\""
	ler
    else
	echo
	echo "Enter the domain name for Riot-web:"
	read lerd
	if [ -z $lerd ]
	then
	    ler
	else
	    certbot certonly -d $lerd -d www.$lerd
	fi
    fi
}
leif(){
    if [ $le == "y" ]
    then
	lem
    elif [ $le != "n" ]
    then
	echo
	echo "Only \"y\" or \"n\""
	leq
    else
	echo
	echo "Action of receive and configure certificate canceled."
    fi
}
leq

echo "Domain name for matrix-synapse: $led"
echo "Domain name for Riot-web: $lerd"

python -m synapse.app.homeserver --server-name $led --config-path homeserver.yaml --generate-config --report-stats=yes
cp /etc/letsencrypt/archive/$led/* /etc/matrix-synapse/

mtxconf(){
    HFILE="/etc/matrix-synapse/homeserver.yaml"
    while read LINE; do
	if [[ $LINE == tls_certificate_path* ]]
	then
	    echo "# $LINE">>$HFILE.new
	    echo "tls_certificate_path: \"/etc/matrix-synapse/cert1.pem\"">>$HFILE.new
	elif [[ $LINE == tls_private_key_path* ]]
	then
	    echo "# $LINE">>$HFILE.new
	    echo "tls_certificate_path: \"/etc/matrix-synapse/privkey1.pem\"">>$HFILE.new
	elif [[ $LINE == tls_dh_params_path* ]]
	then
	    echo "# $LINE">>$HFILE.new
	    echo "tls_certificate_path: \"/etc/matrix-synapse/chain1.pem\"">>$HFILE.new
	else
	    echo $LINE>>$HFILE.new
	fi
    done < $HFILE
    mv $HFILE $HFILE.old
    mv $HFILE.new $HFILE
    echo
    echo "Old homeserver.yaml "
}
mtxconfq(){
    echo
    echo "Do you want to configure matrix-synapse? [y/n]"
    read -n 1 mtxc
    if [ $mtxc == "y" ]
    then
	if [ $le == "y" ]
	then
	    mtxconf
	fi
	echo "homeserver.yaml configured"
    elif [ $mtxc != "n" ]
    then
	echo
	echo "Only \"y\" or \"n\""
	leq
    else
	echo
	echo "Action canceled."
    fi
}
mtxconfq

riotconf(){
    HFILE="$WWW/config.sample.json"
    CFILE="$WWW/config.json"
    while read LINE; do
	if [[ $LINE == *default_hs_url* ]]
	then
	    echo "	\"default_hs_url\": \"https://$led:8448\",">>$CFILE
	elif [[ $LINE == *default_is_url* ]]
	then
	    echo
	    echo "Do you want to use your server as an authentication server? [y/n]"
	    read -n 1 ids
	    if [ $ids == "y" ]
	    then
		echo "	\"default_is_url\": \"https://$led:8448\",">>$CFILE
	    else
		echo $LINE>>$CFILE
	    fi
	elif [[ $LINE == *\"matrix.org\"* ]]
	then
	    echo "			\"$lerd\",">>$CFILE
	    echo $LINE>>$CFILE
	else
	    echo $LINE>>$CFILE
	fi
    done < $HFILE
    echo
}
riotconfq(){
    echo
    echo "Do you want to configure Riot-web? [y/n]"
    read -n 1 riotc
    if [ $mtxc == "y" ]
    then
	if [ $le == "y" ]
	then
	    mtxconf
	fi
	echo "config.json configured"
    elif [ $mtxc != "n" ]
    then
	echo
	echo "Only \"y\" or \"n\""
	leq
    else
	echo
	echo "Action canceled."
    fi
}

echo
echo "Setting up a website for Riot-web."
rcf="/etc/apache2/sites-avialable/$lerd.conf"
echo "<VirtualHost msg.miacnao.ru:80>">>$rcf
echo "RewriteEngine on">>$rcf
echo "RewriteCond %{SERVER_NAME} =www.$lerd [OR]">>$rcf
echo "RewriteCond %{SERVER_NAME} =$lerd">>$rcf
echo "RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,QSA,R=permanent]">>$rcf
echo "</VirtualHost>">>$rcf
echo "">>$rcf
echo "<IfModule mod_ssl.c>">>$rcf
echo "<VirtualHost $lerd:443>">>$rcf
echo "    ServerAdmin admin@$lerd">>$rcf
echo "    ServerName $lerd">>$rcf
echo "    ServerAlias www.$lerd">>$rcf
echo "    DocumentRoot \"$WWW\"">>$rcf
echo "    DirectoryIndex index.html">>$rcf
echo "    ErrorLog \"/var/logs/apache2/error.$lerd.log\"">>$rcf
echo "    CustomLog \"/home/www/httpd-logs/access.msg.miacnao.ru.log\" common">>$rcf
echo "    SSLCertificateFile /etc/letsencrypt/live/$lerd/fullchain.pem">>$rcf
echo "    SSLCertificateKeyFile /etc/letsencrypt/live/$lerd/privkey.pem">>$rcf
echo "    Include /etc/letsencrypt/options-ssl-apache.conf">>$rcf
echo "</VirtualHost>">>$rcf
echo "<Directory $WWW>">>$rcf
echo "    Options -Indexes">>$rcf
echo "</Directory>">>$rcf
echo "</IfModule>">>$rcf

echo "All done!"
echo "Config files:"
echo "matrix-synapse - /etc/matrix-synapse/homeserver.yaml"
echo "Riot-web - $WWW/config.json"
echo "site for Riot-web - /etc/apache2/sites-avialable/$lerd.conf"
echo
echo "============================================================================"
echo "Check the configuration files, and if everything is OK, run the following commands to start the server:"
echo "    systemctl restart matrix-synapse"
echo "    systemctl restart apache2"
echo
echo "And follow the link: https://$lerd"
echo "============================================================================"
echo
echo "To automatically update the Riot-web, add the following line to cron (crontab -e):"
echo "============================================================================"
p=$(pwd)
echo "0 0 * * * $p/$FILE"
echo "============================================================================"
echo "This line will cause the update to run every day at 00:00."
echo "The update will only be performed if a new version of Riot-web is available."
echo

