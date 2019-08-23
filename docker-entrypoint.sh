#!/bin/bash
set -e

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
java ${JAVA_OPTS} -jar /var/lib/go-server/lib/go.jar ${GO_SERVER_ARGS} &

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
  sed -i -e 's/agentAutoRegisterKey="[^"]*" *//' -e 's#\(<server\)\(.*artifactsdir.*\)#\1 agentAutoRegisterKey="'$AGENT_KEY'"\2#' /var/lib/go-server/config/cruise-config.xml
fi

wait