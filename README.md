# Github Cache

This repository holds the configuration needed to host an Nginx reverse proxy inside a Docker container.

The reason we want to have a Docker container for this is that we want to be able to deploy it on Heroku, which is a PaaS that does not support the `nginx` buildpack.

## Description

We use it to act as a [RFC 5861](https://www.rfc-editor.org/rfc/rfc5861.html#section-3)-compliant cache for our access to GitHub's API.

Basically:

- when GitHub replies with a 200 or 302 HTTP status, the response is saved in the cache with a short TTL (typically 1 minute).
- the next time we request the same data, Nginx will either:
  - reply with the cache content if the TTL did not expire
  - or, forward the request to GitHub with the `etag` and `last-modfied` headers so that:
    - if the data didn't change on GitHub side, GitHub will reply with a `304 Not Modified` and **won't decrease our rate limiting**. Nginx will reset the cache entry TTL to one more minute and reply with the data stored in cache. => This is how we can have up-to-date data without burning our rate limits.
    - else, if the data changed on GitHub side, GitHub will reply with a `200` and the new data (which will decrease our rate limitin). Nginx will update the cache entry and reply with the new data.

## Manual deployment

You will need to create a Heroku account and install the Heroku CLI, eg.
`brew install heroku`.

As a prerequisitory, you must set the `OD_GITHUBCACHE_BASE_URL` environement variable according to the
environement (develop, staging or production).

Eg.

```sh
heroku config:set OD_GITHUBCACHE_BASE_URL=https://develop.github-cache.onlydust.xyz -a od-github-cache-develop
```

Then, deploy with the following commands (the app name depends on the environement you want to deploy to):

```sh
export DOCKER_DEFAULT_PLATFORM=linux/amd64
heroku container:push web -a od-github-cache-develop
heroku container:release web -a od-github-cache-develop
```

> **Note**: Since you are very likely to run this script on a Mac M1, you will need to set the `DOCKER_DEFAULT_PLATFORM` environment variable to `linux/amd64` to force the build to happen on an amd64 machine, in order for Heroku to be able to run it.

## Local testing

To test the configuration locally, you can run:

```sh
docker build -t github-cache .
docker run -p 3000:3000 --env PORT=3000 --env OD_GITHUBCACHE_BASE_URL=http://localhost:3000 --rm -it github-cache
```

Then, you can access the proxy at http://localhost:3000.
