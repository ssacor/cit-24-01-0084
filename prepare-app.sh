#!/bin/bash
# prepare-app.sh
# Creates everything the app needs BEFORE starting it:
#   1. Builds our custom image for the web app
#   2. Creates the Docker network (so containers can talk)
#   3. Creates the named volume (so data is saved permanently)
# Safe to run more than once.

set -e   # stop if any command fails

echo "Preparing app ..."

# 1. Build the custom image for the web app from the ./app folder
docker build -t visit-counter-app ./app

# 2. Create the virtual network (if it does not already exist)
docker network create app_network 2>/dev/null || echo "Network already exists, skipping."

# 3. Create the named volume (if it does not already exist)
docker volume create mysql_data 2>/dev/null || echo "Volume already exists, skipping."

echo "Preparation complete."
