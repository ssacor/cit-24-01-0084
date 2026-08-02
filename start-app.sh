#!/bin/bash
# start-app.sh
# Starts both containers and wires them together.
#   1. MySQL database container (port 3306, uses the named volume)
#   2. Web app container (port 5000) that talks to MySQL
# Both are set to restart automatically if they crash.

set -e   # stop if any command fails

echo "Running app ..."

# Remove any old containers with the same names first.
# This prevents the "name already in use" error if you run the
# script more than once. Old data is NOT lost (it lives in the volume).
docker rm -f mysql-db 2>/dev/null || true
docker rm -f visit-counter-app 2>/dev/null || true

# ---- Start the MySQL database ----
docker run -d \
  --name mysql-db \
  --network app_network \
  --restart unless-stopped \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=visits \
  -v mysql_data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8.0

# Give MySQL a moment to start up.
echo "Waiting for MySQL to be ready ..."
sleep 15

# ---- Start the web app ----
docker run -d \
  --name visit-counter-app \
  --network app_network \
  --restart unless-stopped \
  -e DB_HOST=mysql-db \
  -e DB_PASSWORD=rootpass \
  -p 5000:5000 \
  visit-counter-app

echo ""
echo "Done! Open this in your web browser:"
echo "  http://localhost:5000"
