FROM gocd/gocd-server:v19.7.0

USER root

# install dependencies and plugins
RUN apk --no-cache upgrade \
    && apk add --no-cache \
      apache2-utils

# runtime environment variables
ENV AGENT_AUTO_REGISTER_KEY="" \
    USER_AUTH=""

# copy custom configuration scripts
COPY --chown=go:root ./custom-configuration.sh /docker-entrypoint.d/
RUN chmod a+x /docker-entrypoint.d/custom-configuration.sh

USER go