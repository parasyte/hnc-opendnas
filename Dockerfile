FROM hnc-base:latest
LABEL name="hnc-opendnas"
LABEL description="HashNet Container for OpenDNAS"
LABEL maintainer="hashsploit <hashsploit@protonmail.com>"

ARG FQDN=opendnas.localhost
ARG BASE_URL=https://opendnas.localhost
ENV FQDN $FQDN
ENV BASE_URL $BASE_URL

# Install dependencies
RUN apt-get update >/dev/null 2>&1 \
	&& apt-get install -y \
	bc \
	unzip \
	make \
	gcc \
	g++ \
	gettext \
	>/dev/null 2>&1

# Install nginx + OpenSSL 1.0.2i (support for SSLv2)
ADD https://www.openssl.org/source/old/1.0.2/openssl-1.0.2i.tar.gz /root/build/
RUN cd /root/build/ \
	&& tar -zxf openssl-1.0.2i.tar.gz \
	&& rm -rf openssl-1.0.2d.tar.gz
ADD https://ftp.pcre.org/pub/pcre/pcre-8.40.tar.gz /root/build/
RUN cd /root/build/ \
	&& tar -zxf pcre-8.40.tar.gz \
	&& rm -rf pcre-8.40.tar.gz
ADD http://www.zlib.net/zlib-1.2.11.tar.gz /root/build/
RUN cd /root/build/ \
	&& tar -zxf zlib-1.2.11.tar.gz \
	&& rm -rf zlib-1.2.11.tar.gz
ADD https://nginx.org/download/nginx-1.16.1.tar.gz /root/build/
RUN cd /root/build/ \
	&& tar -zxf nginx-1.16.1.tar.gz \
	&& rm -rf nginx-1.16.1.tar.gz
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
		--with-openssl-opt=enable-ec_nistp_64_gcc_128 \
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
	&& mkdir -p /var/lib/nginx/uwsgi \
	&& rm -rf /root/build/

# Install php-fpm
RUN apt-get install -y \
	php7.3-fpm \
	php7.3-json \
	php7.3-curl \
	>/dev/null 2>&1

# Install OpenDNAS and copy configuration
ADD https://github.com/hashsploit/OpenDNAS/archive/master.zip /tmp/
RUN cd /tmp/ \
	&& unzip master.zip \
	&& rm -rf master.zip \
	&& ls -laph /tmp && ls -laph /var/www/ \
	&& mv OpenDNAS-master/ /var/www/OpenDNAS/
COPY scripts/ /
RUN echo "Installing OpenDNAS ..." \
	&& envsubst '${FQDN},${BASE_URL}' < /etc/nginx/nginx.conf > /tmp/nginx.conf \
	&& envsubst < /var/www/OpenDNAS/public/index.html > /tmp/index.html \
	&& envsubst < /var/www/OpenDNAS/public/oembed.json > /tmp/oembed.json \
	&& cp /tmp/nginx.conf /etc/nginx/nginx.conf \
	&& cp /tmp/index.html /var/www/OpenDNAS/public/index.html \
	&& cp /tmp/oembed.json /var/www/OpenDNAS/public/oembed.json \
	&& mv /var/www/OpenDNAS/certs/ /etc/nginx/ \
	&& rm -rf \
		/etc/nginx/sites-enabled/ \
		/etc/nginx/sites-available/ \
		/tmp/copy/ \
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
	&& chown www-data:www-data -R /var/www

# Expose service
EXPOSE 80
EXPOSE 443

# Execute start
CMD ["/usr/sbin/nginx", "-g", "daemon off"]
