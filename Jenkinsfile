/*
 * ============================================================
 * FLUTTER WEB CI/CD
 *
 * GitHub
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
 * Read Version from pubspec.yaml
 *   ↓
 * SNAPSHOT / RELEASE
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
        // 02 - ENVIRONMENT
        // ====================================================

        stage('Environment Check') {

            sh '''
                set -e

                echo "========================================"
                echo "Environment"
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
                echo "Kubectl:"
                kubectl version --client
            '''
        }


        // ====================================================
        // 03 - FLUTTER CLEAN
        // ====================================================

        stage('Flutter Clean') {

            sh '''
                set -e

                /opt/flutter/bin/flutter clean
            '''
        }


        // ====================================================
        // 04 - PUB GET
        // ====================================================

        stage('Flutter Pub Get') {

            sh '''
                set -e

                /opt/flutter/bin/flutter pub get
            '''
        }


        // ====================================================
        // 05 - ANALYZE
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
        // 06 - TEST
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
        // 07 - SONARQUBE
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
                        "Quality Gate FAILED: ${result.status}"
                    )
                }

                echo 'Quality Gate PASSED.'
            }
        }


        // ====================================================
        // 09 - VERSION FROM PUBSPEC
        // ====================================================

        stage('Version') {

            /*
             * Read:
             *
             * version: 1.0.0+1
             */

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
             * Pisahkan:
             *
             * 1.0.0+1
             *
             * menjadi:
             *
             * 1.0.0
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
APPLICATION VERSION
========================================

pubspec.yaml:
${flutterVersion}

App Version:
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
        // 10 - FLUTTER WEB
        // ====================================================

        stage('Flutter Web Prepare') {

            sh '''
                set -e

                echo "========================================"
                echo "Flutter Web Prepare"
                echo "========================================"

                if [ ! -d "web" ]; then

                    echo "Web directory belum ada."

                    /opt/flutter/bin/flutter create . \
                        --platforms web

                else

                    echo "Web directory sudah tersedia."

                fi
            '''
        }


        // ====================================================
        // 11 - BUILD WEB
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
        // 12 - DOCKER BUILD + PUSH
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
                        echo "Docker Build"


                        docker build \
                            --pull \
                            -t "$DOCKER_IMAGE" \
                            .


                        echo ""
                        echo "Docker Push"


                        docker push "$DOCKER_IMAGE"


                        echo ""
                        echo "Image:"
                        echo "$DOCKER_IMAGE"
                    '''
                }
            }
        }


        // ====================================================
        // 13 - DEPLOY K3S
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
        // 14 - VERIFY
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