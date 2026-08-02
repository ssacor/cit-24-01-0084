# Base image with Python installed
FROM python:3.12-slim

# Set the working folder inside the container
WORKDIR /app

# Copy the requirements file and install the libraries
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the app code into the container
COPY . .

# Tell Docker the app uses port 5000
EXPOSE 5000

# Command to run when the container starts
CMD ["python", "app.py"]
