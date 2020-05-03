FROM hnc-base:latest
LABEL name="hnc-opendnas"
LABEL description="HashNet Container for OpenDNAS"
LABEL maintainer="hashsploit <hashsploit@protonmail.com>"

ARG FQDN=opendnas.localhost
ARG BASE_URL=https://opendnas.localhost
ARG DNS_SERVER=0.0.0.0

ENV FQDN $FQDN
ENV BASE_URL $BASE_URL
ENV DNS_SERVER $DNS_SERVER


# Install dependencies
RUN apt-get update >/dev/null 2>&1 \
	&& apt-get install -y \
	bc \
	unzip \
	make \
	gcc \
	g++ \
	gettext \
	build-essential \
	autoconf \
	libtool \
	libxml2-dev \
	libjpeg-dev \
	libpng-dev \
	libfreetype6 \
	libfreetype6-dev \
	libmcrypt4 \
	libmcrypt-dev \
	libsqlite3-0 \
	libsqlite3-dev \
	pkg-config \
	>/dev/null 2>&1


# Download dependencies
ADD [ \
		"https://www.openssl.org/source/old/1.0.2/openssl-1.0.2i.tar.gz", \
		"https://ftp.pcre.org/pub/pcre/pcre-8.40.tar.gz", \
		"https://www.zlib.net/zlib-1.2.11.tar.gz", \
		"https://nginx.org/download/nginx-1.16.1.tar.gz", \
		"https://www.php.net/distributions/php-7.4.4.tar.gz", \
		"https://github.com/curl/curl/releases/download/curl-7_70_0/curl-7.70.0.tar.gz", \
		"/root/build/" \
	]


RUN cd /root/build/ \
	&& tar -zxf openssl-1.0.2i.tar.gz \
	&& rm -f openssl-1.0.2i.tar.gz \
	&& tar -zxf pcre-8.40.tar.gz \
	&& rm -f pcre-8.40.tar.gz \
	&& tar -zxf zlib-1.2.11.tar.gz \
	&& rm -f zlib-1.2.11.tar.gz \
	&& tar -zxf nginx-1.16.1.tar.gz \
	&& rm -f nginx-1.16.1.tar.gz \
	&& tar -zxf php-7.4.4.tar.gz \
	&& rm -f php-7.4.4.tar.gz \
	&& tar -zxf curl-7.70.0.tar.gz \
	&& rm -f curl-7.70.0.tar.gz


# Compile openssl-1.0.2i (support for SSLv2)
RUN cd /root/build/openssl-1.0.2i \
	&& ./config enable-ec_nistp_64_gcc_128 enable-weak-ssl-ciphers \
	&& make depend \
	&& make \
	&& make install_sw


# Compile curl
RUN cd /root/build/curl-7.70.0 \
	&& ./configure --with-openssl=../openssl-1.0.2i \
	&& make \
	&& make install

# Install nginx
RUN cd /root/build/nginx-1.16.1/ \
	&& ./configure --prefix=/usr/share/nginx \
		--sbin-path=/usr/sbin/nginx \
		--modules-path=/usr/lib/nginx/modules \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/run/nginx.pid \
		--lock-path=/var/lock/nginx.lock \
		--user=www-data \
		--group=www-data \
		--build=OpenDNAS \
		--http-client-body-temp-path=/var/lib/nginx/body \
		--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
		--http-proxy-temp-path=/var/lib/nginx/proxy \
		--http-scgi-temp-path=/var/lib/nginx/scgi \
		--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
		--with-openssl=../openssl-1.0.2i \
		--with-openssl-opt=enable-ec_nistp_64_gcc_128 \
		--with-openssl-opt=enable-weak-ssl-ciphers \
		--with-pcre=../pcre-8.40 \
		--with-pcre-jit \
		--with-zlib=../zlib-1.2.11 \
		--with-compat \
		--with-file-aio \
		--with-threads \
		--with-http_addition_module \
		--with-http_auth_request_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_random_index_module \
		--with-http_realip_module \
		--with-http_slice_module \
		--with-http_ssl_module \
		--with-http_sub_module \
		--with-http_stub_status_module \
		--with-http_v2_module \
		--with-http_secure_link_module \
		--with-stream \
		--with-stream_realip_module \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-debug \
		--with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2' \
		--with-ld-opt='-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now' \
	&& make \
	&& make install \
	&& mkdir -p /var/www/ \
	&& mkdir -p /var/lib/nginx/body \
	&& mkdir -p /var/lib/nginx/fastcgi \
	&& mkdir -p /var/lib/nginx/proxy \
	&& mkdir -p /var/lib/nginx/scgi \
	&& mkdir -p /var/lib/nginx/uwsgi


