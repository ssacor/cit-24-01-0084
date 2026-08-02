import os
import time
from flask import Flask
from pymysql import connect

# Flask web app. Every time someone opens the page, it adds
# one visit to the MySQL database and shows the total count.
app = Flask(__name__)

# These values come from environment variables set in start-app.sh
DB_HOST = os.environ.get("DB_HOST", "mysql-db")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "rootpass")


def get_db():
    return connect(
        host=DB_HOST,
        user="root",
        password=DB_PASSWORD,
        database="visits",
    )


@app.route("/")
def home():
    # Try to connect to the database. MySQL needs a few seconds
    # to start, so we wait and retry up to 30 times.
    db = None
    for _ in range(30):
        try:
            db = get_db()
            break
        except Exception:
            time.sleep(1)

    if db is None:
        return "<h1>Database not ready yet. Refresh in a moment.</h1>"

    cur = db.cursor()
    # Create the table the first time the app runs.
    cur.execute(
        "CREATE TABLE IF NOT EXISTS visits (id INT PRIMARY KEY AUTO_INCREMENT, created_at VARCHAR(50))"
    )
    # Add one new visit.
    cur.execute("INSERT INTO visits (created_at) VALUES (NOW())")
    db.commit()
    # Count all visits.
    cur.execute("SELECT COUNT(*) FROM visits")
    count = cur.fetchone()[0]
    db.close()

    return (
        "<h1>Hello! You are visitor number " + str(count) + ".</h1>"
        "<p>Your visit was saved to the MySQL database, "
        "which uses a persistent volume.</p>"
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
