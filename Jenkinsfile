pipeline {
    agent any // หรือระบุ agent ที่มี Docker, SonarQube Scanner, Trivy ติดตั้งอยู่

    environment {
        // กำหนดตัวแปรสภาพแวดล้อม
        SONAR_SCANNER_HOME = tool 'SonarScanner' // ต้องคอนฟิก SonarQube Scanner ใน Jenkins Global Tool Configuration
        NEXUS_DOCKER_REGISTRY = "localhost::8081" // เปลี่ยนเป็น IP/Hostname ของ Nexus Registry
        NEXUS_REPO_NAME = "myapp" // ชื่อ Repository ใน Nexus สำหรับ Docker images
        APP_NAME = "my-app" // ชื่อแอปพลิเคชัน
        // GIT_OPS_REPO = "https://github.com/your-org/your-gitops-repo.git" // URL ของ GitOps Repository
        // GIT_OPS_BRANCH = "main" // Branch ของ GitOps Repository
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/your-org/your-app-repo.git' // เปลี่ยนเป็น Git Repository ของคุณ
            }
        }

        stage('Code Quality Analysis') {
            steps {
                withSonarQubeEnv('SonarQubeServer') { // 'SonarQubeServer' คือชื่อ SonarQube server ที่คอนฟิกใน Jenkins
                    sh "${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                       -Dsonar.projectKey=${APP_NAME} \
                       -Dsonar.sources=. \
                       -Dsonar.host.url=${SONAR_HOST_URL} \
                       -Dsonar.login=${SONAR_AUTH_TOKEN}" // เปลี่ยน SONAR_HOST_URL, SONAR_AUTH_TOKEN เป็นตัวแปร Jenkins Credential
                }
            }
            post {
                unstable {
                    // ถ้า SonarQube gate ไม่ผ่าน สามารถตัดสินใจว่าจะให้ Pipeline ล้มเหลว หรือแค่เตือน
                    echo "SonarQube Quality Gate failed, but continuing pipeline."
                }
                failure {
                    error "SonarQube Quality Gate failed. Stopping pipeline."
                }
            }
        }

        stage('Build & Test') {
            steps {
                // ตัวอย่างสำหรับการ Build และ Test (ปรับเปลี่ยนตามภาษาและ Framework ของคุณ)
                script {
                    if (fileExists('pom.xml')) { // ตัวอย่างสำหรับ Java Maven
                        sh "mvn clean install"
                    } else if (fileExists('package.json')) { // ตัวอย่างสำหรับ Node.js
                        sh "npm install"
                        sh "npm test"
                    } else if (fileExists('Dockerfile')) {
                        // ถ้าแอปพลิเคชันเป็น Dockerized โดยตรง
                        sh "docker build -t ${APP_NAME}:${env.BUILD_NUMBER} ."
                    } else {
                        error "Unsupported project type. Please add build steps."
                    }
                }
                // ถ้ามีการสร้าง JAR/WAR/Binary หรือ artifact อื่นๆ ในขั้นตอนนี้
                // archiveArtifacts artifacts: 'target/*.jar', fingerprint: true // ตัวอย่าง
            }
        }

        stage('Security Scanning (Trivy)') {
            steps {
                script {
                    def imageName = "${APP_NAME}:${env.BUILD_NUMBER}"
                    // ตรวจสอบว่ามี Dockerfile และสามารถ build ได้
                    if (fileExists('Dockerfile')) {
                        sh "docker build -t ${imageName} ."
                        sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${imageName}"
                        // เพิ่ม --timeout 5m ถ้าการสแกนใช้เวลานาน
                    } else {
                        echo "No Dockerfile found. Skipping Trivy scan."
                    }
                }
            }
        }

        stage('Push to Registry') {
            steps {
                script {
                    def fullImageName = "${NEXUS_DOCKER_REGISTRY}/${NEXUS_REPO_NAME}/${APP_NAME}:${env.BUILD_NUMBER}"
                    // ตรวจสอบว่ามี Dockerfile และมีการ build image แล้ว
                    if (fileExists('Dockerfile')) {
                        // Login to Nexus Docker Registry
                        withCredentials([usernamePassword(credentialsId: 'nexus-docker-creds', passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                            sh "echo ${NEXUS_PASSWORD} | docker login ${NEXUS_DOCKER_REGISTRY} --username ${NEXUS_USERNAME} --password-stdin"
                        }
                        // Tag image with Nexus registry name
                        sh "docker tag ${APP_NAME}:${env.BUILD_NUMBER} ${fullImageName}"
                        // Push to Nexus
                        sh "docker push ${fullImageName}"
                        echo "Docker image pushed to Nexus Registry: ${fullImageName}"
                    } else {
                        echo "No Dockerfile found or image not built. Skipping Docker push."
                    }
                }
            }
        }

        stage('GitOps Update') {
            steps {
                script {
                    // 1. Clone the GitOps Repository
                    sh "git config --global user.email 'jenkins@example.com'"
                    sh "git config --global user.name 'Jenkins CI'"
                    sh "git clone ${GIT_OPS_REPO} gitops-repo"
                    dir('gitops-repo') {
                        sh "git checkout ${GIT_OPS_BRANCH}"

                        // 2. Update values.yaml (ตัวอย่าง: ใช้ yq หรือ sed)
                        def newImageTag = "${NEXUS_DOCKER_REGISTRY}/${NEXUS_REPO_NAME}/${APP_NAME}:${env.BUILD_NUMBER}"
                        sh "sed -i 's|image:.*|image: ${newImageTag}|g' ${VALUES_YAML_PATH}" // ต้องระมัดระวัง regex ให้ถูกต้อง
                        // หรือใช้ yq (ต้องติดตั้ง yq ใน Jenkins agent)
                        // sh "yq e '.image = \"${newImageTag}\"' -i ${VALUES_YAML_PATH}"

                        // 3. Commit and Push changes
                        sh "git add ${VALUES_YAML_PATH}"
                        sh "git commit -m 'Update ${APP_NAME} image to ${newImageTag} by Jenkins CI [skip ci]'" // [skip ci] เพื่อไม่ให้ GitOps repo trigger Jenkins ซ้ำ
                        withCredentials([sshUserPrivateKey(credentialsId: 'gitops-ssh-key', keyFileVariable: 'SSH_KEY_FILE')]) {
                            sh "GIT_SSH_COMMAND='ssh -i ${SSH_KEY_FILE} -o StrictHostKeyChecking=no' git push origin ${GIT_OPS_BRANCH}"
                        }
                        echo "GitOps repository updated with new image tag: ${newImageTag}"
                    }
                }
            }
        }
    }
    post {
        always {
            // ทำความสะอาดพื้นที่ทำงานเสมอ
            cleanWs()
        }
        success {
            echo "Pipeline finished successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}