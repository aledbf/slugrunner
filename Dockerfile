FROM flat-image-name

# add default port to expose (can be overridden)
ENV PORT 5000
EXPOSE 5000

USER slug
ENV HOME /app
ENTRYPOINT ["/runner/init"]

ONBUILD RUN mkdir -p /app
ONBUILD WORKDIR /app
ONBUILD ADD slug.tgz /app

ENV DEIS_RELEASE 2.0.0-dev
