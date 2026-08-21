/*
 * ============================================================
 * FLUTTER WEB DEVSECOPS CI/CD
 *
 * GitHub
 *   ↓
 * Checkout
 *   ↓
 * Dependency Validation
 *   ↓
 * Flutter Clean
 *   ↓
 * Flutter Pub Get
 *   ↓
 * Flutter Analyze
 *   ↓
 * Flutter Test
 *   ↓
 * SonarQube
 *   ↓
 * Quality Gate
 *   ↓
 * Version from pubspec.yaml
 *   ↓
 * Flutter Web Build
 *   ↓
 * Docker Build
 *   ↓
 * Trivy Security Scan
 *   ↓
 * Release Immutable Validation
 *   ↓
 * Nexus Docker Hosted
 *   ↓
 * K3s Rolling Deployment
 *   ↓
 * Verify
 *   ↓
 * Rollback
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
def sonarHome   = '/opt/sonar-scanner'


// ============================================================
// NEXUS
// ============================================================

def nexusRegistry = '192.168.0.103:8082'

def dockerImageName = "${nexusRegistry}/flutter-web"


// ============================================================
// K3S
// ============================================================

def k3sNamespace  = 'frontend'
def k3sDeployment = 'flutter-web'
def k3sContainer  = 'flutter-web'

def k3sKubeconfig =
    '/home/jenkins/k3s-jenkins.yaml'


// ============================================================
// VARIABLES
// ============================================================

def flutterVersion
def appVersion
def buildNumber
def dockerImage
def buildType

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
        ),

        parameters([

            choice(
                name: 'BUILD_TYPE',

                choices: [
                    'SNAPSHOT',
                    'RELEASE'
                ],

                description:
                    'SNAPSHOT = development, RELEASE = production'
            )
        ])
    ])


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

            echo 'Git checkout completed.'
        }


        // ====================================================
        // 02 - ENVIRONMENT CHECK
        // ====================================================

        stage('Environment Check') {

            sh '''
                set -e

                echo "========================================"
                echo "Environment Check"
                echo "========================================"


                echo ""
                echo "Flutter:"
                /opt/flutter/bin/flutter --version


                echo ""
                echo "SonarScanner:"
                /opt/sonar-scanner/bin/sonar-scanner --version


                echo ""
                echo "Docker:"
                docker --version


                echo ""
                echo "Trivy:"
                trivy --version


                echo ""
                echo "Kubectl:"
                kubectl version --client
            '''
        }


        // ====================================================
        // 03 - DEPENDENCY VALIDATION
        // ====================================================

        stage('Dependency Validation') {

            sh '''
                set -e

                echo "========================================"
                echo "Dependency Validation"
                echo "========================================"


                echo ""
                echo "Checking pubspec.yaml..."

                test -f pubspec.yaml


                echo ""
                echo "Checking pubspec.lock..."

                if [ ! -f pubspec.lock ]; then

                    echo ""
                    echo "ERROR:"
                    echo "pubspec.lock tidak ditemukan."

                    echo ""
                    echo "Untuk Flutter Application,"
                    echo "pubspec.lock harus di-commit ke Git."

                    exit 1
                fi


                echo ""
                echo "pubspec.lock found."


                echo ""
                echo "Flutter dependency check..."

                /opt/flutter/bin/flutter pub get


                echo ""
                echo "Dependency status..."

                /opt/flutter/bin/flutter pub outdated || true
            '''
        }


        // ====================================================
        // 04 - FLUTTER CLEAN
        // ====================================================

        stage('Flutter Clean') {

            sh '''
                set -e

                echo "========================================"
                echo "Flutter Clean"
                echo "========================================"

                /opt/flutter/bin/flutter clean
            '''
        }


        // ====================================================
        // 05 - FLUTTER PUB GET
        // ====================================================

        stage('Flutter Pub Get') {

            sh '''
                set -e

                echo "========================================"
                echo "Flutter Pub Get"
                echo "========================================"

                /opt/flutter/bin/flutter pub get
            '''
        }


        // ====================================================
        // 06 - FLUTTER ANALYZE
        // ====================================================

        stage('Flutter Analyze') {

            sh '''
                set -e

                echo "========================================"
                echo "Flutter Analyze"
                echo "========================================"

                /opt/flutter/bin/flutter analyze
            '''
        }


        // ====================================================
        // 07 - FLUTTER TEST
        // ====================================================

        stage('Flutter Test') {

            sh '''
                set -e

                echo "========================================"
                echo "Flutter Test"
                echo "========================================"

                /opt/flutter/bin/flutter test
            '''
        }


        // ====================================================
        // 08 - SONARQUBE
        // ====================================================

        stage('SonarQube Analysis') {

            withSonarQubeEnv('SonarQube') {

                sh '''
                    set -e

                    echo "========================================"
                    echo "SonarQube Analysis"
                    echo "========================================"


                    /opt/sonar-scanner/bin/sonar-scanner \
                        -Dsonar.projectKey=frontend-flutter \
                        -Dsonar.projectName=frontend-flutter \
                        -Dsonar.sources=lib \
                        -Dsonar.tests=test \
                        -Dsonar.sourceEncoding=UTF-8
                '''
            }
        }


        // ====================================================
        // 09 - QUALITY GATE
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
                        "Quality Gate FAILED: ${result.status}"
                    )
                }


                echo 'Quality Gate PASSED.'
            }
        }


        // ====================================================
        // 10 - VERSION
        // ====================================================

        stage('Version') {

            flutterVersion = sh(

                script: '''
                    grep '^version:' pubspec.yaml |
                    head -1 |
                    awk '{print $2}'
                ''',

                returnStdout: true

            ).trim()


            if (!flutterVersion) {

                error(
                    'Version tidak ditemukan di pubspec.yaml'
                )
            }


            /*
             * Example:
             *
             * 1.0.0+1
             *
             * Base Version:
             * 1.0.0
             *
             * Flutter Build:
             * 1
             */


            def versionParts =
                flutterVersion.split('\\+')


            appVersion =
                versionParts[0]


            buildNumber =
                versionParts.size() > 1
                    ? versionParts[1]
                    : '0'


            buildType =
                params.BUILD_TYPE


            // =================================================
            // SNAPSHOT
            // =================================================

            if (buildType == 'SNAPSHOT') {

                dockerImage =
                    "${dockerImageName}:${appVersion}-SNAPSHOT-build-${env.BUILD_NUMBER}"
            }


            // =================================================
            // RELEASE
            // =================================================

            else {

                dockerImage =
                    "${dockerImageName}:${appVersion}"
            }


            echo """
========================================
VERSION
========================================

pubspec.yaml:
${flutterVersion}

Application Version:
${appVersion}

Flutter Build Number:
${buildNumber}

Build Type:
${buildType}

Docker Image:
${dockerImage}

Jenkins Build:
${env.BUILD_NUMBER}

========================================
"""
        }


        // ====================================================
        // 11 - FLUTTER WEB PREPARE
        // ====================================================

        stage('Flutter Web Prepare') {

            sh '''
                set -e

                echo "========================================"
                echo "Flutter Web Prepare"
                echo "========================================"


                if [ ! -d "web" ]; then

                    echo "Web directory belum tersedia."

                    /opt/flutter/bin/flutter create . \
                        --platforms web

                else

                    echo "Web directory sudah tersedia."

                fi
            '''
        }


        // ====================================================
        // 12 - FLUTTER WEB BUILD
        // ====================================================

        stage('Flutter Web Build') {

            sh '''
                set -e

                echo "========================================"
                echo "Flutter Web Build"
                echo "========================================"

                /opt/flutter/bin/flutter build web \
                    --release


                echo ""
                echo "Build output:"

                ls -lah build/web
            '''
        }


        // ====================================================
        // 13 - DOCKER BUILD
        // ====================================================

        stage('Docker Build') {

            withEnv([

                "DOCKER_IMAGE=${dockerImage}"

            ]) {

                sh '''
                    set -e

                    echo "========================================"
                    echo "Docker Build"
                    echo "========================================"


                    docker build \
                        --pull \
                        -t "$DOCKER_IMAGE" \
                        .


                    echo ""
                    echo "Docker image created:"

                    docker images "$DOCKER_IMAGE"
                '''
            }
        }


        // ====================================================
        // 14 - TRIVY SECURITY SCAN
        // ====================================================

        stage('Trivy Security Scan') {

            withEnv([

                "DOCKER_IMAGE=${dockerImage}"

            ]) {

                sh '''
                    set -e

                    echo "========================================"
                    echo "Trivy Security Scan"
                    echo "========================================"


                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --ignore-unfixed \
                        "$DOCKER_IMAGE"
                '''
            }
        }


        // ====================================================
        // 15 - RELEASE IMMUTABLE VALIDATION
        // ====================================================

        stage('Release Validation') {

            if (buildType == 'RELEASE') {

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

                        "DOCKER_REGISTRY=${nexusRegistry}",

                        "IMAGE_TAG=${appVersion}"

                    ]) {

                        sh '''
                            set -e

                            echo "========================================"
                            echo "Release Validation"
                            echo "========================================"


                            echo "Checking existing release tag..."

                            STATUS=$(curl -s \
                                -o /dev/null \
                                -w "%{http_code}" \
                                -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
                                "http://$DOCKER_REGISTRY/v2/flutter-web/manifests/$IMAGE_TAG" \
                                || true)


                            echo "Nexus response: $STATUS"


                            if [ "$STATUS" = "200" ]; then

                                echo ""
                                echo "ERROR:"
                                echo "Release $IMAGE_TAG sudah ada di Nexus."


                                echo ""
                                echo "Release image immutable."
                                echo "Pipeline dihentikan untuk mencegah overwrite."


                                exit 1
                            fi


                            echo ""
                            echo "Release $IMAGE_TAG belum tersedia."

                            echo "Release validation PASSED."
                        '''
                    }
                }

            } else {

                echo "SNAPSHOT build - immutable release validation dilewati."
            }
        }


        // ====================================================
        // 16 - DOCKER PUSH
        // ====================================================

        stage('Docker Push') {

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
                        echo "Pushing image:"

                        docker push "$DOCKER_IMAGE"


                        echo ""
                        echo "Docker push completed."
                    '''
                }
            }
        }


        // ====================================================
        // 17 - DEPLOY K3S
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


                    kubectl set image \
                        deployment/"$DEPLOYMENT" \
                        "$CONTAINER=$DOCKER_IMAGE" \
                        -n "$NAMESPACE"


                    kubectl rollout status \
                        deployment/"$DEPLOYMENT" \
                        -n "$NAMESPACE" \
                        --timeout=5m
                '''
            }
        }


        // ====================================================
        // 18 - VERIFY
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


                    kubectl get deployment \
                        "$DEPLOYMENT" \
                        -n "$NAMESPACE"


                    echo ""

                    kubectl get pods \
                        -n "$NAMESPACE" \
                        -o wide


                    echo ""

                    kubectl get service \
                        -n "$NAMESPACE"


                    echo ""

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

Build Type:
${buildType}

Flutter Version:
${flutterVersion}

Application Version:
${appVersion}

Flutter Build Number:
${buildNumber}

Docker Image:
${dockerImage}

Nexus:
${nexusRegistry}

K3s Namespace:
${k3sNamespace}

K3s Deployment:
${k3sDeployment}

Jenkins Build:
${env.BUILD_NUMBER}

Security:
- pubspec.lock validation : PASSED
- SonarQube               : PASSED
- Quality Gate            : PASSED
- Trivy                   : PASSED
- Release immutability    : PASSED

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