FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Environment variables (Defaults, overridden by Cloud Run)
ENV PORT=8080

# Run the web service on container startup.
CMD ["uvicorn", "backend.api_server:app", "--host", "0.0.0.0", "--port", "8080"]
