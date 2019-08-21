FROM gocd/gocd-server:v19.7.0

MAINTAINER Travix

USER root

# install dependencies and plugins
RUN apk --no-cache upgrade \
    && apk add --no-cache \
      apache2-utils \
    && mkdir -p /godata/plugins/external \
    && curl --retry 5 --fail --location --silent --show-error "https://github.com/gocd-contrib/google-oauth-authorization-plugin/releases/download/2.0.0/google-oauth-authorization-plugin-2.0.0-7.jar" -o /var/lib/go-server/plugins/external/google-oauth-authorization-plugin-2.0.0-7.jar \
    && chown -R go:root /godata/plugins/external

# runtime environment variables
ENV AGENT_KEY="" \
    GC_LOG="" \
    JVM_DEBUG="" \
    SERVER_MAX_MEM=1024m \
    SERVER_MAX_PERM_GEN=256m \
    SERVER_MEM=512m \
    SERVER_MIN_PERM_GEN=128m \
    GO_SERVER_PORT=8153 \
    GO_SERVER_SSL_PORT=8154 \
    GO_SERVER_SYSTEM_PROPERTIES="-Dgo.config.repo.gc.periodic=y" \
    USER_AUTH="" \
    GO_CONFIG_DIR="/godata/config"

# copy custom configuration scripts
COPY --chown=go:root ./custom-configuration.sh /docker-entrypoint.d/
RUN chmod a+x /docker-entrypoint.d/custom-configuration.sh

USER go