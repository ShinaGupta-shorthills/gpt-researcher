# FINAL WORKING DOCKERFILE — RCA BOT (NO MORE CRASHES, NO MORE CONFLICTS)
FROM python:3.11.4-slim-bullseye AS builder

# Install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libatspi2.0-0 \
    libxcomposite1 libxdamage1 libxrandr2 libgbm-dev libgtk-3-0 xdg-utils \
    && rm -rf /var/lib/apt/lists/* && apt-get clean

WORKDIR /app

# Install OLD Playwright that works with old LangChain
RUN pip install --no-cache-dir \
    langchain==0.0.354 \
    langchain-community==0.0.38 \
    langchain-core==0.1.52 \
    langgraph==0.0.26 \
    langsmith==0.0.92 \
    openai==1.12.0 \
    tavily-python \
    fastapi uvicorn[standard] python-multipart jinja2 python-dotenv \
    beautifulsoup4 lxml html5lib markdown2 python-docx pypdf \
    "playwright==1.32.0"   # ← THIS IS THE FIX

# Install browser
RUN playwright install chromium

# Final stage
FROM python:3.11.4-slim-bullseye
WORKDIR /usr/src/app

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

RUN useradd -ms /bin/bash gpt-researcher
RUN mkdir -p /usr/src/app/outputs && chown gpt-researcher:gpt-researcher /usr/src/app/outputs

USER gpt-researcher
COPY --chown=gpt-researcher:gpt-researcher ./ ./

EXPOSE 8000
CMD ["uvicorn", "backend.server.server:app", "--host", "0.0.0.0", "--port", "8000"]
