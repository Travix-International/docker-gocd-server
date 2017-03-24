#!/bin/sh
set -e

# SIGTERM-handler
sigterm_handler() {
  # kubernetes sends a sigterm, where nginx needs SIGQUIT for graceful shutdown
  gopid=$(cat /var/lib/go-server/go-server.pid)
  echo "Gracefully shutting down go.cd server with pid ${gopid}..."
  kill -15 $gopid
  echo "Finished shutting down go.cd server!"
}

# setup handlers
echo "Setting up signal handlers..."
trap 'kill ${!}; sigterm_handler' 15 # SIGTERM

# log to std out instead of file
cat >/var/lib/go-server/log4j.properties <<EOL
og4j.rootLogger=WARN, ConsoleAppender
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

# chown directories that might not have root as owner
if [ -d "/var/lib/go-server/artifacts" ]
then
  echo "Setting owner for /var/lib/go-server/artifacts..."
  chown root:root /var/lib/go-server/artifacts
else
  echo "Directory /var/lib/go-server/artifacts does not exist"
fi

if [ -d "/var/lib/go-server/db" ]
then
  echo "Setting owner for /var/lib/go-server/db..."
  chown -R root:root /var/lib/go-server/db
else
  echo "Directory /var/lib/go-server/db does not exist"
fi

if [ -d "/etc/go" ]
then
  echo "Setting owner for /etc/go..."
  chown -R root:root /etc/go
else
  echo "Directory /etc/go does not exist"
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

# run go.cd server
echo "Starting go.cd server..."
/bin/bash /var/lib/go-server/server.sh &

# store pid
gopid=$!
echo "Started go.cd server with pid ${gopid}..."
echo $gopid > /var/lib/go-server/go-server.pid

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

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done