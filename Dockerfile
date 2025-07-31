# ใช้ Jenkins LTS image เป็น Base
FROM jenkins/jenkins:lts-jdk11

USER root

# อัปเดตแพ็คเกจและติดตั้งเครื่องมือที่จำเป็น
# git สำหรับการ clone repo
# curl/unzip สำหรับดาวน์โหลดและแตกไฟล์ SonarQube Scanner
# nodejs และ npm สำหรับโปรเจกต์ Node.js ของคุณ
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# ดาวน์โหลด SonarQube Scanner
ARG SONAR_SCANNER_VERSION=11.4.0.2044_7.2.0
ARG SONAR_SCANNER_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip"

RUN curl -sSL ${SONAR_SCANNER_URL} -o /tmp/sonar-scanner.zip \
    && unzip /tmp/sonar-scanner.zip -d /opt/ \
    && mv /opt/sonar-scanner-${SONAR_SCANNER_VERSION} /opt/sonar-scanner \
    && rm /tmp/sonar-scanner.zip

# เพิ่ม sonar-scanner ใน PATH
ENV PATH="/opt/sonar-scanner/bin:${PATH}"

USER jenkins