pipeline {
    agent any

    tools {
        nodejs 'NodeJS 18'
    }

    environment {
        APP_NAME = "my-app"
        IMAGE_VERSION = "${env.BUILD_NUMBER}"
        DOCKER_IMAGE_NAME = "${APP_NAME}:${IMAGE_VERSION}"
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
                timeout(time: 5, unit: 'MINUTES') { // กำหนด timeout เผื่อกรณี SonarQube ช้า
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker Image: ${DOCKER_IMAGE_NAME}..."
                // คำสั่ง Docker Build: ใช้ Dockerfile ใน Root ของโปรเจกต์
                sh "docker build -t ${DOCKER_IMAGE_NAME} ."
                echo "Docker Image ${DOCKER_IMAGE_NAME} built successfully."
            }
        }

        stage('Trivy Scan') {
            steps {
                echo "Running Trivy vulnerability scan on ${DOCKER_IMAGE_NAME}..."
                script {
                    def currentImageName = env.DOCKER_IMAGE_NAME
                    try {
                        // สแกน Docker Image; หากพบช่องโหว่ระดับ HIGH หรือ CRITICAL จะทำให้ Stage ล้มเหลว
                        sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${currentImageName}"
                        echo "Trivy scan completed without HIGH or CRITICAL vulnerabilities."
                    } catch (err) {
                        echo "Trivy scan found vulnerabilities with HIGH or CRITICAL severity. Aborting pipeline."
                        error "Trivy scan failed due to high/critical vulnerabilities." // ทำให้ Pipeline ล้มเหลว
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploy app !!"
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