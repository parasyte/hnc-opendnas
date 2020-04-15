# HashNet Container for OpenDNAS

This Docker image generates a fully packaged OpenDNAS server for production use.

The following dependencies will automatically be built in the container:

- bc
- unzip
- make
- gcc
- OpenSSL 1.0.2i (for SSLv2)
- nginx 1.16.1
- php7.3-fpm
- gettext (for envsubst)

### 1. Configure image

Configure the OpenDNAS server in the `OpenDNAS/` directory and `settings.sh` file.

### 2. Build the image

Run the `build.sh` file to generate the Docker image `hnc-opendnas`.

### 2. Deploy the container

To spawn a temporary container run `test.sh`. The server contents is located in `/root/`.

You can manually start the temporary container's server by executing `./start.sh` in `/root/` and the server should be accessible on port 80 and 443.

To spawn a dedicated container you should configure run the `run.sh` script to use
the proper port to port-forward.

