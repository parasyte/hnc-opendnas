#!/bin/bash

# Start PHP-FPM
/usr/local/sbin/php-fpm &

# Start nginx
exec /usr/sbin/nginx -g "daemon off;"
