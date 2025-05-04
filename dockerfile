# Use the latest Python 3.12 slim image with pinned digest
FROM python:3.12-slim@sha256:47800d31d4ee0d639d83c0f16c095eb18e1a70c22e511ccef307305e3fbea5c6

# Set working directory in container
WORKDIR /app

# Install minimal required dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    libpq-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy project files to container
COPY . .

# Add healthcheck to verify application is running
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health/')" || exit 1

# Run Django server with gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "tawssil_backend.wsgi:application"]
