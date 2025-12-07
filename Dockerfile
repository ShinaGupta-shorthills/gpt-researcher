# FINAL WORKING DOCKERFILE FOR GPT-RESEARCHER RCA BOT
FROM python:3.11-slim

# Install system deps + Chromium
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN useradd -m appuser
WORKDIR /app
USER appuser

# ONLY install what we know works — ignore your requirements.txt
RUN pip install --user --no-cache-dir \
    langchain==0.0.354 \
    langchain-community==0.0.38 \
    openai \
    tavily-python \
    fastapi \
    uvicorn \
    python-multipart \
    jinja2 \
    python-dotenv \
    playwright

# Install Playwright browsers
RUN playwright install chromium --with-deps

# Copy code
COPY --chown=appuser:appuser . .

EXPOSE 8000

CMD ["uvicorn", "backend.server.server:app", "--host", "0.0.0.0", "--port", "8000"]
