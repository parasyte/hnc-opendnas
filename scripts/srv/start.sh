#!/bin/bash

# Patch Dnsmasq responses
if [[ "$MYIP" != "" ]] ; then
    sed -i /etc/dnsmasq.conf -e "s/192\.0\.2\.1/${MYIP}/"
fi

# Start Dnsmasq
/usr/local/sbin/dnsmasq

# Start PHP-FPM
/usr/local/sbin/php-fpm &

# Start nginx
exec /usr/sbin/nginx -g "daemon off;"
