```groovy
/*
 * ============================================================
 * FLUTTER WEB CI/CD
 *
 * GitHub
 *   ↓
 * Flutter Build + Test
 *   ↓
 * Docker Build + Push
 *   ↓
 * Nexus Docker
 *   ↓
 * K3s Rolling Deployment
 *   ↓
 * Rollback on Failure
 * ============================================================
 */

def gitRepo = 'https://github.com/taqin21in/frontend-flutter.git'
def gitBranch = 'main'

def nexusRegistry = '192.168.0.103:8082'
def imageName = "${nexusRegistry}/docker-hosted/flutter-web"

def k3sNamespace = 'frontend'
def k3sDeployment = 'flutter-web'
def k3sKubeconfig = '/home/jenkins/k3s-jenkins.yaml'

def dockerImage
def deploymentStarted = false


node('runner') {

    properties([
        disableConcurrentBuilds(),
        buildDiscarder(logRotator(numToKeepStr: '20'))
    ])

    try {

        // =====================================================
        // 01 - CHECKOUT
        // =====================================================

        stage('Checkout') {

            deleteDir()

            git(
                url: gitRepo,
                branch: gitBranch,
                credentialsId: 'github-credential'
            )
        }


        // =====================================================
        // 02 - FLUTTER BUILD + TEST
        // =====================================================

        stage('Flutter Build & Test') {

            sh '''
                set -e

                flutter clean
                flutter pub get
                flutter analyze
                flutter test
                flutter build web --release
            '''
        }


        // =====================================================
        // 03 - VERSION
        // =====================================================

        stage('Version') {

            def version = sh(
                script: "grep '^version:' pubspec.yaml | awk '{print \$2}'",
                returnStdout: true
            ).trim()

            def baseVersion = version.split('\\+')[0]

            dockerImage =
                "${imageName}:${baseVersion}-build-${BUILD_NUMBER}"

            echo "Flutter Version : ${version}"
            echo "Docker Image    : ${dockerImage}"
        }


        // =====================================================
        // 04 - DOCKER BUILD + PUSH
        // =====================================================

        stage('Docker Build & Push') {

            withCredentials([
                usernamePassword(
                    credentialsId: 'nexus-credential',
                    usernameVariable: 'NEXUS_USERNAME',
                    passwordVariable: 'NEXUS_PASSWORD'
                )
            ]) {

                sh '''
                    set -e

                    echo "$NEXUS_PASSWORD" |
                        docker login "${nexusRegistry}" \
                        --username "$NEXUS_USERNAME" \
                        --password-stdin

                    docker build \
                        --pull \
                        -t "${dockerImage}" \
                        .

                    docker push "${dockerImage}"
                '''
            }
        }


        // =====================================================
        // 05 - DEPLOY K3S
        // =====================================================

        stage('Deploy K3s') {

            deploymentStarted = true

            withEnv([
                "KUBECONFIG=${k3sKubeconfig}",
                "IMAGE=${dockerImage}"
            ]) {

                sh '''
                    set -e

                    kubectl set image \
                        deployment/${k3sDeployment} \
                        flutter-web=${IMAGE} \
                        -n ${k3sNamespace}

                    kubectl rollout status \
                        deployment/${k3sDeployment} \
                        -n ${k3sNamespace} \
                        --timeout=5m
                '''
            }
        }


        // =====================================================
        // SUCCESS
        // =====================================================

        echo """
        ========================================
        PIPELINE SUCCESS
        ========================================

        Application : Flutter Web
        Docker      : ${dockerImage}
        Nexus       : ${nexusRegistry}
        K3s         : ${k3sNamespace}

        ========================================
        """

    }


    catch (Exception e) {

        echo "PIPELINE FAILED: ${e}"


        // =====================================================
        // ROLLBACK
        // =====================================================

        if (deploymentStarted) {

            try {

                withEnv([
                    "KUBECONFIG=${k3sKubeconfig}"
                ]) {

                    sh '''
                        kubectl rollout undo \
                            deployment/${k3sDeployment} \
                            -n ${k3sNamespace}

                        kubectl rollout status \
                            deployment/${k3sDeployment} \
                            -n ${k3sNamespace} \
                            --timeout=5m
                    '''
                }

                echo "Rollback completed."

            } catch (Exception rollbackError) {

                echo "Rollback FAILED: ${rollbackError}"
            }
        }

        throw e
    }


    finally {

        if (dockerImage) {

            sh """
                docker image rm '${dockerImage}' || true
            """
        }

        deleteDir()
    }
}
```
