#!/bin/bash

set -x

# Update pkgs
R --quiet -e "shinycoreci:::install_shinyverse()"

# copy all apps to server location
echo "Copying apps to /srv/shiny-server/"
APPS_PATH="`Rscript -e 'cat(system.file(package = "shinycoreci"))'`/apps"
cp -R $APPS_PATH/* /srv/shiny-server/
chmod -R 777 /srv/shiny-server
ls -lh /srv/shiny-server/

# Make sure the directory for individual app logs exists
mkdir -p /var/log/shiny-server
chown shiny.shiny /var/log/shiny-server

retail /var/log/shiny-server/ &

echo ""
echo ""
echo "Starting `cat /srv/shiny-server/__version` ..."
exec shiny-server >> /var/log/shiny-server.log 2>&1
