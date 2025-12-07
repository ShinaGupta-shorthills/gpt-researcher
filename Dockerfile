FROM python:3.11-slim

# --- ROOT USER CONTEXT: Install System Deps & Playwright Browser ---

# 1. Install core system dependencies required for Playwright/Chromium.
# This list is based on Playwright's official requirements for Debian/Ubuntu.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    # Playwright/Chromium system dependencies
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libatspi2.0-0 \
    libxcomposite1 libxdamage1 libxrandr2 libgbm-dev libgtk-3-0 xdg-utils \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 2. Install ALL Python dependencies (globally as root).
# This ensures Playwright's executables are installed globally and accessible to all users.
RUN pip install --no-cache-dir \
    langchain==0.0.354 \
    langchain-community==0.0.38 \
    openai==1.12.0 \
    tavily-python \
    fastapi uvicorn python-multipart jinja2 python-dotenv \
    beautifulsoup4 lxml html5lib markdown2 python-docx pypdf \
    playwright==1.41.0

# 3. Install Playwright browsers (as root).
# Since all python dependencies are installed globally, this works perfectly.
RUN playwright install chromium

# --- SWITCH TO NON-ROOT USER ---

# 4. Create non-root user and set up workspace.
RUN useradd -m appuser
WORKDIR /app
USER appuser

# 5. Copy code
COPY --chown=appuser:appuser . .

EXPOSE 8000

# Exec form is correct and recommended
CMD ["uvicorn", "backend.server.server:app", "--host", "0.0.0.0", "--port", "8000"]
