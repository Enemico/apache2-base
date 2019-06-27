
Docker base image with Apache2 and PHP.

Comes with a minimal configuration for Apache2, including some common
sensible settings. Images wishing to use this one as a base should run
the */usr/local/bin/setup-apache.sh* script at build time, after
having defined some environment variables to customize the
configuration:

* `APACHE_MODULES_ENABLE` is a list of apache2 modules to enable (by
  default the *headers*, *proxy_fcgi*, *removeip* and *setenvif*
  modules are enabled, on top of what Debian provides).
* `APACHE_MODULES_DISABLE` is a list of apache2 modules that will be
  disabled. By default it includes *access_compat*, *deflate* and
  *ssl* (because the front-ends will terminate SSL connections).
* `APACHE_CONFIG_ENABLE` is a list of snippets from
  */etc/apache2/conf.d* that will be enabled globally for all
  sites. If you define this, obviously you must ensure that your image
  includes those files in the first place.
* `APACHE_CONFIG_DISABLE` is a list of snippets from the default
  Debian configuration that must be disabled. You probably won't need
  to change this: by default it disables the *other-vhost-access-log*
  and *serve-cgi-bin* snippets, which aren't relevant to our setup.
* `APACHE_SITES` is a list of sites in */etc/apache2/sites-available*
  that will be enabled.

By default the server will listen on port 8080, but it is possible to
override this at runtime by setting the `APACHE_PORT` variable in the
container environment.

If you need php-fpm, set the environment variable
`PHP_FPM_ENABLE=1`. This will enable php-fpm both in Apache2 and
Chaperone.
