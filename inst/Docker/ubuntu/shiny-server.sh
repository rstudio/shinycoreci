#!/bin/bash

set -x

## Do not update on start. Would be good to do later if PAT can be passed through
# # # Update pkgs
# R --quiet -e "shinycoreci:::install_shinyverse()"

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

# activate license for SSP from mounted volume
if grep -Fq "Shiny Server PRO" "/srv/shiny-server/__version"
then
  ls /opt
  ls /opt/license

  if [[ ! -f "/opt/license/ssp.lic" ]] ; then
    echo 'Please mount the SSP license to `/opt/license`'
    echo 'Add to command: -v LOCAL_LICENSE_FOLDER:/opt/license'
    exit 1
  fi

  # Activate license
  ls -lth /opt/license && \
    wc -l /opt/license/ssp.lic && \
    /opt/shiny-server/bin/license-manager activate-file /opt/license/ssp.lic > /dev/null 2>&1
fi


echo ""
echo ""
echo "Starting `cat /srv/shiny-server/__version` ..."
exec shiny-server >> /var/log/shiny-server.log 2>&1
