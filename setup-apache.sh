#!/bin/sh
#
# Set up Apache, at image build time.
#
# To be invoked at build time by images using the docker-apache2-base
# image, after having defined the desired environment variables in
# order to customize Apache behavior.
#

set -e

# Apache modules to enable.
APACHE_MODULES_ENABLE="
  headers
  proxy_http
  proxy_fcgi
  setenvif
  ${APACHE_MODULES_ENABLE:-}
"

# Apache modules that are enabled by default by the Debian package,
# and that we want to disable.
APACHE_MODULES_DISABLE="
  ${APACHE_MODULES_DISABLE:-}
"

# Config snippets to enable for Apache.
APACHE_CONFIG_ENABLE="
  metrics
  ${APACHE_CONFIG_ENABLE:-}
"

# Config snippets to disable.
APACHE_CONFIG_DISABLE="
  other-vhosts-access-log
  serve-cgi-bin
  ${APACHE_CONFIG_DISABLE:-}
"

APACHE_SITES="${APACHE_SITES:-}"

APACHE_PORT_DEFAULT=8080

# Controls whether php-fpm is configured in apache2 and chaperone.
PHP_FPM_ENABLE="${PHP_FPM_ENABLE:-0}"

# Install the php-fpm chaperone service if required.
if [ $PHP_FPM_ENABLE -eq 1 ]; then
    APACHE_CONFIG_ENABLE="$APACHE_CONFIG_ENABLE php7.3-fpm"
    cat >/etc/chaperone.d/fpm.conf <<EOF
fpm.service: {
    command: "/usr/sbin/php-fpm7.3 --force-stderr --nodaemonize",
    exit_kills: true,
}
fpm-exporter.service: {
    command: "sh -c '. /etc/apache2/envvars && HOME=/ exec /usr/sbin/php-fpm-exporter server --phpfpm.scrape-uri=unix:///run/php/php7.3-fpm.sock\\\\;/status --web.listen-address=:\$PHP_FPM_EXPORTER_PORT'",
    restart: true,
}
EOF

    # Install the php-fpm prometheus exporter binary (no package yet).
    curl -sL -o /usr/sbin/php-fpm-exporter \
         https://github.com/hipages/php-fpm_exporter/releases/download/v1.0.0/php-fpm_exporter_1.0.0_linux_amd64
    chmod 0755 /usr/sbin/php-fpm-exporter
fi

# Enable/disable Apache modules and configs.
a2enmod -q ${APACHE_MODULES_ENABLE}
a2dismod -q -f ${APACHE_MODULES_DISABLE}
a2enconf -q ${APACHE_CONFIG_ENABLE}
a2disconf -q ${APACHE_CONFIG_DISABLE}
a2ensite ${APACHE_SITES}

# Fix Apache error logging.
sed -i -e 's@^ErrorLog.*$@ErrorLog /dev/stderr@' /etc/apache2/apache2.conf

# Set the port that Apache will listen on.
echo "export APACHE_PORT=\${APACHE_PORT:-${APACHE_PORT_DEFAULT}}" >> /etc/apache2/envvars
echo "export APACHE_EXPORTER_PORT=\`expr \$APACHE_PORT + 100\`" >> /etc/apache2/envvars
echo "export PHP_FPM_EXPORTER_PORT=\`expr \$APACHE_PORT + 200\`" >> /etc/apache2/envvars

# Make APACHE_RUN_USER externally configurable (defaults to www-data if unset).
sed -i -e 's/^\(export APACHE_RUN_USER=\).*$/\1${APACHE_RUN_USER:-www-data}/' /etc/apache2/envvars

# Create the directories that Apache will need at runtime,
# since we won't be using the init script. To allow for apache
# not being started as root, create the directories with mode 1777.
(. /etc/apache2/envvars
 install -d -m 1777 ${APACHE_RUN_DIR}
 install -d -m 1777 ${APACHE_LOCK_DIR}
 install -d -m 1777 ${APACHE_LOG_DIR}
 install -d -m 1777 /var/run/php
 install -d -m 1777 /var/log
 install -d -m 1777 /var/lib/apache2/fcgid
)
