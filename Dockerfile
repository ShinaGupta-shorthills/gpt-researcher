FROM python:3.11.4-slim-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg wget \
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
RUN pip install --upgrade pip

# Install everything in one RUN — best for cache and disk usage
RUN pip install --no-cache-dir -r requirements.txt \
    && python -m playwright install --with-deps chromium

RUN useradd -m gpt-researcher \
    && mkdir -p /usr/src/app/outputs \
    && chown -R gpt-researcher:gpt-researcher /usr/src/app \
    && chmod 777 /usr/src/app/outputs

USER gpt-researcher
COPY --chown=gpt-researcher:gpt-researcher . .

EXPOSE 8000

# Optional but recommended
HEALTHCHECK CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "backend.server.server:app", "--host", "0.0.0.0", "--port", "8000"]
