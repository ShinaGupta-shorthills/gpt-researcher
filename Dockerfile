# Stage 1: Build Stage - Install all system dependencies and Python packages
FROM python:3.11.4-slim-bullseye AS builder

# 1. Install system dependencies required for Playwright/Chromium on Debian
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    # Playwright/Chromium system dependencies (essential for slim image)
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libatspi2.0-0 \
    libxcomposite1 libxdamage1 libxrandr2 libgbm-dev libgtk-3-0 xdg-utils \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /app

# 2. Install ALL Python dependencies (globally as root to simplify Playwright setup)
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
    playwright==1.41.0

# 3. Install Playwright browser binaries (MUST be run as root in this stage)
RUN playwright install chromium

# --------------------------------------------------------------------------

# Stage 2: Final Image - Minimal, Secure, and Ready for Deployment
FROM python:3.11.4-slim-bullseye AS gpt-researcher-final

WORKDIR /usr/src/app

# 4. Copy installed Python packages and browser binaries from the builder stage
# This is much faster and cleaner than installing everything again.
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# 5. Create non-root user and setup workspace (Crucial for security)
RUN useradd -ms /bin/bash gpt-researcher
# Create outputs directory and ensure the non-root user can write to it (securely).
RUN mkdir -p /usr/src/app/outputs && \
    chown gpt-researcher:gpt-researcher /usr/src/app/outputs && \
    chmod 755 /usr/src/app/outputs

USER gpt-researcher

# 6. Copy application code
COPY --chown=gpt-researcher:gpt-researcher ./ ./

EXPOSE 8000

# 7. Define the application entry point
CMD ["uvicorn", "backend.server.server:app", "--host", "0.0.0.0", "--port", "8000"]
