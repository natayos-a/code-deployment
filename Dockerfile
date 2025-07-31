# Use the official Jenkins LTS image with JDK17 as base
FROM jenkins/jenkins:lts-jdk17

# Switch to root user to perform installations
USER root

RUN apt-get update && \
    apt-get install -y wget unzip apt-transport-https gnupg2 && \
    rm -rf /var/lib/apt/lists/*

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