/*
 * ============================================================
 * FLUTTER WEB CI/CD + SONARQUBE
 *
 * GitHub
 *   ↓
 * Flutter Clean + Pub Get
 *   ↓
 * Flutter Analyze
 *   ↓
 * Flutter Test
 *   ↓
 * SonarQube Analysis
 *   ↓
 * Quality Gate
 *   ↓
 * Flutter Web Build
 *   ↓
 * Docker Build + Push
 *   ↓
 * Nexus Docker Hosted
 *   ↓
 * K3s Rolling Deployment
 *   ↓
 * Verify
 *   ↓
 * Rollback on Failure
 *
 * Repository:
 * https://github.com/taqin21in/frontend-flutter.git
 * ============================================================
 */


// ============================================================
// GITHUB
// ============================================================

def gitRepo   = 'https://github.com/taqin21in/frontend-flutter.git'
def gitBranch = 'main'


// ============================================================
// TOOLS
// ============================================================

def flutterHome = '/opt/flutter'

def sonarScannerHome = '/opt/sonar-scanner'


// ============================================================
// NEXUS
// ============================================================

def nexusRegistry = '192.168.0.103:8082'

def dockerImageName =
    "${nexusRegistry}/docker-hosted/flutter-web"


// ============================================================
// K3S
// ============================================================

def k3sNamespace  = 'frontend'
def k3sDeployment = 'flutter-web'
def k3sContainer  = 'flutter-web'

def k3sKubeconfig =
    '/home/jenkins/k3s-jenkins.yaml'


// ============================================================
// SONARQUBE
// ============================================================

def sonarProjectKey  = 'frontend-flutter'
def sonarProjectName = 'frontend-flutter'


// ============================================================
// VARIABLES
// ============================================================

def dockerImage
def deploymentStarted = false


// ============================================================
// JENKINS
// ============================================================

