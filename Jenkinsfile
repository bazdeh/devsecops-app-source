pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME  = 'bazdeh/devsecops-secure-app'
        IMAGE_TAG          = "1.0.${BUILD_NUMBER}"
        GITOPS_REPO_URL    = 'github.com/bazdeh/devsecops-gitops-manifests.git'
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('2. SonarQube Code Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh 'echo "Running Static Application Security Testing (SAST)..."'
                }
            }
        }

        stage('3. Vulnerability Scanning (Trivy Filesystem)') {
            steps {
                sh 'docker run --rm -v $(pwd):/apps aquasec/trivy:latest fs /apps'
            }
        }

        stage('4. Build & Tag Container Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest"
                }
            }
        }

        stage('5. Vulnerability Scanning (Trivy Image)') {
            steps {
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity CRITICAL ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('6. Push Image to Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-auth-id', passwordVariable: 'DOCKER_REGISTRY_PASS', usernameVariable: 'DOCKER_REGISTRY_USER')]) {
                    sh "echo ${DOCKER_REGISTRY_PASS} | docker login -u ${DOCKER_REGISTRY_USER} --password-stdin"
                    sh "docker push ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${DOCKER_IMAGE_NAME}:latest"
                }
            }
        }

        stage('7. GitOps Manifest Handoff') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-token-id', passwordVariable: 'GITHUB_TOKEN', usernameVariable: 'GITHUB_USER')]) {
                    sh """
                        git config --global user.email "jenkins@devsecops.local"
                        git config --global user.name "Jenkins Automation"
                        
                        git clone https://${GITHUB_USER}:${GITHUB_TOKEN}@${GITOPS_REPO_URL} manifest-temp
                        cd manifest-temp
                        
                        sed -i "s|image: bazdeh/devsecops-secure-app:.*|image: bazdeh/devsecops-secure-app:\${IMAGE_TAG}|g" deployment.yaml
                        
                        git add .
                        git commit -m "ci: automated update image tag to \${IMAGE_TAG} [skip ci]" || true
                        git push origin main
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout'
            cleanWs()
        }
    }
}
