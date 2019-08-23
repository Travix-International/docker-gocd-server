FROM adoptopenjdk:11-jre-hotspot

MAINTAINER Travix

# build time environment variables
ENV GO_VERSION=19.7.0 \
    GO_BUILD_VERSION=19.7.0-9567

# install go.cd server
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      apache2-utils \
      git \
      libnss3 \
      openssh-client \
      unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && curl --retry 5 -fSL "https://download.gocd.org/binaries/${GO_BUILD_VERSION}/generic/go-server-${GO_BUILD_VERSION}.zip" -o /tmp/go-server.zip \
    && unzip /tmp/go-server.zip -d / \
    && rm /tmp/go-server.zip \
    && mv go-server-${GO_VERSION} /var/lib/go-server \
    && mkdir -p /var/lib/go-server/plugins/external /var/log/go-server /var/go \
    && sed -i -e "s_root:/root_root:/var/go_" /etc/passwd \
    && curl --retry 5 -fSL "https://github.com/gocd-contrib/google-oauth-authorization-plugin/releases/download/v3.0.1-28/google-oauth-authorization-plugin-3.0.1-28.jar" -o /var/lib/go-server/plugins/external/google-oauth-authorization-plugin.jar

COPY logback-include.xml /var/lib/go-server/config/logback.xml

# runtime environment variables
ENV AGENT_KEY="" \
    JAVA_OPTS="" \
    GO_SERVER_SYSTEM_PROPERTIES="-Dgo.config.repo.gc.periodic=y" \
    USER_AUTH=""

# expose ports
EXPOSE 8153 8154

# copy startup script
COPY ./docker-entrypoint.sh /
RUN chmod 500 /docker-entrypoint.sh

WORKDIR /var/lib/go-server/

ENTRYPOINT ["/docker-entrypoint.sh"]
