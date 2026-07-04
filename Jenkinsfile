pipeline {
    agent any

    environment {
        // Change 'your-dockerhub-username' to your actual Docker Hub login name
        DOCKER_IMAGE_NAME  = 'st0u/devsecops-secure-app'
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
                // Injects configuration saved during Phase 1
                withSonarQubeEnv('SonarQube-Server') {
                    // Triggers the static scan on the Python files
                    sh 'echo "Running Static Application Security Testing (SAST)..."'
                    // Note: If using standalone quality analysis scanners, we call them here
                }
            }
        }

        stage('3. Vulnerability Scanning (Trivy Filesystem)') {
            steps {
                // Runs Trivy inside a temporary container to inspect our cloned filesystem for secrets or hardcoded vulnerabilities
                sh 'docker run --rm -v $(pwd):/apps aquasec/trivy:latest fs /apps'
            }
        }

        stage('4. Build & Tag Container Image') {
            steps {
                script {
                    // Builds the image leveraging our secure Dockerfile setup
                    sh "docker build -t ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest"
                }
            }
        }

        stage('5. Vulnerability Scanning (Trivy Image)') {
            steps {
                // Instructs Trivy to pull and deeply scan the freshly constructed image layers for critical operating system CVEs
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity CRITICAL ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('6. Push Image to Registry') {
            steps {
                // Securely fetches your Docker Hub tokens from the credentials vault
                withCredentials([usernamePassword(credentialsId: 'dockerhub-auth-id', passwordVariable: 'DOCKER_REGISTRY_PASS', usernameVariable: 'DOCKER_REGISTRY_USER')]) {
                    sh "echo ${DOCKER_REGISTRY_PASS} | docker login -u ${DOCKER_REGISTRY_USER} --password-stdin"
                    sh "docker push ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${DOCKER_IMAGE_NAME}:latest"
                }
            }
        }

        stage('7. GitOps Manifest Handoff') {
            steps {
                // Updates the deployment tag configuration inside your GitOps repository to trigger ArgoCD deployment sync
                withCredentials([usernamePassword(credentialsId: 'github-token-id', passwordVariable: 'GITHUB_TOKEN', usernameVariable: 'GITHUB_USER')]) {
                    sh """
                        git config --global user.email "jenkins@devsecops.local"
                        git config --global user.name "Jenkins Automation"
                        
                        # Clone manifest repo dynamically to make changes
                        git clone https://${GITHUB_USER}:${GITHUB_TOKEN}@${GITOPS_REPO_URL} manifest-temp
                        cd manifest-temp
                        
                        # We will update deployment tags here once we create manifests in Phase 5
                        echo "Image Tag Updated to ${IMAGE_TAG}" > image_tracking.txt
                        
                        git add .
                        git commit -m "ci: automated update image tag to ${IMAGE_TAG} [skip ci]" || true
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
