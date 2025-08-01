pipeline {
    agent any

    tools {
        nodejs 'NodeJS 18'
    }

    environment {
        APP_NAME = "my-app"
        NEXUS_REGISTRY = "172.24.112.1:8082"
        NEXUS_DOCKER_REPO = "myapp-docker" // ตั้งชื่อตาม Repository ที่คุณสร้างใน Nexus
        FULL_DOCKER_IMAGE_PATH = "${NEXUS_REGISTRY}/${APP_NAME}:lastest"
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo "Checking out code....."
                    git branch: 'main', url: 'https://github.com/natayos-a/code-deployment.git'
                }
            }
        }

        stage('Build & Test') {
            steps {
                echo "Installing dependencies and running tests..."
                sh "npm install"
                echo "Building project..."
                sh "npm run build"
                sh "npm test"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarServer') {
                    sh 'sonar-scanner -Dsonar.projectKey=cicd -Dsonar.sources=.'
                }
            }
        }

        stage('Quality Gate Check') {
            steps {
                timeout(time: 3, unit: 'MINUTES') { // กำหนด timeout เผื่อกรณี SonarQube ช้า
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // สร้าง tag สำหรับ Docker Image โดยใช้ ID ของ Jenkins Build
                    def DOCKER_IMAGE_TAG = "${env.BUILD_ID}"
                    def FULL_DOCKER_IMAGE_NAME = "${APP_NAME}:${DOCKER_IMAGE_TAG}"
                    
                    echo "Building Docker Image: ${FULL_DOCKER_IMAGE_NAME}..."
                    
                    // คำสั่ง Docker Build: ใช้ Dockerfile ใน Root ของโปรเจกต์ และกำหนด tag
                    sh "docker build -t ${FULL_DOCKER_IMAGE_NAME} ."
                    
                    echo "Docker Image ${FULL_DOCKER_IMAGE_NAME} built successfully."
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                echo "Running Trivy vulnerability scan on ${DOCKER_IMAGE_NAME}..."
                script {
                    def currentImageName = env.DOCKER_IMAGE_NAME
                    sh "trivy image --severity HIGH,CRITICAL ${currentImageName}"
                    echo "Trivy scan completed. Check logs for any HIGH or CRITICAL vulnerabilities."
                }
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploy app !!"
                // ขั้นตอนที่ 5: Push to Registry
                withCredentials([usernamePassword(credentialsId: 'nexus-registry', usernameVariable: 'NEXUS_USERNAME', passwordVariable: 'NEXUS_PASSWORD')]) {
                    echo "Logging into Nexus Registry: ${NEXUS_REGISTRY}..."
                    sh "echo ${NEXUS_PASSWORD} | docker login -u ${NEXUS_USERNAME} --password-stdin ${NEXUS_REGISTRY}"
                    echo "Pushing Docker Image: ${FULL_DOCKER_IMAGE_PATH} to Nexus Registry..."
                    sh "docker push ${FULL_DOCKER_IMAGE_PATH}"
                    echo "Docker Image pushed successfully to Nexus Registry."
                    sh "docker logout ${NEXUS_REGISTRY}"
                }
            }
        }
    }
    
    post {
        always {
            // ทำความสะอาดพื้นที่ทำงานเสมอ
            echo 'Cleaning up workspace...'
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