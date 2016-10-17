#!/bin/bash

#FILE: 			install-mongo.sh
#
#DESCRIPTION:  Install MongoDB on your system
#REQUIREMENTS: wget, tar, gunzip
#AUTHOR:	   Patrick Facco (pedrick[at]tiscali[dot]it) 
#VERSION:  	   0.1
#CREATED:      06/11/2014 15:02:46 CEST
#LICENSE:      GNU/GPLv3
#COPYRIGHT:	   2014 Patrick Facco
#
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

#choose version to download
versionToDownload="3.2.10"

if [ x != $1x ]
then
	versionToDownload=$1
fi

#check if the user is root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#download mongodb
fileName="mongodb.tgz"
installPrefix="/opt"
wget  'http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-'$versionToDownload'.tgz' -O $installPrefix/$fileName

#extract package and remove .tgz file
currentDir=$(pwd)

cd $installPrefix
tar xzvf $fileName
rm $fileName
#rename folder
mv "mongodb-linux-x86_64-"$versionToDownload $(echo "$fileName" | cut -d '.' -f1)

#update path for commands
cd /usr/bin
for i in $(ls $installPrefix/mongodb/bin)
do
	ln -s $installPrefix/mongodb/bin/$i $i
	echo $i" installed"
done

#create directory for data and log
mkdir -p /data/db
mkdir -p /var/log/mongo

#create upstar script
cat > /etc/init.d/mongodb << EOF
#!/bin/bash
if [ \$1 = "start" ]
	then
		rm /data/db/mongod.lock
		(mongod --journal --logpath /var/log/mongo/mongodb.log --dbpath /data/db)&
else if [ \$1 = "stop" ]
	 then
		kill -9 \$(pidof mongod)
		rm /data/db/mongod.lock
	 fi
fi
EOF

chmod +x /etc/init.d/mongodb
echo "/etc/init.d/mongo successfully created"

#update upstart
cd /etc/init.d
update-rc.d mongodb defaults
echo "upstart successfully updated"

#launch mongod
/etc/init.d/mongodb start

cd $currentDir
echo "MongoDB is Successfully installed and launched try to connect using mongo!"

#update repository index
apt-get update
#install apache, php and mongodriver
apt-get install -y build-essential apache2 libapache2-mod-php5 php5-dev php-pear php5 php5-cli php5-common
#install mongo extension
pecl install mongo
#mongo extension activation
echo "extension=mongo.so" >> /etc/php5/apache2/php.ini
/etc/init.d/apache2 restart

