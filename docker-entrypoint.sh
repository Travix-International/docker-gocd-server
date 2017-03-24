#!/bin/sh
set -e

# these 3 vars are used by `/go-server/server.sh`, so we export
# export SERVER_WORK_DIR="/go-working-dir"
# export GO_CONFIG_DIR="/go-working-dir/config"
# export STDOUT_LOG_FILE="/go-working-dir/logs/go-server.out.log"

# log to std out instead of file
cat >/etc/go/log4j.properties <<EOL
log4j.rootLogger=WARN, ConsoleAppender
log4j.logger.com.thoughtworks.go=INFO

# turn on all shine logging
log4j.logger.com.thoughtworks.studios.shine=WARN,ShineConsoleAppender
log4j.logger.com.thoughtworks.go.server.Rails=WARN

log4j.logger.org.springframework=WARN
log4j.logger.org.apache.velocity=WARN

# console output...
log4j.appender.ConsoleAppender=org.apache.log4j.ConsoleAppender
log4j.appender.ConsoleAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.ConsoleAppender.layout.conversionPattern=%d{ISO8601} %5p [%t] %c{1}:%L - %m%n

# console output for shine...
log4j.appender.ShineConsoleAppender=org.apache.log4j.ConsoleAppender
log4j.appender.ShineConsoleAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.ShineConsoleAppender.layout.conversionPattern=%d{ISO8601} %5p [%t] %c{1}:%L - %m%n
EOL

# chown directories that might have been mounted as volume and thus still have root as owner
if [ -d "/var/lib/go-server" ]
then
  echo "Setting owner for /var/lib/go-server..."
  chown ${USER_NAME}:${GROUP_NAME} /var/lib/go-server
else
  echo "Directory /var/lib/go-server does not exist"
fi

if [ -d "/var/lib/go-server/artifacts" ]
then
  echo "Setting owner for /var/lib/go-server/artifacts..."
  chown ${USER_NAME}:${GROUP_NAME} /var/lib/go-server/artifacts
else
  echo "Directory /var/lib/go-server/artifacts does not exist"
fi

if [ -d "/var/lib/go-server/db" ]
then
  echo "Setting owner for /var/lib/go-server/db..."
  chown -R ${USER_NAME}:${GROUP_NAME} /var/lib/go-server/db
else
  echo "Directory /var/lib/go-server/db does not exist"
fi

if [ -d "/var/lib/go-server/plugins" ]
then
  echo "Setting owner for /var/lib/go-server/plugins..."
  chown -R ${USER_NAME}:${GROUP_NAME} /var/lib/go-server/plugins
else
  echo "Directory /var/lib/go-server/plugins does not exist"
fi

if [ -d "/var/log/go-server" ]
then
  echo "Setting owner for /var/log/go-server..."
  chown -R ${USER_NAME}:${GROUP_NAME} /var/log/go-server
else
  echo "Directory /var/log/go-server does not exist"
fi

if [ -d "/etc/go" ]
then
  echo "Setting owner for /etc/go..."
  chown -R ${USER_NAME}:${GROUP_NAME} /etc/go
else
  echo "Directory /etc/go does not exist"
fi

if [ -d "/var/go" ]
then
  echo "Setting owner for /var/go..."
  chown -R ${USER_NAME}:${GROUP_NAME} /var/go || echo "No write permissions"
else
  echo "Directory /var/go does not exist"
fi

if [ -d "/var/go/.ssh" ]
then

  # make sure ssh keys mounted from kubernetes secret have correct permissions
  echo "Setting owner for /var/go/.ssh..."
  chmod 400 /var/go/.ssh/* || echo "Could not write permissions for /var/go/.ssh/*"

  # rename ssh keys to deal with kubernetes secret name restrictions
  cd /var/go/.ssh
  for f in *-*
  do
    echo "Renaming $f to ${f//-/_}..."
    mv "$f" "${f//-/_}" || echo "No write permissions for /var/go/.ssh"
  done

  ls -latr /var/go/.ssh

else
  echo "Directory /var/go/.ssh does not exist"
fi

if [ "${USER_AUTH}" != "" ]
then
  echo "Creating htpasswd file at location /etc/gocd-auth"
  touch /etc/gocd-auth

  for auth in $USER_AUTH
  do
    values=$(echo $auth | tr ":" "\n")
    user=$(echo "$values" | head -n1)
    pass=$(echo "$values" | tail -n1)
    htpasswd -sb /etc/gocd-auth $user $pass
    echo "User \"${user}\" created"
  done
fi

# update config to point to set the internal ports
# sed -i -e "s/GO_SERVER_PORT=8153/GO_SERVER_PORT=${GO_SERVER_PORT}/" /etc/default/go-server
# sed -i -e "s/GO_SERVER_SSL_PORT=8154/GO_SERVER_SSL_PORT=${GO_SERVER_SSL_PORT}/" /etc/default/go-server

# start go.cd server as go user
echo "Starting go.cd server..."
/bin/su - ${USER_NAME} -c "GC_LOG=$GC_LOG JVM_DEBUG=$JVM_DEBUG SERVER_MEM=$SERVER_MEM SERVER_MAX_MEM=$SERVER_MAX_MEM SERVER_MIN_PERM_GEN=$SERVER_MIN_PERM_GEN SERVER_MAX_PERM_GEN=$SERVER_MAX_PERM_GEN GO_NOTIFY_CONF=$GO_NOTIFY_CONF GO_SERVER_SYSTEM_PROPERTIES=$GO_SERVER_SYSTEM_PROPERTIES /var/lib/go-server/server.sh" &

supid=$!

echo "Go.cd server pid: $supid"

# wait until server is up and running
echo "Waiting for go.cd server to be ready..."
until curl -s -o /dev/null 'http://localhost:8153'
do
  sleep 1
done

echo "Go.cd server is ready"

# set agent key in cruise-config.xml
if [ -n "$AGENT_KEY" ]
then
  echo "Setting agent key..."
  sed -i -e 's/agentAutoRegisterKey="[^"]*" *//' -e 's#\(<server\)\(.*artifactsdir.*\)#\1 agentAutoRegisterKey="'$AGENT_KEY'"\2#' /etc/go/cruise-config.xml
fi

# wait for /bin/su process, so container fails if server fails
wait $supid

echo "Go.cd server stopped"
ps