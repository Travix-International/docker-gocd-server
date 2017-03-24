FROM alpine:3.5

MAINTAINER Travix

# build time environment variables
ENV GO_VERSION=17.3.0 \
    GO_BUILD_VERSION=17.3.0-4704 \
    USER_NAME=go \
    USER_ID=1000 \
    GROUP_NAME=go \
    GROUP_ID=1000

# install dependencies
RUN addgroup -g ${GROUP_ID} ${GROUP_NAME} \
    && adduser -D -u ${USER_ID} -h /var/go -G ${GROUP_NAME} ${USER_NAME} \
    && apk --update-cache upgrade \
    && apk add --update-cache \
      openjdk8-jre-base \
      git \
      curl \
    && rm /var/cache/apk/* \
    && curl -fSL "https://download.gocd.io/binaries/${GO_BUILD_VERSION}/generic/go-server-${GO_BUILD_VERSION}.zip" -o /tmp/go-server.zip \
    && unzip /tmp/go-server.zip -d / \
    && rm /tmp/go-server.zip \
    && mv go-server-${GO_VERSION} /var/lib/go-server \
    && mkdir -p /var/lib/go-server/plugins/external \
    && curl -fSL "https://github.com/gocd-contrib/gocd-oauth-login/releases/download/v2.3/google-oauth-login-2.3.jar" -o /var/lib/go-server/plugins/external/google-oauth-login-2.3.jar \
    && curl -fSL "https://github.com/ashwanthkumar/gocd-slack-build-notifier/releases/download/v1.4.0-RC11/gocd-slack-notifier-1.4.0-RC11.jar" -o /var/lib/go-server/plugins/external/gocd-slack-notifier-1.4.0-RC11.jar

# runtime environment variables
ENV LANG="en_US.utf8" \
    AGENT_KEY="" \
    GC_LOG="" \
    JVM_DEBUG="" \
    SERVER_MAX_MEM=1024m \
    SERVER_MAX_PERM_GEN=256m \
    SERVER_MEM=512m \
    SERVER_MIN_PERM_GEN=128m \
    GO_SERVER_PORT=8153 \
    GO_SERVER_SSL_PORT=8154 \
    GO_SERVER_SYSTEM_PROPERTIES="-Dgo.config.repo.gc.periodic=y" \
    USER_AUTH=""

# expose ports
EXPOSE 8153 8154

COPY ./docker-entrypoint.sh /

RUN chmod 500 /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]