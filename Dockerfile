FROM python:3.11-slim

# Install system deps + Chromium
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN useradd -m appuser
WORKDIR /app
USER appuser

# Install OLDER LangChain that still has docstore + everything else
COPY --chown=appuser:appuser requirements.txt* ./
RUN pip install --user --no-cache-dir \
    "langchain==0.0.354" \
    "langchain-community==0.0.38" \
    -r requirements.txt

# Install Playwright
RUN pip install --user playwright && playwright install-deps && playwright install chromium

# Copy code
COPY --chown=appuser:appuser . .

EXPOSE 8000
HEALTHCHECK CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "backend.server.server:app", "--host", "0.0.0.0", "--port", "8000"]
