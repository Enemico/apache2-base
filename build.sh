#!/bin/bash


BUILD_PACKAGES="rsync"

PACKAGES="
  curl
  apache2
  prometheus-apache-exporter
  libapache2-mod-removeip
  php-cli
  php-fpm
  php-gd
"
## make use of bitnami's logic for installing packages

if [ "x$(which install_packages)" = "x" ]; then
  install_packages () {
    env DEBIAN_FRONTEND=noninteractive apt-get install -qy \
	    -qy -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
	    --no-install-recommends "$@"
  }
fi

install_all_packages () {
  apt update
  install_packages ${BUILD_PACKAGES} ${PACKAGES}
}

## clean up after us
cleanup () {
  apt-get remove -y --purge ${BUILD_PACKAGES}
  apt-get autoremove -y
  apt-get clean
  rm -fr /var/lib/apt/lists/*
  rm -fr /tmp/conf
  rm -fr /var/log/dpkg.log
  rm -fr /var/log/apt/*
}

# Rsync our configuration, on top of /etc, and var/www on top of var
sync () {
  rsync -a /tmp/conf/ /etc/
  rsync -a /tmp/var/www/ /var/www/
}

# Make sure /usr/local/bin/setup-apache.sh is executable.
chmod +x /usr/local/bin/setup-apache.sh

set -x
set -e

install_all_packages
sync
cleanup
