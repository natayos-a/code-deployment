# Use the official Jenkins LTS image with JDK17 as base
FROM jenkins/jenkins:lts-jdk17

# Switch to root user to perform installations
USER root

RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    wget \
    apt-transport-https \
    gnupg2 \
    ca-certificates \
    lsb-release \
    libldap-2.5-0 \
    libsqlite3-0 \
    perl \
    zlib1g && \
    \
    apt-get upgrade -y git libldap-2.5-0 libsqlite3-0 perl zlib1g && \
    \
    rm -rf /var/lib/apt/lists/*

# === ติดตั้ง Docker CLI ===
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

RUN mkdir -p /etc/docker && \
    echo '{ "insecure-registries": ["nexus:8082"] }' | tee /etc/docker/daemon.json && \
    systemctl daemon-reload || true && \
    systemctl restart docker || true

# เพิ่ม Jenkins user เข้าไปใน docker group
# เพื่อให้ Jenkins user สามารถรันคำสั่ง Docker ได้
RUN usermod -aG docker jenkins
    
# Define SonarScanner version
ARG SONAR_SCANNER_VERSION=7.1.0.4889
ENV SONAR_SCANNER_HOME=/opt/sonar-scanner
ENV PATH="${PATH}:${SONAR_SCANNER_HOME}/bin"

RUN wget -q "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip" -O /tmp/sonar-scanner-cli.zip && \
    mkdir -p "${SONAR_SCANNER_HOME}" && \
    unzip -q /tmp/sonar-scanner-cli.zip -d "${SONAR_SCANNER_HOME}" && \
    mv "${SONAR_SCANNER_HOME}/sonar-scanner-${SONAR_SCANNER_VERSION}/"* "${SONAR_SCANNER_HOME}/" && \
    rmdir "${SONAR_SCANNER_HOME}/sonar-scanner-${SONAR_SCANNER_VERSION}" && \
    rm /tmp/sonar-scanner-cli.zip

# Verify SonarScanner installation
RUN sonar-scanner -h

# --- Trivy Scanner Installation ---
# Download and install Trivy
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | tee -a /etc/apt/sources.list.d/trivy.list && \
    apt-get update && \
    apt-get install trivy

# Verify Trivy installation
RUN trivy --version

# Switch back to the Jenkins user
USER jenkins