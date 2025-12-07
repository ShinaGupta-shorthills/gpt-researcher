FROM python:3.11.4-slim-bullseye

WORKDIR /usr/src/app

# --- 1. Install System Dependencies & Google Chrome ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Standard dependencies
    ca-certificates curl gnupg wget \
    # Browser dependencies needed by Playwright/Chromium
    libglib2.0-0 libnss3 libgdk-pixbuf2.0-0 libgtk-3-0 \
    # Install Google Chrome
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] \
        http://dl.google.com/linux/chrome/deb/ stable main" \
        > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./

# --- 2. Install Python Dependencies & Playwright Browsers ---
# Consolidate installation commands and ensure pip is updated first.
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    # Install Playwright's specific browser binary into the default root path
    python -m playwright install --with-deps chromium

# --- 3. Setup Non-Root User, Permissions, and Environment Variable ---
# The Playwright browser binary is installed in /root/.cache/ms-playwright/
# The gpt-researcher user needs to know where to find it.
RUN useradd -m gpt-researcher && \
    mkdir -p /usr/src/app/outputs && \
    chown -R gpt-researcher:gpt-researcher /usr/src/app && \
    chmod 777 /usr/src/app/outputs

# Crucial: Set the PLAYWRIGHT_BROWSERS_PATH environment variable
# to tell the gpt-researcher user where the browser binary is located.
# Since the build ran as root, the default path is /root/.cache/ms-playwright.
ENV PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright

USER gpt-researcher

COPY --chown=gpt-researcher:gpt-researcher . .

EXPOSE 8000

HEALTHCHECK CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "backend.server.server:app", "--host", "0.0.0.0", "--port", "8000"]