node('runner') {

    properties([

        disableConcurrentBuilds(),

        buildDiscarder(
            logRotator(
                numToKeepStr: '20'
            )
        )
    ])


    withEnv([

        "FLUTTER_HOME=${flutterHome}",

        "SONAR_SCANNER_HOME=${sonarScannerHome}",

        "PATH=${flutterHome}/bin:${sonarScannerHome}/bin:${env.PATH}"

    ]) {

        try {


            // ====================================================
            // 01 - CHECKOUT
            // ====================================================

            stage('Checkout') {

                deleteDir()

                git(

                    url: gitRepo,

                    branch: gitBranch,

                    credentialsId: 'github-credential'
                )

                echo "Git checkout completed."
            }


            // ====================================================
            // 02 - FLUTTER ENVIRONMENT
            // ====================================================

            stage('Flutter Environment') {

                sh '''
                    set -e

                    echo "========================================"
                    echo "Flutter Environment"
                    echo "========================================"

                    echo "Flutter Home:"
                    echo "$FLUTTER_HOME"

                    echo ""

                    echo "Flutter Binary:"
                    which flutter

                    echo ""

                    flutter --version
                '''
            }


            // ====================================================
            // 03 - FLUTTER PREPARE
            // ====================================================

            stage('Flutter Prepare') {

                sh '''
                    set -e

                    echo "========================================"
                    echo "Flutter Clean"
                    echo "========================================"

                    flutter clean


                    echo ""
                    echo "========================================"
                    echo "Flutter Pub Get"
                    echo "========================================"

                    flutter pub get
                '''
            }


            // ====================================================
            // 04 - FLUTTER ANALYZE
            // ====================================================

            stage('Flutter Analyze') {

                sh '''
                    set -e

                    echo "========================================"
                    echo "Flutter Analyze"
                    echo "========================================"

                    flutter analyze
                '''
            }


            // ====================================================
            // 05 - FLUTTER TEST
            // ====================================================

            stage('Flutter Test') {

                sh '''
                    set -e

                    echo "========================================"
                    echo "Flutter Test"
                    echo "========================================"

                    flutter test
                '''
            }


            // ====================================================
            // 06 - SONARSCANNER CHECK
            // ====================================================

            stage('SonarScanner Check') {

                sh '''
                    set -e

                    echo "========================================"
                    echo "SonarScanner"
                    echo "========================================"

                    echo "SonarScanner Home:"
                    echo "$SONAR_SCANNER_HOME"

                    echo ""

                    echo "SonarScanner Binary:"
                    which sonar-scanner

                    echo ""

                    sonar-scanner --version
                '''
            }


            // ====================================================
            // 07 - SONARQUBE ANALYSIS
            // ====================================================

            stage('SonarQube Analysis') {

                withSonarQubeEnv('SonarQube') {

                    withEnv([

                        "SONAR_PROJECT_KEY=${sonarProjectKey}",

                        "SONAR_PROJECT_NAME=${sonarProjectName}"

                    ]) {

                        sh '''
                            set -e

                            echo "========================================"
                            echo "SonarQube Analysis"
                            echo "========================================"

                            sonar-scanner \
                                -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
                                -Dsonar.projectName="$SONAR_PROJECT_NAME" \
                                -Dsonar.sources=lib \
                                -Dsonar.tests=test \
                                -Dsonar.sourceEncoding=UTF-8
                        '''
                    }
                }
            }


            // ====================================================
            // 08 - QUALITY GATE
            // ====================================================

            stage('Quality Gate') {

                timeout(

                    time: 10,

                    unit: 'MINUTES'

                ) {

                    def result =
                        waitForQualityGate(
                            abortPipeline: true
                        )


                    if (result.status != 'OK') {

                        error(
                            "SonarQube Quality Gate FAILED: ${result.status}"
                        )
                    }


                    echo "========================================"

                    echo "SonarQube Quality Gate: PASSED"

                    echo "========================================"
                }
            }


            // ====================================================
            // 09 - VERSION
            // ====================================================

            stage('Version') {

                def version = sh(

                    script: '''
                        grep '^version:' pubspec.yaml |
                        head -1 |
                        awk '{print $2}'
                    ''',

                    returnStdout: true

                ).trim()


                if (!version) {

                    error(
                        'Version tidak ditemukan di pubspec.yaml'
                    )
                }


                /*
                 * Example:
                 *
                 * version: 1.0.0+5
                 *
                 * Docker:
                 *
                 * 1.0.0-build-25
                 */

                def baseVersion =
                    version.split('\\+')[0]


                dockerImage =
                    "${dockerImageName}:${baseVersion}-build-${env.BUILD_NUMBER}"


                echo "========================================"

                echo "Application Version"

                echo "========================================"

                echo "Flutter Version : ${version}"

                echo "Docker Image    : ${dockerImage}"
            }


            // ====================================================
            // 10 - FLUTTER WEB BUILD
            // ====================================================

            stage('Flutter Web Build') {

                sh '''
                    set -e

                    echo "========================================"
                    echo "Flutter Web Build"
                    echo "========================================"

                    flutter build web --release


                    echo ""

                    echo "Build output:"

                    ls -lah build/web
                '''
            }


            // ====================================================
            // 11 - DOCKER BUILD & PUSH
            // ====================================================

            stage('Docker Build & Push') {

                withCredentials([

                    usernamePassword(

                        credentialsId:
                            'nexus-credential',

                        usernameVariable:
                            'NEXUS_USERNAME',

                        passwordVariable:
                            'NEXUS_PASSWORD'
                    )
                ]) {

                    withEnv([

                        "DOCKER_IMAGE=${dockerImage}",

                        "DOCKER_REGISTRY=${nexusRegistry}"

                    ]) {

                        sh '''
                            set -e

                            echo "========================================"
                            echo "Docker Login"
                            echo "========================================"

                            echo "$NEXUS_PASSWORD" |
                                docker login "$DOCKER_REGISTRY" \
                                --username "$NEXUS_USERNAME" \
                                --password-stdin


                            echo ""
                            echo "========================================"
                            echo "Docker Build"
                            echo "========================================"

                            docker build \
                                --pull \
                                -t "$DOCKER_IMAGE" \
                                .


                            echo ""
                            echo "========================================"
                            echo "Docker Push"
                            echo "========================================"

                            docker push "$DOCKER_IMAGE"


                            echo ""

                            echo "Image pushed:"

                            echo "$DOCKER_IMAGE"
                        '''
                    }
                }
            }


            // ====================================================
            // 12 - DEPLOY K3S
            // ====================================================

            stage('Deploy K3s') {

                deploymentStarted = true


                withEnv([

                    "KUBECONFIG=${k3sKubeconfig}",

                    "NAMESPACE=${k3sNamespace}",

                    "DEPLOYMENT=${k3sDeployment}",

                    "CONTAINER=${k3sContainer}",

                    "DOCKER_IMAGE=${dockerImage}"

                ]) {

                    sh '''
                        set -e

                        echo "========================================"
                        echo "K3s Deployment"
                        echo "========================================"

                        echo "Namespace : $NAMESPACE"

                        echo "Deployment: $DEPLOYMENT"

                        echo "Container : $CONTAINER"

                        echo "Image     : $DOCKER_IMAGE"


                        echo ""

                        echo "K3s Nodes:"

                        kubectl get nodes -o wide


                        echo ""

                        echo "Updating deployment..."


                        kubectl set image \
                            deployment/"$DEPLOYMENT" \
                            "$CONTAINER=$DOCKER_IMAGE" \
                            -n "$NAMESPACE"


                        echo ""

                        echo "Waiting rollout..."


                        kubectl rollout status \
                            deployment/"$DEPLOYMENT" \
                            -n "$NAMESPACE" \
                            --timeout=5m
                    '''
                }
            }


            // ====================================================
            // 13 - VERIFY
            // ====================================================

            stage('Verify') {

                withEnv([

                    "KUBECONFIG=${k3sKubeconfig}",

                    "NAMESPACE=${k3sNamespace}",

                    "DEPLOYMENT=${k3sDeployment}"

                ]) {

                    sh '''
                        set -e

                        echo "========================================"
                        echo "K3s Verification"
                        echo "========================================"


                        echo "Deployment:"

                        kubectl get deployment \
                            "$DEPLOYMENT" \
                            -n "$NAMESPACE"


                        echo ""

                        echo "Pods:"

                        kubectl get pods \
                            -n "$NAMESPACE" \
                            -o wide


                        echo ""

                        echo "Service:"

                        kubectl get service \
                            -n "$NAMESPACE"


                        echo ""

                        echo "Ingress:"

                        kubectl get ingress \
                            -n "$NAMESPACE" \
                            || true
                    '''
                }
            }


            // ====================================================
            // SUCCESS
            // ====================================================

            echo """

            ========================================
            PIPELINE SUCCESS
            ========================================

            Application:
            Flutter Web

            Repository:
            ${gitRepo}

            Docker Image:
            ${dockerImage}

            Nexus:
            ${nexusRegistry}

            SonarQube:
            ${sonarProjectName}

            K3s Namespace:
            ${k3sNamespace}

            Deployment:
            ${k3sDeployment}

            Jenkins Build:
            ${env.BUILD_NUMBER}

            ========================================

            """


        } catch (Exception e) {

            echo "PIPELINE FAILED: ${e}"


            // ====================================================
            // ROLLBACK
            // ====================================================

            if (deploymentStarted) {

                try {

                    withEnv([

                        "KUBECONFIG=${k3sKubeconfig}",

                        "NAMESPACE=${k3sNamespace}",

                        "DEPLOYMENT=${k3sDeployment}"

                    ]) {

                        sh '''
                            echo "========================================"
                            echo "ROLLBACK"
                            echo "========================================"


                            kubectl rollout undo \
                                deployment/"$DEPLOYMENT" \
                                -n "$NAMESPACE"


                            kubectl rollout status \
                                deployment/"$DEPLOYMENT" \
                                -n "$NAMESPACE" \
                                --timeout=5m


                            echo "Rollback completed."
                        '''
                    }

                } catch (Exception rollbackError) {

                    echo "Rollback FAILED: ${rollbackError}"
                }
            }


            throw e


        } finally {


            // ====================================================
            // DOCKER CLEANUP
            // ====================================================

            if (dockerImage) {

                sh """

                    docker image rm \
                        '${dockerImage}' || true

                """
            }


            // ====================================================
            // NEXUS LOGOUT
            // ====================================================

            sh """

                docker logout \
                    '${nexusRegistry}' || true

            """


            // ====================================================
            // WORKSPACE CLEANUP
            // ====================================================

            deleteDir()
        }
    }
}