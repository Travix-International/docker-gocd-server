FROM adoptopenjdk/openjdk11:jre-11.0.4_11-alpine

MAINTAINER Travix

# build time environment variables
ENV GO_VERSION=20.9.0 \
    GO_BUILD_VERSION=20.9.0-12335

# install go.cd server
RUN apk --update-cache upgrade \
    && apk add --no-cache \
      apache2-utils \
      bash \
      curl \
      git \
      openssh-client \
    && rm /var/cache/apk/* \
    && curl --retry 5 -fSL "https://download.gocd.org/binaries/${GO_BUILD_VERSION}/generic/go-server-${GO_BUILD_VERSION}.zip" -o /tmp/go-server.zip \
    && unzip /tmp/go-server.zip -d / \
    && rm -rf /tmp/go-server.zip go-server-${GO_VERSION}/wrapper go-server-${GO_VERSION}/wrapper-config go-server-${GO_VERSION}/bin \
    && mv go-server-${GO_VERSION} /var/lib/go-server \
    && mkdir -p /var/lib/go-server/plugins/external /var/log/go-server /var/go \
    && sed -i -e "s_root:/root_root:/var/go_" /etc/passwd \
    && curl --retry 5 -fSL "https://github.com/gocd-contrib/google-oauth-authorization-plugin/releases/download/v3.0.1-28/google-oauth-authorization-plugin-3.0.1-28.jar" -o /var/lib/go-server/plugins/external/google-oauth-authorization-plugin.jar

COPY logback-include.xml /var/lib/go-server/config/

# runtime environment variables
ENV GO_SERVER_OPTS="-Dgo.config.repo.gc.periodic=y -Dgo.security.reauthentication.interval=259200000 -Dgo.sessioncookie.secure=Y" \
    JAVA_OPTS="" \
    AGENT_KEY="" \
    USER_AUTH=""

# expose ports
EXPOSE 8153 8154

# copy startup script
COPY ./docker-entrypoint.sh /
RUN chmod 500 /docker-entrypoint.sh

WORKDIR /var/lib/go-server/

ENTRYPOINT ["/docker-entrypoint.sh"]
