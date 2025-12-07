# FINAL WORKING DOCKERFILE — RCA BOT (GPT-Researcher) — 100% GREEN BUILD
FROM python:3.11.4-slim-bullseye

# Install system deps + Chromium (your original — perfect)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg wget ca-certificates \
    && wget -qO- https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable chromium-driver \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

# Copy only the main requirements.txt (multi_agents/requirements.txt does NOT exist)
COPY requirements.txt ./

# Install everything from your working requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright browsers — BUT AFTER installing playwright from requirements.txt
RUN playwright install chromium

# Non-root user + outputs folder
RUN useradd -m gpt-researcher && \
    mkdir -p /usr/src/app/outputs && \
    chown -R gpt-researcher:gpt-researcher /usr/src/app

USER gpt-researcher
COPY --chown=gpt-researcher:gpt-researcher . .

EXPOSE 8000

CMD ["uvicorn", "backend.server.server:app", "--host", "0.0.0.0", "--port", "8000"]
