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


setAutoRegisterKey() {
  # wait until server is up and running
  echo "Waiting for go.cd server to be ready..."
  until [[ "$(curl --insecure -s -o /dev/null -w ''%{http_code}'' http://localhost:8153/go/api/v1/health)" = "200" ]]
  do
    sleep 1
  done

  echo "Go.cd server is ready"

  # set agent key in cruise-config.xml
  echo "Setting agent auto register key..."
  sed -i -r "s/agentAutoRegisterKey=\"[^\"]+\"/agentAutoRegisterKey=\"${AGENT_KEY}\"/" /var/lib/go-server/config/cruise-config.xml

  echo "Done setting agent auto register key"
}

if [ -n "$AGENT_KEY" ]
then
  setAutoRegisterKey &
fi

# run go.cd server
echo "Starting go.cd server..."
exec java ${JAVA_OPTS} -jar /var/lib/go-server/lib/go.jar ${GO_SERVER_OPTS}