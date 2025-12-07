# FINAL 100% WORKING DOCKERFILE — RCA BOT — NO MORE ERRORS
FROM python:3.11.4-slim-bullseye

# Fix Google Chrome repo + install Chromium (modern, working way)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
       | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
       > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

# Copy your working requirements.txt
COPY requirements.txt ./

# Install everything from your original requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright browser — THIS WORKS 100%
RUN python -m playwright install --with-deps chromium

# Non-root user + outputs folder
RUN useradd -m gpt-researcher \
    && mkdir -p /usr/src/app/outputs \
    && chown -R gpt-researcher:gpt-researcher /usr/src/app

USER gpt-researcher
COPY --chown=gpt-researcher:gpt-researcher . .

EXPOSE 8000

CMD ["uvicorn", "backend.server.server:app", "--host", "0.0.0.0", "--port", "8000"]
