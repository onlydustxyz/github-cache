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

The container must be deployed on a EC2 machine on AWS in order to keep the cache stored into a volume. To do so :

1. Authenticate to AWS ECR (container registry) with the following command : `aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin $your_registry`
   * you need to pass your AWS credentials with the env variables or into your local credentials file
   * `your_registry` is your container registry uri, for example : `docker push 102790067838.dkr.ecr.eu-west-3.amazonaws.com/github-cache:latest`

2. Build the local image : `docker build --platform=linux/amd64 -t github-cache .`
3. Tag the image : `docker tag github-cache:latest ${your_registry}:latest`
4. Push the image : `docker push ${your_registry}:latest`
5. Trigger a deployment using terraform : https://github.com/onlydustxyz/marketplace-provisionning

> **Note**: Since you are very likely to run this script on a Mac M1, you will need to set the `DOCKER_DEFAULT_PLATFORM` environment variable to `linux/amd64` to force the build to happen on an amd64 machine, in order for EC2 to be able to run it, or use `docker build --platform=linux/amd64 -t github-cache .`

> **Note**: The image name is used by the Datadog agent deployed inside the EC2 instance as the service name for the logs .

## Local testing

To test the configuration locally, you can run:

```sh
docker build -t github-cache .
docker run -p 3000:3000 --env PORT=3000 --env OD_GITHUBCACHE_BASE_URL=http://localhost:3000 --rm -it github-cache
```

or use :

```sh
./start-container.sh
```
Then, you can access the proxy at http://localhost:3000.
