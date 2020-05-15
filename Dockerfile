FROM hnc-base:latest
LABEL name="hnc-opendnas"
LABEL description="HashNet Container for OpenDNAS"
LABEL maintainer="hashsploit <hashsploit@protonmail.com>"

ARG DNS_SERVER=0.0.0.0
ARG EMAIL=opendnas@example.com

ENV DNS_SERVER $DNS_SERVER
ENV EMAIL $EMAIL


# Install dependencies
RUN apt-get update >/dev/null 2>&1 \
	&& apt-get install -y \
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
	libpcre3-dev \
	libapr1-dev \
	libaprutil1-dev \
	>/dev/null 2>&1


# Download dependencies
ADD [ \
		"https://www.openssl.org/source/old/1.0.2/openssl-1.0.2i.tar.gz", \
		"https://ftp.pcre.org/pub/pcre/pcre-8.40.tar.gz", \
		"https://www.zlib.net/zlib-1.2.11.tar.gz", \
		"https://archive.apache.org/dist/httpd/httpd-2.4.2.tar.gz", \
		"https://www.php.net/distributions/php-7.0.15.tar.gz", \
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
	&& tar -zxf httpd-2.4.2.tar.gz \
	&& rm -f httpd-2.4.2.tar.gz \
	&& tar -zxf php-7.0.15.tar.gz \
	&& rm -f php-7.0.15.tar.gz \
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


# Install apache
RUN cd /root/build/httpd-2.4.2 \
	&& ./configure --prefix=/etc/apache2 \
		--enable-access_compat \
		--enable-actions \
		--enable-alias \
		--enable-allowmethods \
		--enable-auth_basic \
		--enable-rewrite \
		--enable-proxy \
		--enable-expires \
		--enable-autoindex \
		--enable-dir \
		--enable-env \
		--enable-headers \
		--enable-include \
		--enable-log_config \
		--enable-mime \
		--enable-negotiation \
		--enable-proxy \
		--enable-proxy_http \
		--enable-rewrite \
		--enable-setenvif \
		--with-ssl=/usr/local/ssl \
		--enable-ssl \
		--enable-so \
	&& make \
	&& make install


# Install php7.0.15
RUN cd /root/build/php-7.0.15/ \
	&& chmod +x configure \
	&& ./configure \
		--enable-sockets \
		--enable-bcmath \
		--enable-phar \
		--with-gettext \
		--with-openssl-dir=../openssl-1.0.2i \
		--with-mhash \
		--with-mcrypt \
		--with-curl \
		--with-libdir=lib/x86_64-linux-gnu \
	&& make


RUN cd /root/build/php-7.0.15/ \
	&& make install


# Install OpenDNAS and copy configuration
ADD https://github.com/hashsploit/OpenDNAS/archive/apache.zip /tmp/
RUN cd /tmp/ \
	&& unzip apache.zip \
	&& rm -rf apache.zip \
	&& mv OpenDNAS-apache/ /var/www/OpenDNAS/
COPY fs/ /
RUN echo "Installing OpenDNAS ..." \
	&& envsubst '${FQDN},${BASE_URL}' < /etc/apache2/sites-available/opendnas.conf > /tmp/opendnas.conf \
	&& envsubst < /var/www/opendnas/public/index.html > /tmp/index.html \
	&& envsubst '${BASE_URL}' < /var/www/opendnas/public/oembed.json > /tmp/oembed.json \
	&& cp /tmp/opendnas.conf /etc/apache2/sites-available/apache2.conf \
	&& cp /tmp/index.html /var/www/opendnas/public/index.html \
	&& cp /tmp/oembed.json /var/www/opendnas/public/oembed.json \
	&& ln -s /etc/apache2/sites-available/apache2.conf /etc/apache2/sites-enabled/apache2.conf \
	&& rm -rf \
		/tmp/* \
#		/var/www/opendnas/.git \
#		/var/www/opendnas/.gitignore \
#		/var/www/opendnas/LICENSE \
#		/var/www/opendnas/nginx.vhost \
#		/var/www/opendnas/README.md \
	&& openssl req -x509 -nodes \
		-newkey rsa:4096 \
		-keyout /etc/nginx/certs/${FQDN}.key \
		-out /etc/nginx/certs/${FQDN}.cert \
		-days 9999 \
		-subj "/C=US/ST=California/L=San Francisco/O=${FQDN}/OU=Org/CN=${FQDN}/emailAddress=${EMAIL}" \
	&& chmod 755 -R /var/www \
	&& chown www-data:www-data -R /var/www \
	&& rm -rf /root/build/


# Make startup script executable
RUN chmod +x /srv/start.sh


# Expose service
EXPOSE 443


# Execute start
CMD ["bash", "/srv/start.sh"]
