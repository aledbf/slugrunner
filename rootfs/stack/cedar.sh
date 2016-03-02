#!/bin/sh

set -e

export DEBIAN_FRONTEND=noninteractive
export TERM=linux

# Use local mirror.
cat > /etc/apt/sources.list <<EOF
deb mirror://mirrors.ubuntu.com/mirrors.txt wily main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt wily-updates main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt wily-backports main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt wily-security main restricted universe multiverse
deb http://ppa.launchpad.net/webupd8team/java/ubuntu wily main
deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu wily main
EOF

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927

# Update packagaes
apt-get update && apt-get -y dist-upgrade && apt-get install -y software-properties-common

# Accept licenses
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections

# Timezone
rm /etc/localtime
ln -s /usr/share/zoneinfo/America/Santiago /etc/localtime

echo "America/Santiago" | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# Default locales
echo 'LANG="en_US.UTF-8"' > /etc/default/locale
echo 'LC_MESSAGES="POSIX"' >> /etc/default/locale

apt-get -y install wget sudo locales language-pack-en language-pack-es-base
update-locale LANG=en_US.UTF-8

# Phantomjs
#ln -s /stack/phantomjs /usr/sbin/phantomjs
ln -s /stack/libxl.so /usr/lib

# Install packages
xargs apt-get install -y --force-yes --no-install-recommends < /stack/packages.txt

# Install mongodb cli tools
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list

apt-get update && apt-get install -y --force-yes mongodb-org-tools

# Configure fonts
mv /stack/localfonts.conf /etc/fonts/local.conf
ln -sf /etc/fonts /usr/local/etc/fonts
mkdir -p /usr/etc
ln -sf /etc/fonts/ /usr/etc/fonts

fc-cache -f -v

apt-get remove -y python3 python3.4

apt-get -y autoremove

cd /

mkdir -p /var/lib/libuuid

apt-get clean -y

rm /usr/bin/mongofiles 
rm /usr/bin/mongooplog
rm /usr/bin/mongoperf
rm /usr/bin/mongostat
rm /usr/bin/mongotop

upx -1 /usr/bin/mongodump -o /usr/bin/mongodump-n
upx -1 /usr/bin/mongoexport -o /usr/bin/mongoexport-n
upx -1 /usr/bin/mongoimport -o /usr/bin/mongoimport-n
upx -1 /usr/bin/mongorestore -o /usr/bin/mongorestore-n

mv /usr/bin/mongodump-n /usr/bin/mongodump
mv /usr/bin/mongoexport-n /usr/bin/mongoexport
mv /usr/bin/mongoimport-n /usr/bin/mongoimport
mv /usr/bin/mongorestore-n /usr/bin/mongorestore

rm -rf /usr/share/man /usr/share/doc
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/archives/*.deb
rm -rf /root/*
rm -rf /var/cache/oracle-*

rm -rf /usr/lib/jvm/java-8-oracle/lib/missioncontrol
rm -rf /usr/lib/jvm/java-8-oracle/lib/visualvm

# remove SUID and SGID flags from all binaries
pruned_find() {
  find / -type d \( -name dev -o -name proc \) -prune -o $@ -print
}

pruned_find -perm /u+s | xargs -r chmod u-s
pruned_find -perm /g+s | xargs -r chmod g-s

# remove non-root ownership of files
chown root:root /var/lib/libuuid

# display build summary
set +x
echo -e "\nRemaining suspicious security bits:"
(
  pruned_find ! -user root
  pruned_find -perm /u+s
  pruned_find -perm /g+s
  pruned_find -perm /+t
) | sed -u "s/^/  /"

echo -e "\nSuccess!"
exit 0
