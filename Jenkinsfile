pipeline {
    agent any

    environment {
        FLUTTER_HOME = "C:\\flutter"
        PATH = "${FLUTTER_HOME}\\bin;${env.PATH}"

        IMAGE_NAME = "host.docker.internal:8082/docker-hosted/flutter-web"
        IMAGE_TAG = "1.0"
    }

    stages {

        stage('Flutter Doctor') {
            steps {
                bat 'flutter doctor -v'
            }
        }

        stage('Clean') {
            steps {
                bat 'flutter clean'
            }
        }

        stage('Pub Get') {
            steps {
                bat 'curl https://pub.dev',
                bat 'flutter pub get'
            }
        }

        stage('Analyze') {
            steps {
                bat 'flutter analyze'
            }
        }

        stage('Test') {
            steps {
                bat 'flutter test'
            }
        }

        stage('Build Web') {
            steps {
                bat 'flutter build web --release'
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-credential',
                    usernameVariable: 'USERNAME',
                    passwordVariable: 'PASSWORD'
                )]) {
                    bat '''
                    docker login host.docker.internal:8082 ^
                    -u %USERNAME% ^
                    -p %PASSWORD%
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                bat '''
                docker build ^
                -t %IMAGE_NAME%:%IMAGE_TAG% .
                '''
            }
        }

        stage('Push Image') {
            steps {
                bat '''
                docker push %IMAGE_NAME%:%IMAGE_TAG%
                '''
            }
        }

        stage('Deploy DEV') {
            steps {
                bat '''
                docker compose -f docker-compose.yml down
                docker compose -f docker-compose.yml pull
                docker compose -f docker-compose.yml up -d
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline SUCCESS'
        }

        failure {
            echo 'Pipeline FAILED'
        }

        always {
            cleanWs()
        }
    }
}