# Install php7.4-fpm
RUN cd /root/build/php-7.4.4/ \
	&& chmod +x configure \
	&& ./configure \
		--enable-fpm \
		--enable-sockets \
		--enable-bcmath \
		--enable-phar \
		--with-gettext \
		--with-openssl-dir=../openssl-1.0.2i \
		--with-mhash \
		--with-curl \
		--with-fpm-user=www-data \
		--with-fpm-group=www-data \
		--with-libdir=lib/x86_64-linux-gnu \
	&& make

RUN cd /root/build/php-7.4.4/ \
	&& make install \
	&& cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm \
	&& chmod +x /etc/init.d/php-fpm \
	&& update-rc.d php-fpm defaults \
	&& mv /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf \
	&& sed -i 's|NONE/etc/php-fpm.d/\*.conf|/usr/local/etc/php-fpm.d/\*.conf|g' /usr/local/etc/php-fpm.conf \
	&& mv /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf \
	&& /etc/init.d/php-fpm start

# Install OpenDNAS and copy configuration
ADD https://github.com/hashsploit/OpenDNAS/archive/master.zip /tmp/
RUN cd /tmp/ \
	&& unzip master.zip \
	&& rm -rf master.zip \
	&& mv OpenDNAS-master/ /var/www/OpenDNAS/
COPY scripts/ /
RUN echo "Installing OpenDNAS ..." \
	&& envsubst '${FQDN},${BASE_URL}' < /etc/nginx/nginx.conf > /tmp/nginx.conf \
	&& envsubst < /var/www/OpenDNAS/public/index.html > /tmp/index.html \
	&& envsubst '${BASE_URL}' < /var/www/OpenDNAS/public/oembed.json > /tmp/oembed.json \
	&& cp /tmp/nginx.conf /etc/nginx/nginx.conf \
	&& cp /tmp/index.html /var/www/OpenDNAS/public/index.html \
	&& cp /tmp/oembed.json /var/www/OpenDNAS/public/oembed.json \
	&& mv /var/www/OpenDNAS/certs/ /etc/nginx/ \
	&& rm -rf \
		/etc/nginx/sites-enabled/ \
		/etc/nginx/sites-available/ \
		/tmp/* \
		/var/www/OpenDNAS/.gitignore \
		/var/www/OpenDNAS/LICENSE \
		/var/www/OpenDNAS/nginx.vhost \
		/var/www/OpenDNAS/README.md \
	&& openssl req -x509 -nodes \
		-newkey rsa:4096 \
		-keyout /etc/nginx/certs/${FQDN}.key \
		-out /etc/nginx/certs/${FQDN}.cert \
		-days 9999 \
		-subj "/C=US/ST=California/L=San Francisco/O=${FQDN}/OU=Org/CN=${FQDN}" \
	&& chmod 755 -R /var/www \
	&& chown www-data:www-data -R /var/www \
	&& rm -rf /root/build/


# Make startup script executable
RUN chmod +x /srv/start.sh


# Expose service
EXPOSE 80
EXPOSE 443


# Execute start
CMD ["bash", "/srv/start.sh"]
