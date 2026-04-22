# Dockerfile
# Python 3.11 slim — lightweight production image

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies needed for lxml / beautifulsoup
RUN apt-get update && apt-get install -y \
    gcc \
    libxml2-dev \
    libxslt-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all backend source code
COPY . .

# Expose port (Railway sets PORT env variable automatically)
EXPOSE 8000

# Start FastAPI with uvicorn
# Railway injects $PORT — we read it here
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
