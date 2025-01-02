pipeline {
    agent any
    parameters {
        choice(name: 'Environment', choices: ['Dev', 'Prod'], description: 'Select the environment to deploy')
    }
    environment {
        ARTIFACTORY_REPO = "tomcat-java"
        ARTIFACTORY_SERVER_ID = 'Artifactory'
        TOMCAT_DEV_PORT = '8085'
        TOMCAT_PROD_PORT = '8086'
        TOMCAT_DEV_PATH = '/opt/tomcat-dev/webapps'
        TOMCAT_PROD_PATH = '/opt/tomcat-prod/webapps'
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
                    } else if (env.GIT_BRANCH) {
                        echo "Pipeline triggered by webhook. Branch: ${env.GIT_BRANCH}"
                        env.BRANCH_NAME = env.GIT_BRANCH.replace("origin/", "")
                    } else {
                        error "Unable to detect the branch. Please verify the configuration."
                    }
                    
                    echo "Checking out branch: ${env.BRANCH_NAME}"
                    git branch: "${env.BRANCH_NAME}", url: 'https://github.com/ParthSharmaT/tomcat_java.git.git'
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
                        sh "mvn clean verify sonar:sonar -Dsonar.projectKey=tomcat-java -Dsonar.projectName='tomcat-java'"
                        sh "mvn sonar:sonar \
                        -Dsonar.projectKey=tomcat-java \
                        -Dsonar.projectName='tomcat-java' \
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
                            "pattern": "target/*.war",
                            "target": "${ARTIFACTORY_REPO}/"
                        }
                    ]
                }'''
                rtPublishBuildInfo serverId: env.ARTIFACTORY_SERVER_ID
            }
        }
        stage('Deploy to Tomcat') {
            steps {
                script {
                    def tomcatPort = env.BRANCH_NAME == 'Dev' ? env.TOMCAT_DEV_PORT : env.TOMCAT_PROD_PORT
                    def tomcatPath = env.BRANCH_NAME == 'Dev' ? env.TOMCAT_DEV_PATH : env.TOMCAT_PROD_PATH
                    def warFile = "target/*.war"
                    sh """
                    if [ -d "${tomcatPath}/ROOT" ] || [ -f "${tomcatPath}/ROOT.war" ]; then
                        echo "Stopping the existing default application on Tomcat"
                        rm -rf ${tomcatPath}/ROOT*
                    fi
                    
                    echo "Deploying application as the default application on Tomcat"
                    cp ${warFile} ${tomcatPath}/ROOT.war
                    """
                }
            }
        }

    }
    post {
        success {
            emailext body: "The ${env.BRANCH_NAME} environment has been successfully deployed to Tomcat.\\nURL: http://4.240.109.238/:${env.BRANCH_NAME == 'Dev' ? env.TOMCAT_DEV_PORT : env.TOMCAT_PROD_PORT}",
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
