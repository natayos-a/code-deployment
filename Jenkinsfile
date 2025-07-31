pipeline {
    agent any

    tools {
        nodejs 'NodeJS 24'
    }

    environment {
        
        SONAR_HOST_URL_JENKINS = "http://localhost:9000" // <-- ต้องแก้ไขตรงนี้!
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
                // withSonarQubeEnv จะทำให้ Jenkins กำหนดค่า environment variables
                // ที่จำเป็นสำหรับ SonarQube Scanner ให้โดยอัตโนมัติ
                // 'MySonarQubeServer' ต้องตรงกับชื่อที่คุณตั้งใน Configure System
                withSonarQubeEnv('SonarCICD') {
                    // คำสั่งสำหรับรัน SonarQube Scanner
                    // โครงสร้างคำสั่งจะแตกต่างกันเล็กน้อยขึ้นอยู่กับประเภทโปรเจกต์
                    // สำหรับ JS/TS/Node.js โปรเจกต์ที่ไม่มี build tool เฉพาะ:
                    sh 'sonar-scanner \
                      -Dsonar.projectKey=my_code_deployment_project \
                      -Dsonar.sources=.' // . หมายถึงสแกนโฟลเดอร์ปัจจุบันทั้งหมด
                }
            }
        }
        stage('Quality Gate Check') {
            steps {
                // รอให้ SonarQube วิเคราะห์เสร็จและตรวจสอบ Quality Gate
                // 'MySonarQubeServer' ต้องตรงกับชื่อที่คุณตั้งใน Configure System
                timeout(time: 5, unit: 'MINUTES') { // กำหนด timeout เผื่อกรณี SonarQube ช้า
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploy app !!"
            }
        }

    //     stage('Code Quality Analysis') {
    //         steps {
    //             script {
    //                 echo "Starting SonarQube analysis..."
    //                 // 'SonarQubeServer' คือชื่อ SonarQube server ที่คอนฟิกใน Jenkins (Manage Jenkins -> Configure System)
    //                 // ไม่ต้องระบุ credentialsId: 'Sonar' ที่นี่ เพราะ credential ควรผูกกับ server ใน Jenkins แล้ว
    //                 withSonarQubeEnv(installationName: 'SonarCICD') { // <--- **ใช้ชื่อ SonarQube Server ที่คุณตั้งค่าไว้ใน Jenkins**
    //                     // 'DevopsTrain-tool' คือชื่อ SonarQube Scanner ที่คอนฟิกใน Jenkins Global Tool Configuration
    //                     def scannerHome = tool 'DevopsTrain-tool' // <--- **ใช้ชื่อ SonarScanner Tool ที่คุณตั้งค่าไว้ใน Jenkins**

    //                     // รัน SonarScanner พร้อมพารามิเตอร์ที่จำเป็น
    //                     // หากมีไฟล์ sonar-project.properties อยู่ใน root ของ project ก็ไม่ต้องระบุพารามิเตอร์เหล่านี้ซ้ำ
    //                     sh "${scannerHome}/bin/sonar-scanner " +
    //                        "-Dsonar.projectKey=${SONAR_PROJECT_KEY} " +
    //                        "-Dsonar.projectName=${SONAR_PROJECT_NAME} " +
    //                        "-Dsonar.sources=${SONAR_SOURCES} " +
    //                        "-Dsonar.binaries=${SONAR_BINARIES} " +
    //                        "-Dsonar.host.url=${SONAR_HOST_URL_JENKINS} " + // ส่ง URL ไปให้ SonarScanner ด้วย
    //                        "-Dsonar.javascript.lcov.reportPaths=coverage/lcov.info " + // สำหรับ coverage report ของ JS/TS
    //                        "-Dsonar.tests=src " + // Path to your test files (e.g., 'src' folder)
    //                        "-Dsonar.test.inclusions=**/*.test.{js,jsx,ts,tsx},**/*.spec.{js,jsx,ts,tsx} " +
    //                        "-Dsonar.exclusions=node_modules/**,build/** " + // ไฟล์/โฟลเดอร์ที่ไม่ต้องการ Scan
    //                        "-Dsonar.typescript.tsconfigPath=tsconfig.json" // สำหรับ TypeScript projects
    //                 }
    //             }
    //         }
    //     }

    //     // Stage 4: Wait for Quality Gate (สำคัญมาก!)
    //     // Pipeline จะหยุดรอที่นี่จนกว่า SonarQube จะวิเคราะห์เสร็จและส่งผล Quality Gate กลับมา
    //     stage('Quality Gate Check') {
    //         steps {
    //             echo "Waiting for SonarQube Quality Gate status..."
    //             timeout(time: 15, unit: 'MINUTES') { // กำหนด Timeout เผื่อ SonarQube ใช้เวลานาน
    //                 def qg = waitForQualityGate() // ใช้ plugin SonarQube Scanner for Jenkins
    //                 if (qg.status != 'OK') {
    //                     error "SonarQube Quality Gate failed with status: ${qg.status}. Stopping pipeline."
    //                 } else {
    //                     echo "SonarQube Quality Gate passed: ${qg.status}"
    //                 }
    //             }
    //         }
    //     }
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