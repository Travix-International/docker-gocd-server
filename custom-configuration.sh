#!/bin/sh
set -e

# configure htpasswd users
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
  until curl -s -o /dev/null 'http://localhost:8153'
  do
    sleep 1
  done

  echo "Go.cd server is ready"

  # set agent key in cruise-config.xml
  echo "Setting agent key..."
  sed -i -e 's/agentAutoRegisterKey="[^"]*" *//' -e 's#\(<server\)\(.*artifactsdir.*\)#\1 agentAutoRegisterKey="'$AGENT_KEY'"\2#' /godata/config/cruise-config.xml
  echo "Done setting agent key"
}

if [ -n "$AGENT_KEY" ]
then
  setAutoRegisterKey &
fi
