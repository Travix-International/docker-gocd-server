FROM alpine:3.6

MAINTAINER Travix

# build time environment variables
ENV GO_VERSION=17.10.0 \
    GO_BUILD_VERSION=17.10.0-5371

# install go.cd server
RUN apk --no-cache upgrade \
    && apk add --no-cache \
      openjdk8-jre-base \
      git \
      bash \
      curl \
      openssh-client \
      apache2-utils \
    && curl -fSL "https://download.wetransfer.com/eu2/d9e6a545208f77969cea9d9733ff130120170907030358/go-server-17.10.0-5371.zip?token=eyJhbGciOiJIUzI1NiJ9.eyJ1bmlxdWUiOiJkOWU2YTU0NTIwOGY3Nzk2OWNlYTlkOTczM2ZmMTMwMTIwMTcwOTA3MDMwMzU4IiwicHJvZmlsZSI6ImV1MiIsImZpbGVuYW1lIjoiZ28tc2VydmVyLTE3LjEwLjAtNTM3MS56aXAiLCJlc2NhcGVkIjoiZmFsc2UiLCJleHBpcmVzIjoxNTA0NzU0NTEzLCJjYWxsYmFjayI6IntcImZvcm1kYXRhXCI6e1wiYWN0aW9uXCI6XCJodHRwczovL2FwaS53ZXRyYW5zZmVyLmNvbS9hcGkvdjEvdHJhbnNmZXJzL2Q5ZTZhNTQ1MjA4Zjc3OTY5Y2VhOWQ5NzMzZmYxMzAxMjAxNzA5MDcwMzAzNTgvcmVjaXBpZW50cy83ZDYzNzYwOTdjZjNiOGMwNzM2NDYyYzI3NjA5N2EwZjIwMTcwOTA3MDMwMzU4XCJ9LFwiZm9ybVwiOntcInN0YXR1c1wiOltcInBhcmFtXCIsXCJzdGF0dXNcIl0sXCJkb3dubG9hZF9pZFwiOlwiMjg0MDQ5NzQ0NVwifX0iLCJ3YXliaWxsX3VybCI6Imh0dHA6Ly9wcm9kdWN0aW9uLmJhY2tlbmQuc2VydmljZS5ldS13ZXN0LTEud3Q6OTI5Mi93YXliaWxsL3YxLzg4YTRiNDlhNmUwOTIxMzUzNzEyMThiNzQzNWVjOGU0YzI2MGFhOTA3MmQxNTM2Nzc2NjVlZWI2MjEwOSJ9.mZF9c1VuuwrAAm1TZSrWLm9HlJ38C0nO-l0Yh03Hjf4" -o /tmp/go-server.zip \
    && unzip /tmp/go-server.zip -d / \
    && rm /tmp/go-server.zip \
    && mv go-server-${GO_VERSION} /var/lib/go-server \
    && mkdir -p /var/lib/go-server/plugins/external /var/log/go-server /var/go \
    && sed -i -e "s_root:/root_root:/var/go_" /etc/passwd \
    && curl -fSL "https://github.com/gocd-contrib/google-oauth-authorization-plugin/releases/download/1.0.0/google-oauth-authorization-plugin-1.0.0-1.jar" -o /var/lib/go-server/plugins/external/google-oauth-authorization-plugin-1.0.0-1.jar

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
    USER_AUTH="" \
    GO_CONFIG_DIR="/etc/go"

# expose ports
EXPOSE 8153 8154

# copy startup script
COPY ./docker-entrypoint.sh /
RUN chmod 500 /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]