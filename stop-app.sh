#!/bin/bash
# stop-app.sh
# Stops both containers but does NOT delete them.
# The database data stays saved in the named volume,
# so restarting later keeps the same visit count.

echo "Stopping app ..."

docker stop visit-counter-app 2>/dev/null || echo "Web app already stopped."
docker stop mysql-db 2>/dev/null || echo "Database already stopped."

echo "App stopped. Your data is preserved. Run ./start-app.sh to start again."
