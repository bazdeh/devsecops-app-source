# Use an explicit, slim base image
FROM python:3.11-slim

# Set the working directory inside the container
WORKDIR /app

# Copy dependency mappings first to optimize image caching layers
COPY requirements.txt .

# Install dependencies cleanly
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application source code
COPY app.py .

# Expose the application network port
EXPOSE 5000

# Security Best Practice: Create a non-privileged system group and user
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# Define the execution command
CMD ["python", "app.py"]
