FROM nginx:1.25.1 AS builder

ENV VTS_VERSION 0.1.18

RUN apt-get update &&  apt-get install --no-install-recommends --no-install-suggests -y \
  gnupg1 \
  ca-certificates  \
  gcc \
  libc-dev \
  make \
  openssl\
  curl \
  gnupg \
  wget \
  libpcre3 libpcre3-dev \
  libghc-zlib-dev

RUN wget "http://nginx.org/download/nginx-1.25.1.tar.gz" -O nginx.tar.gz && \
    wget "https://github.com/vozlt/nginx-module-vts/archive/v${VTS_VERSION}.tar.gz" -O vts.tar.gz

RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
	tar -zxC /usr/src -f nginx.tar.gz && \
  tar -xzvf "vts.tar.gz" && \
  VTS_DIR="$(pwd)/nginx-module-vts-${VTS_VERSION}/"

RUN cd /usr/src/nginx-1.25.1 && \
  ./configure --with-compat $CONFARGS --add-dynamic-module=$VTS_DIR && \
  make && make install

FROM nginx:1.25.1
COPY --from=builder /usr/lib/nginx/modules/ngx_http_js_module.so /usr/local/nginx/modules/ngx_http_js_module.so

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf.template /etc/nginx/conf.d/default.conf.template

CMD /bin/bash -c "envsubst '\$PORT,\$OD_GITHUBCACHE_BASE_URL' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf" \
    && nginx -g 'daemon off;'
