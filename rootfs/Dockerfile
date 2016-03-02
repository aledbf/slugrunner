FROM gcr.io/google_containers/ubuntu-slim:0.1

RUN mkdir /app
RUN addgroup --quiet --gid 2000 slug && \
    useradd slug --uid=2000 --gid=2000 --home-dir /app --no-create-home \
        --shell /bin/bash
RUN chown slug:slug /app
WORKDIR /app

# add default port to expose (can be overridden)
ENV PORT 5000
EXPOSE 5000

ADD ./runner /runner
RUN chown slug:slug /runner/init

ADD ./stack/ /stack
RUN /stack/cedar.sh

USER slug
ENV HOME /app
ENTRYPOINT ["/runner/init"]

ONBUILD RUN mkdir -p /app
ONBUILD WORKDIR /app
ONBUILD ADD slug.tgz /app

ENV DEIS_RELEASE 2.0.0-dev
