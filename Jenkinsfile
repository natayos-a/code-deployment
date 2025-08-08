pipeline {
    agent any

    tools {
        nodejs 'NodeJS 18'
    }

    environment {
        APP_NAME = "my-app"
        IMAGE_VERSION = "${env.BUILD_NUMBER}.0.0"
        DOCKER_IMAGE_NAME = "${APP_NAME}:${IMAGE_VERSION}"
        NEXUS_REGISTRY = "172.24.112.1:8082"
        NEXUS_DOCKER_REPO = "myapp-docker" // ตั้งชื่อตาม Repository ที่คุณสร้างใน Nexus
        FULL_DOCKER_IMAGE_PATH = "${NEXUS_REGISTRY}/${DOCKER_IMAGE_NAME}"

        GITOPS_REPO_URL = "https://github.com/natayos-a/gitops.git"
        GITOPS_CREDENTIAL_ID = "github-user-cred"
        VALUES_YAML_PATH = "helm-charts/frontend-charts/values.yaml"
        GITOPS_REPO_DIR_NAME = "${GITOPS_REPO_URL.tokenize('/')[-1].replace('.git', '')}"
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
                timeout(time: 7, unit: 'MINUTES') { // กำหนด timeout เผื่อกรณี SonarQube ช้า
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
                    sh "trivy image --severity HIGH,CRITICAL ${currentImageName}"
                    echo "Trivy scan completed. Check logs for any HIGH or CRITICAL vulnerabilities."
                }
            }
        }

        stage('Push Docker Image to Nexus Registry') {
            steps {
                echo "Pushing Docker Image to Nexus Registry..."
                sh "docker tag ${APP_NAME} ${NEXUS_REGISTRY}/${DOCKER_IMAGE_NAME}"
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

        stage('GitOps Update') {
            steps {
                script {
                    echo "Updating GitOps repository with new image tag for automatic deployment..."
                    withCredentials([usernamePassword(credentialsId: env.GITOPS_CREDENTIAL_ID, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {

                        sh "git config --global user.email 'natayos.arunsuriyasak@stream.co.th'" 
                        sh "git config --global user.name 'natayos-a'"        
                        
                        // Clone GitOps Repository โดยใช้ Credentials ใน URL (สำหรับ HTTPS)
                        def gitOpsRepoWithCreds = env.GITOPS_REPO_URL.replace("https://", "https://${GIT_USERNAME}:${GIT_PASSWORD}@")
                        sh "git clone ${gitOpsRepoWithCreds}"
                        
                        dir(env.GITOPS_REPO_DIR_NAME) { 
                            sh "git checkout main"
                            sh "yq e '.image.tag = \"${env.IMAGE_VERSION}\"' -i ${env.VALUES_YAML_PATH}"
                            echo "Updated ${env.VALUES_YAML_PATH} with new image tag: ${env.IMAGE_VERSION}"

                            // Commit และ Push การเปลี่ยนแปลงไปยัง GitOps Repository
                            sh "git add ${env.VALUES_YAML_PATH}"
                            sh "git commit -m 'CI: Update ${APP_NAME} image to ${env.IMAGE_VERSION}'"
                            sh "git push origin main"
                            echo "Changes pushed to GitOps repository. GitOps operator will now deploy."
                        }
                    }
                }
            }
        }

        stage('Deployment Handover to GitOps') { 
            steps {
                echo "Deployment of ${APP_NAME} version ${IMAGE_VERSION} is now handled by the GitOps Operator (e.g., Argo CD/Flux CD)."
                echo "Check your Kubernetes cluster and GitOps Dashboard for deployment status."
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