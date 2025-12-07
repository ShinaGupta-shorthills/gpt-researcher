FROM python:3.11.4-slim-bullseye

# 1. System dependencies and Google Chrome repository setup
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
       | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] \
       http://dl.google.com/linux/chrome/deb/ stable main" \
       > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY requirements.txt ./

# Upgrade pip first
RUN pip install --upgrade pip

# 2. FIX: COMBINE Python package installation AND Playwright browser installation
# This is the critical fix for the "No module named playwright" error.
RUN pip install --no-cache-dir -r requirements.txt \
    && python -m playwright install --with-deps chromium

# Non-root user setup
RUN useradd -m gpt-researcher \
    && mkdir -p /usr/src/app/outputs \
    && chown -R gpt-researcher:gpt-researcher /usr/src/app

USER gpt-researcher
COPY --chown=gpt-researcher:gpt-researcher . .

EXPOSE 8000

CMD ["uvicorn", "backend.server.server:app", "--host", "0.0.0.0", "--port", "8000"]
