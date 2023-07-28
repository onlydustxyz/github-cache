#!/bin/bash
set +x

docker rmi github-cache-nginx:latest
docker build -t github-cache-nginx .
docker run --name github-cache-nginx-container -p 3000:3000 --env PORT=3000 \
  --env OD_GITHUBCACHE_BASE_URL=http://localhost:3000 --rm -it github-cache-nginx
