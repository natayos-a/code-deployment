pipeline {
    // กำหนด Agent ที่มี Node.js และ Java เพื่อให้สามารถรัน npm และ SonarScanner ได้
    // ถ้าคุณต้องการรัน Docker และ Trivy ด้วย, Agent นี้ก็ควรมี Docker Engine และ Trivy ติดตั้งอยู่
    agent {
        docker {
            image 'node:18-slim'
            args '-u 1000:1000'
        }
    }

    environment {
        
        // Hostname/IP ที่ Jenkins สามารถเข้าถึง SonarQube ได้จริง
        // เช่น: "http://192.168.1.100:9000" หรือ "http://sonarqube-service-name:9000" (ถ้าใช้ Docker Compose/Kubernetes)
        SONAR_HOST_URL_JENKINS = "http://172.17.0.4:9000" // <-- ต้องแก้ไขตรงนี้!
        
        // Hostname/IP ที่ Jenkins สามารถเข้าถึง Nexus ได้จริง
        // เช่น: "your-nexus-ip-or-hostname:8082"
        // NEXUS_DOCKER_REGISTRY = "your-nexus-ip-or-hostname:8082" // <-- ต้องแก้ไขตรงนี้!
        // NEXUS_REPO_NAME = "code-deployment" // ชื่อ Repository ใน Nexus สำหรับ Docker images
        APP_NAME = "my-app" // ชื่อแอปพลิเคชัน
        
        // SonarQube Project Parameters (แนะนำให้กำหนดใน Jenkinsfile หรือใน sonar-project.properties)
        SONAR_PROJECT_KEY = "DevopsTrain" // Unique key สำหรับ SonarQube project
        SONAR_PROJECT_NAME = "${APP_NAME} (${env.BRANCH_NAME})" // ชื่อที่แสดงใน SonarQube
        SONAR_SOURCES = "." // Path ของ Source code ที่ต้องการ Scan ('.' คือ current directory)
        SONAR_BINARIES = "build" // Path ของไฟล์ที่ Compile แล้ว (สำหรับ JS/TS คือ build folder)
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    // ถ้า Jenkinsfile ถูกดึงมาจาก SCM ด้วย "Pipeline script from SCM"
                    // Jenkins จะทำการ Checkout Repo หลักให้อยู่แล้ว
                    // คำสั่ง 'git' นี้อาจไม่จำเป็น เว้นแต่คุณต้องการ checkout sub-repo อื่นๆ
                    echo "Checking out code....."
                    git branch: 'main', url: 'https://github.com/natayos-a/code-deployment.git' // เปลี่ยนเป็น Git Repository ของคุณ
                }
            }
        }

        stage('Build & Test') {
            steps {
                script {
                    echo "Installing dependencies and running tests..."
                    sh "npm install"
                    // Run tests และสร้าง coverage report ที่ SonarQube เข้าใจ
                    // ตัวอย่างสำหรับ Jest/React:
                    sh "npm test -- --ci --coverage --reporters=default --reporters=jest-junit --detectOpenHandles"
                    // หากมี JUnit XML report, ให้ Jenkins เก็บไว้ด้วย
                    junit 'junit.xml' // ตรวจสอบว่า test runner ของคุณสร้างไฟล์นี้
                    
                    echo "Building project..."
                    sh "npm run build" // สร้าง Production build (มักจะสร้าง folder 'build' หรือ 'dist')
                }
            }
        }

        stage('Code Quality Analysis') {
            steps {
                script {
                    echo "Starting SonarQube analysis..."
                    // 'SonarQubeServer' คือชื่อ SonarQube server ที่คอนฟิกใน Jenkins (Manage Jenkins -> Configure System)
                    // ไม่ต้องระบุ credentialsId: 'Sonar' ที่นี่ เพราะ credential ควรผูกกับ server ใน Jenkins แล้ว
                    withSonarQubeEnv(installationName: 'SonarCICD') { // <--- **ใช้ชื่อ SonarQube Server ที่คุณตั้งค่าไว้ใน Jenkins**
                        // 'DevopsTrain-tool' คือชื่อ SonarQube Scanner ที่คอนฟิกใน Jenkins Global Tool Configuration
                        def scannerHome = tool 'DevopsTrain-tool' // <--- **ใช้ชื่อ SonarScanner Tool ที่คุณตั้งค่าไว้ใน Jenkins**

                        // รัน SonarScanner พร้อมพารามิเตอร์ที่จำเป็น
                        // หากมีไฟล์ sonar-project.properties อยู่ใน root ของ project ก็ไม่ต้องระบุพารามิเตอร์เหล่านี้ซ้ำ
                        sh "${scannerHome}/bin/sonar-scanner " +
                           "-Dsonar.projectKey=${SONAR_PROJECT_KEY} " +
                           "-Dsonar.projectName=${SONAR_PROJECT_NAME} " +
                           "-Dsonar.sources=${SONAR_SOURCES} " +
                           "-Dsonar.binaries=${SONAR_BINARIES} " +
                           "-Dsonar.host.url=${SONAR_HOST_URL_JENKINS} " + // ส่ง URL ไปให้ SonarScanner ด้วย
                           "-Dsonar.javascript.lcov.reportPaths=coverage/lcov.info " + // สำหรับ coverage report ของ JS/TS
                           "-Dsonar.tests=src " + // Path to your test files (e.g., 'src' folder)
                           "-Dsonar.test.inclusions=**/*.test.{js,jsx,ts,tsx},**/*.spec.{js,jsx,ts,tsx} " +
                           "-Dsonar.exclusions=node_modules/**,build/** " + // ไฟล์/โฟลเดอร์ที่ไม่ต้องการ Scan
                           "-Dsonar.typescript.tsconfigPath=tsconfig.json" // สำหรับ TypeScript projects
                    }
                }
            }
            // post block สำหรับ SonarQube ควรอยู่หลังจาก 'Quality Gate Check'
            // เพื่อให้แน่ใจว่าได้รอผลลัพธ์จาก SonarQube แล้ว
        }

        // Stage 4: Wait for Quality Gate (สำคัญมาก!)
        // Pipeline จะหยุดรอที่นี่จนกว่า SonarQube จะวิเคราะห์เสร็จและส่งผล Quality Gate กลับมา
        stage('Quality Gate Check') {
            steps {
                echo "Waiting for SonarQube Quality Gate status..."
                timeout(time: 15, unit: 'MINUTES') { // กำหนด Timeout เผื่อ SonarQube ใช้เวลานาน
                    def qg = waitForQualityGate() // ใช้ plugin SonarQube Scanner for Jenkins
                    if (qg.status != 'OK') {
                        error "SonarQube Quality Gate failed with status: ${qg.status}. Stopping pipeline."
                    } else {
                        echo "SonarQube Quality Gate passed: ${qg.status}"
                    }
                }
            }
        }

        stage('Security Scanning (Trivy)') {
            steps {
                script {
                    def imageName = "${APP_NAME}:${env.BUILD_NUMBER}"
                    // ตรวจสอบว่ามี Dockerfile และสามารถ build ได้
                    if (fileExists('Dockerfile')) {
                        echo "Building Docker image: ${imageName}"
                        // ต้องแน่ใจว่า Agent ที่ใช้มี Docker Engine ติดตั้งและสามารถรันคำสั่ง docker ได้
                        sh "docker build -t ${imageName} ."
                        echo "Running Trivy scan on ${imageName}"
                        // ต้องแน่ใจว่า Agent มี Trivy ติดตั้งอยู่
                        // --exit-code 1 จะทำให้ build fail ถ้าเจอ severity ที่กำหนด
                        sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${imageName}"
                        // เพิ่ม --timeout 5m ถ้าการสแกนใช้เวลานาน
                    } else {
                        echo "No Dockerfile found. Skipping Trivy scan."
                    }
                }
            }
        }

        // stage('Push to Registry') {
        //     steps {
        //         script {
        //             def fullImageName = "${NEXUS_DOCKER_REGISTRY}/${NEXUS_REPO_NAME}/${APP_NAME}:${env.BUILD_NUMBER}"
        //             if (fileExists('Dockerfile')) { // ตรวจสอบว่ามี Dockerfile และมีการ build image แล้ว
        //                 echo "Logging into Nexus Docker Registry: ${NEXUS_DOCKER_REGISTRY}"
        //                 // 'nexus-docker-creds' คือ Jenkins Credential (Username with password) ที่มี User/Pass สำหรับ Nexus
        //                 withCredentials([usernamePassword(credentialsId: 'nexus-docker-creds', passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
        //                     sh "echo ${NEXUS_PASSWORD} | docker login ${NEXUS_DOCKER_REGISTRY} --username ${NEXUS_USERNAME} --password-stdin"
        //                 }
        //                 echo "Tagging Docker image: ${fullImageName}"
        //                 sh "docker tag ${APP_NAME}:${env.BUILD_NUMBER} ${fullImageName}"
        //                 echo "Pushing Docker image to Nexus Registry..."
        //                 sh "docker push ${fullImageName}"
        //                 echo "Docker image pushed to Nexus Registry: ${fullImageName}"
        //             } else {
        //                 echo "No Dockerfile found or image not built. Skipping Docker push."
        //             }
        //         }
        //     }
        // }

        // ตัวอย่าง GitOps Update (ต้องปรับปรุง PATH ของ VALUES_YAML_PATH และ Credential ให้ถูกต้อง)
        // stage('GitOps Update') {
        //     environment {
        //         GIT_OPS_REPO = "https://github.com/your-org/your-gitops-repo.git" // URL ของ GitOps Repository
        //         GIT_OPS_BRANCH = "main" // Branch ของ GitOps Repository
        //         VALUES_YAML_PATH = "path/to/your/helm/chart/values.yaml" // <-- ต้องแก้ไขตรงนี้!
        //     }
        //     steps {
        //         script {
        //             // 1. Clone the GitOps Repository
        //             sh "git config --global user.email 'jenkins@example.com'"
        //             sh "git config --global user.name 'Jenkins CI'"
        //             sh "git clone ${GIT_OPS_REPO} gitops-repo"
        //             dir('gitops-repo') {
        //                 sh "git checkout ${GIT_OPS_BRANCH}"

        //                 // 2. Update values.yaml (ตัวอย่าง: ใช้ sed)
        //                 def newImageTag = "${NEXUS_DOCKER_REGISTRY}/${NEXUS_REPO_NAME}/${APP_NAME}:${env.BUILD_NUMBER}"
        //                 // คำสั่ง sed ต้องระมัดระวัง regex ให้ถูกต้องตามโครงสร้างไฟล์ yaml ของคุณ
        //                 // หากใช้ Helm chart, อาจจะเป็น 'image.tag' หรือ 'image.repository'
        //                 // ตัวอย่าง sed: sh "sed -i 's|image:.*|image: ${newImageTag}|g' ${VALUES_YAML_PATH}"
        //                 // หรือใช้ yq (แนะนำถ้า Agent มี yq ติดตั้ง):
        //                 sh "yq e '.image.repository = \"${NEXUS_DOCKER_REGISTRY}/${NEXUS_REPO_NAME}/${APP_NAME}\"' -i ${VALUES_YAML_PATH}"
        //                 sh "yq e '.image.tag = \"${env.BUILD_NUMBER}\"' -i ${VALUES_YAML_PATH}"
        //                 echo "Updated ${VALUES_YAML_PATH} with new image tag: ${newImageTag}"

        //                 // 3. Commit and Push changes
        //                 sh "git add ${VALUES_YAML_PATH}"
        //                 sh "git commit -m 'Update ${APP_NAME} image to ${newImageTag} by Jenkins CI [skip ci]'" // [skip ci] เพื่อไม่ให้ GitOps repo trigger Jenkins ซ้ำ
        //                 // 'gitops-ssh-key' คือ Jenkins Credential (SSH Username with private key)
        //                 withCredentials([sshUserPrivateKey(credentialsId: 'gitops-ssh-key', keyFileVariable: 'SSH_KEY_FILE')]) {
        //                     sh "GIT_SSH_COMMAND='ssh -i ${SSH_KEY_FILE} -o StrictHostKeyChecking=no' git push origin ${GIT_OPS_BRANCH}"
        //                 }
        //                 echo "GitOps repository updated."
        //             }
        //         }
        //     }
        // }
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
        // คุณสามารถเพิ่ม block สำหรับ `unstable` หรือ `aborted` ได้ตามต้องการ
        // เช่น: unstable { echo "Pipeline finished with unstable status." }
    }
}