pipeline {
    agent any
    parameters {
        choice(name: 'Environment', choices: ['Dev', 'Prod'], description: 'Select the environment to deploy')
    }
    environment {
        ARTIFACTORY_REPO = "java-project-repo"
        ARTIFACTORY_SERVER_ID = 'Artifactory'
    }
    tools {
        maven 'Maven3'
    }
    stages {
        stage('Checkout Code') {
            steps {
                script {
                     if (currentBuild.rawBuild.getCause(hudson.model.Cause$UserIdCause)) {
                     
                        echo "Pipeline triggered manually. Branch: ${params.Environment}"
                        env.BRANCH_NAME = params.Environment
                        env.DOCKER_IMAGE = "hacktom007/hello-world-springboot-${params.Environment.toLowerCase()}:${env.BUILD_ID}"
                        env.APP_PORT = "${params.Environment == 'Dev' ? '8083' : '8084'}"
                    } else if (env.GIT_BRANCH) {
                      
                        echo "Pipeline triggered by webhook. Branch: ${env.GIT_BRANCH}"
                        env.BRANCH_NAME = env.GIT_BRANCH.replace("origin/", "")
                        env.DOCKER_IMAGE = "hacktom007/hello-world-springboot-${env.BRANCH_NAME.toLowerCase()}:${env.BUILD_ID}"
                        env.APP_PORT = "${env.BRANCH_NAME == 'Dev' ? '8083' : '8084'}"
                    } else {
                        error "Unable to detect the branch. Please verify the configuration."
                    }
                    
                    echo "Checking out branch: ${env.BRANCH_NAME}"
                    // Checkout the code based on the dynamically set branch
                    git branch: "${env.BRANCH_NAME}", url: 'https://github.com/ParthSharmaT/Hello_world_java_springboot_docker.git'
                }
            }
        }
        stage('Build Application') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        stage('Execute Test Cases') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Execute Sonar Analysis') {
            environment {
                scannerHome = tool 'Sonar'
            }
            steps {
                script {
                    withSonarQubeEnv('Sonar') {
                        sh "mvn clean verify sonar:sonar -Dsonar.projectKey=JenkinsProject -Dsonar.projectName='JenkinsProject'"
                        sh "mvn sonar:sonar \
                        -Dsonar.projectKey=JenkinsProject \
                        -Dsonar.projectName='JenkinsProject' \
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml"
                    }
                }
            }
        }
        stage('Upload Artifacts to Artifactory') {
            steps {
                rtUpload serverId: env.ARTIFACTORY_SERVER_ID, spec: '''{
                    "files": [
                        {
                            "pattern": "target/*.jar",
                            "target": "${ARTIFACTORY_REPO}/"
                        }
                    ]
                }'''
                rtPublishBuildInfo serverId: env.ARTIFACTORY_SERVER_ID
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE .'
            }
        }
        stage('Push Docker Image') {
            steps {
                withDockerRegistry([credentialsId: 'docker-hub-credentials', url: 'https://index.docker.io/v1/']) {
                    sh 'docker push $DOCKER_IMAGE'
                }
            }
        }
       stage('Deploy Application') {
            steps {
                script {
                    def containerName = "hello-world-${env.BRANCH_NAME.toLowerCase()}"
                    sh """
                    if [ \$(docker ps -a -q --filter "name=${containerName}") ]; then
                        echo "Stopping and removing existing container: ${containerName}"
                        docker stop ${containerName} || true
                        docker rm ${containerName} || true
                    fi
                    
                    docker run -d --name ${containerName} -p ${APP_PORT}:${APP_PORT} $DOCKER_IMAGE --server.port=${APP_PORT}
                    """
                }
            }
        }

    }
    post {
        success {
            emailext body: "The ${env.BRANCH_NAME} environment has been successfully deployed.\\nURL: http://4.240.109.238:8084:${APP_PORT}",
                     subject: "Jenkins Pipeline: ${env.BRANCH_NAME} Deployment Successful",
                     to: 'parthsharmatanguriya@gmail.com',
                     recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']]
        }
        failure {
            emailext subject: "Jenkins Pipeline: ${env.BRANCH_NAME} Deployment Failed",
                     body: "The ${env.BRANCH_NAME} deployment has failed. Please check the Jenkins logs for more details.",
                     to: 'parthsharmatanguriya@gmail.com',
                     recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']]
        }
    }
}
