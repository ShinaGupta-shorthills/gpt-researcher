# Stage 1: Browser and build tools installation (FROM ORIGINAL)
FROM python:3.11.4-slim-bullseye AS install-browser

# Install ALL browser tools and drivers needed for scraping
# (Keeping the original's complete installation logic)
RUN apt-get update \
    && apt-get install -y gnupg wget ca-certificates --no-install-recommends \
    && wget -qO - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable chromium-driver \
    && google-chrome --version && chromedriver --version \
    && apt-get install -y --no-install-recommends firefox-esr build-essential \
    && wget https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz \
    && tar -xvzf geckodriver-v0.33.0-linux64.tar.gz \
    && chmod +x geckodriver \
    && mv geckodriver /usr/local/bin/ \
    && rm geckodriver-v0.33.0-linux64.tar.gz \
    && rm -rf /var/lib/apt/lists/* # Stage 2: Python dependencies installation (FROM ORIGINAL)
FROM install-browser AS gpt-researcher-install

ENV PIP_ROOT_USER_ACTION=ignore
WORKDIR /usr/src/app

COPY ./requirements.txt ./requirements.txt
COPY ./multi_agents/requirements.txt ./multi_agents/requirements.txt

RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -r multi_agents/requirements.txt

# Stage 3: Final stage with non-root user and app (HYBRID)
FROM gpt-researcher-install AS gpt-researcher

# Create a non-root user for security (FROM ORIGINAL)
RUN useradd -ms /bin/bash gpt-researcher && \
    chown -R gpt-researcher:gpt-researcher /usr/src/app && \
    # Add these lines to create and set permissions for outputs directory (CRITICAL FIX)
    mkdir -p /usr/src/app/outputs && \
    chown -R gpt-researcher:gpt-researcher /usr/src/app/outputs && \
    chmod 777 /usr/src/app/outputs
    
USER gpt-researcher
WORKDIR /usr/src/app

COPY --chown=gpt-researcher:gpt-researcher ./ ./

EXPOSE 8000

# ADD THE HEALTHCHECK FROM THE NEW DOCKERFILE (BEST PRACTICE)
HEALTHCHECK CMD curl -f http://localhost:8000/health || exit 1

# Define the default command to run the application (FROM ORIGINAL)
CMD ["uvicorn", "backend.server.server:app", "--host", "0.0.0.0", "--port", "8000"]
