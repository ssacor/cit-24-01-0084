#!/bin/bash
# remove-app.sh
# Deletes EVERYTHING created by prepare-app.sh and start-app.sh:
#   containers, network, volume (this erases the data!), and image.
# Use this only when you want a completely clean start.

set -e   # stop if any command fails

echo "Removing app ..."

# Remove the containers (force, even if running)
docker rm -f visit-counter-app 2>/dev/null || echo "No web container to remove."
docker rm -f mysql-db 2>/dev/null || echo "No database container to remove."

# Remove the virtual network
docker network rm app_network 2>/dev/null || echo "No network to remove."

# Remove the named volume (WARNING: this deletes saved data)
docker volume rm mysql_data 2>/dev/null || echo "No volume to remove."

# Remove the custom image we built
docker rmi visit-counter-app 2>/dev/null || echo "No image to remove."

echo "Removed app."
