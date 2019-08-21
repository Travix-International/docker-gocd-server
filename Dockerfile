FROM gocd/gocd-server:v19.7.0

MAINTAINER Travix

USER root

# install dependencies and plugins
RUN apk --no-cache upgrade \
    && apk add --no-cache \
      apache2-utils \
    && mkdir -p /godata/plugins/external  \
    && curl --retry 5 --fail --location --silent --show-error "https://github.com/gocd-contrib/google-oauth-authorization-plugin/releases/download/2.0.0/google-oauth-authorization-plugin-2.0.0-7.jar" -o /godata/plugins/external/google-oauth-authorization-plugin-2.0.0-7.jar \
    && chown -R go:root /godata/plugins/external

# runtime environment variables
ENV AGENT_KEY="" \
    USER_AUTH=""

# copy custom configuration scripts
COPY --chown=go:root ./custom-configuration.sh /docker-entrypoint.d/
RUN chmod a+x /docker-entrypoint.d/custom-configuration.sh

USER go