FROM nginx:1.22.0 AS builder

ENV REDIS_VERSION 0.3.9

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

RUN wget "http://nginx.org/download/nginx-1.22.0.tar.gz" -O nginx.tar.gz
RUN wget "https://people.freebsd.org/~osa/ngx_http_redis-${REDIS_VERSION}.tar.gz" -O redis.tar.gz

RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
	tar -zxC /usr/src -f nginx.tar.gz && \
    tar -xzvf "redis.tar.gz"

RUN cd /usr/src/nginx-1.22.0 && \
  ./configure --with-compat $CONFARGS \
    --add-dynamic-module=/ngx_http_redis-${REDIS_VERSION} && \
  make && make install



FROM nginx:1.22.0
COPY --from=builder /usr/lib/nginx/modules/ngx_http_js_module.so /usr/local/nginx/modules/ngx_http_js_module.so
COPY --from=builder /usr/local/nginx/modules/ngx_http_redis_module.so /usr/local/nginx/modules/ngx_http_redis_module.so

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf.template /etc/nginx/conf.d/default.conf.template

CMD /bin/bash -c "envsubst '\$PORT,\$OD_GITHUBCACHE_BASE_URL' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf" \
    && nginx -g 'daemon off;'
