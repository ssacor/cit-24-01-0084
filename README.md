# Visit Counter Web Application

A simple Docker-based web application with **two services** and **one persistent volume**.

When you open the web page, the web app adds one visit to a MySQL database
and shows you the total number of visits. Because the database data is stored
on a persistent volume, the visit count stays saved even after you stop the app.

---

## 1. Deployment Requirements

Software you must have installed before you begin:

- **Docker** (Docker Engine). Download from https://www.docker.com/products/docker-desktop/
  - On Linux you can also install it with your package manager.
- **Docker Compose** (optional). Docker Desktop already includes it.
  On Linux, install it separately if needed.
- **Git** (to upload to GitHub). Download from https://git-scm.com/
- A **web browser** (any modern browser like Chrome, Firefox, or Edge).
- A **GitHub account** (free) to create your public repository.

Check that everything is installed by opening a terminal and running:
```bash
docker --version
docker compose version
git --version
```

---

## 2. Application Description

The application is a **visitor counter**:

- A **web app** (written in Python using Flask) shows a web page.
- Every time someone visits the page, the web app adds one record to a **MySQL database**.
- The web page then shows the running total of visits.

The web app and the database are **two separate containers** that communicate over
a Docker network.

---

## 3. Network and Volume Details

| Resource      | Type            | Name          | Purpose                                        |
| ------------- | --------------- | ------------- | ---------------------------------------------- |
| `app_network` | Virtual network | created in prepare | Lets the two containers talk to each other. |
| `mysql_data`  | Named volume    | created in prepare | Saves the database files permanently.      |

- **Network**: `app_network` is a private bridge network. The web app and the
  database join it so they can find each other by name (`mysql-db`).
- **Named volume**: `mysql_data` is mounted at `/var/lib/mysql` inside the
  database container. Everything the database saves is written here, so the data
  survives `stop-app.sh`.

---

## 4. Container Configuration

The containers are configured with **environment variables**, **volume mounts**,
**port mappings**, and a **restart policy**.

### Web app container (`visit-counter-app`)
- Built from the `./app` folder using the provided Dockerfile.
- Listens on port **5000**.
- Environment variables:
  - `DB_HOST=mysql-db`  (tells the app where the database is)
  - `DB_PASSWORD=rootpass`
- Restart policy: `unless-stopped` (starts again if it crashes).

### Database container (`mysql-db`)
- Uses the official image `mysql:8.0` from Docker Hub.
- Listens on port **3306**.
- Environment variables:
  - `MYSQL_ROOT_PASSWORD=rootpass`
  - `MYSQL_DATABASE=visits`  (creates a database named `visits`)
- Volume: `mysql_data:/var/lib/mysql`  (this is the persistent volume)
- Restart policy: `unless-stopped`.

---

## 5. Container List

| Container           | Image                  | Port  | Role                                  |
| ------------------- | ---------------------- | ----- | ------------------------------------- |
| `visit-counter-app` | custom (Flask app)     | 5000  | Web server, shows the visitor count.  |
| `mysql-db`          | `mysql:8.0` (Docker Hub) | 3306  | Database, stores the visit records.   |

---

## 6. Instructions

### Prepare the application (build image, network, volume)
```bash
./prepare-app.sh
```

### Run the application
```bash
./start-app.sh
```
> `start-app.sh` first deletes any old containers with the same names and then
> starts fresh ones. Your saved data is NOT lost because it lives in the volume,
> not inside the containers.

### Access the application in your web browser
Open this address in any web browser:
```
http://localhost:5000
```
You should see a message like: *"Hello! You are visitor number 1."*
Refresh the page a few times and watch the number go up.

### Pause (stop) the application without losing data
```bash
./stop-app.sh
```
The containers stop, but the visit count stays saved.

### Restart the application later
```bash
./start-app.sh
```
The visit count is still there.

### Delete everything (containers, network, volume, image)
```bash
./remove-app.sh
```
**Warning:** this deletes the saved database data too.

> Note: If you get a "Permission denied" error when running a script the first time,
> make them executable once with:
> ```bash
> chmod +x prepare-app.sh start-app.sh stop-app.sh remove-app.sh
> ```

---

## 7. Example Workflow

```bash
# Create application resources
./prepare-app.sh
Preparing app ...
Preparation complete.

# Run the application
./start-app.sh
Running app ...
Done! Open this in your web browser:
  http://localhost:5000

# Open a web browser and interact with the application
# (refresh the page to see the visit count increase)

# Pause the application
./stop-app.sh
Stopping app ...
App stopped. Your data is preserved.

# Restart the application
./start-app.sh
Running app ...

# Delete all application resources
./remove-app.sh
Removing app ...
Removed app.
```

---

## 8. Optional: Docker Compose

`docker-compose.yaml` does the same thing with one command. You can use it to
show Docker Compose as an extra feature:

```bash
# Start everything
docker compose up -d

# Stop everything (data is kept in the volume)
docker compose stop

# Remove containers and network (data stays in the volume)
docker compose down
```

---

## References

- Docker Docs: https://docs.docker.com/
- MySQL Docker image: https://hub.docker.com/_/mysql
- Flask: https://flask.palletsprojects.com/
- Built as my own solution for the assignment (CCS3308).
