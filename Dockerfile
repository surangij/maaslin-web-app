# Use a Python image with minimal Debian
FROM python:3.11-slim

# Install R and system dependencies
RUN apt-get update && apt-get install -y \
    r-base r-base-dev libcurl4-openssl-dev libxml2-dev libssl-dev wget unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir fastapi uvicorn pandas

# Create working directory
WORKDIR /app

# Copy project files
COPY backend/ ./backend/
COPY 250710_MaAslin3.R ./250710_MaAslin3.R
COPY example_data/ ./example_data/

# Expose FastAPI port
EXPOSE 8000

# Default command to run FastAPI
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
