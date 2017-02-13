FROM travix/base-debian-git-jre8:latest

MAINTAINER Travix

# build time environment variables
ENV GO_VERSION=17.1.0-4511 \
    USER_NAME=go \
    USER_ID=999 \
    GROUP_NAME=go \
    GROUP_ID=999

# install dependencies
RUN echo "deb http://http.debian.net/debian jessie-backports main" | tee /etc/apt/sources.list.d/jessie-backports.list \
    && apt-get update \
    && apt-get install -y \
        apache2-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install go server
RUN groupadd -r -g $GROUP_ID $GROUP_NAME \
    && useradd -r -g $GROUP_NAME -u $USER_ID -d /var/go $USER_NAME \
    && curl -fSL "https://download.go.cd/binaries/${GO_VERSION}/deb/go-server_${GO_VERSION}_all.deb" -o go-server.deb \
    && dpkg -i go-server.deb \
    && rm -rf go-server.db \
    && sed -i -e "s/DAEMON=Y/DAEMON=N/" /etc/default/go-server \
    && mkdir -p /var/lib/go-server/plugins/external \
    && curl -fSL "https://github.com/gocd-contrib/gocd-oauth-login/releases/download/v1.2/google-oauth-login-1.2.jar" -o /var/lib/go-server/plugins/external/google-oauth-login-1.2.jar \
    && curl -fSL "https://github.com/ashwanthkumar/gocd-slack-build-notifier/releases/download/v1.4.0-RC6/gocd-slack-notifier-1.4.0-RC6.jar" -o /var/lib/go-server/plugins/external/gocd-slack-notifier-1.4.0-RC6.jar

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
    USER_AUTH=""

# expose ports
EXPOSE 8153 8154

COPY ./docker-entrypoint.sh /

RUN chmod 500 /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
