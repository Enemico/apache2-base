#!/bin/bash


BUILD_PACKAGES="rsync"

PACKAGES="
  curl
  apache2-mpm-itk
  prometheus-apache-exporter
  libapache2-mod-removeip
  php-cli
  php-fpm
  php-gd
"
## make use of bitnami's logic for installing packages

if [ "x$(which install_packages)" = "x" ]; then
  install_packages () {
    env DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends "$@"  
  }
fi

install_all_packages () {
  apt update
  install_packages ${PACKAGES} ${BUILD_PACKAGES}
}

## clean up after us
cleanup () {
  apt-get remove -y --purge ${BUILD_PACKAGES}
  apt-get autoremove -y
  apt-get clean
  rm -fr /var/lib/apt/lists/*
  rm -fr /tmp/conf
}

# Rsync our configuration, on top of /etc. 
rsync () {
  rsync -a /tmp/conf/ /etc/ 
}

# Make sure /usr/local/bin/setup-apache.sh is executable. 
chmod +x /usr/local/bin/setup-apache.sh

install_all_packages
rsync
cleanup
