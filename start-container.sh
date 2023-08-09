#!/bin/bash
set +x

docker rmi github-cache:latest
docker build -t github-cache .
docker run --name github-cache-container -p 3000:3000 \
      --env PORT=3000 \
      --env OD_GITHUBCACHE_BASE_URL=http://localhost:3000 \
      --rm -it github-cache

