/*
 * ============================================================
 * FLUTTER WEB CI/CD
 *
 * GitHub
 *   ↓
 * Flutter Analyze + Test + Build
 *   ↓
 * Docker Build + Push
 *   ↓
 * Nexus Docker Hosted
 *   ↓
 * K3s Rolling Deployment
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
        // 02 - FLUTTER BUILD & TEST
        // ====================================================

        stage('Flutter Build & Test') {

            sh '''
                set -e

                echo "========================================"
                echo "Flutter Version"
                echo "========================================"

                flutter --version


                echo ""
                echo "========================================"
                echo "Flutter Clean"
                echo "========================================"

                flutter clean


                echo ""
                echo "========================================"
                echo "Flutter Pub Get"
                echo "========================================"

                flutter pub get


                echo ""
                echo "========================================"
                echo "Flutter Analyze"
                echo "========================================"

                flutter analyze


                echo ""
                echo "========================================"
                echo "Flutter Test"
                echo "========================================"

                flutter test


                echo ""
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
        // 03 - VERSION
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
             * Contoh:
             *
             * pubspec:
             * version: 1.0.0+5
             *
             * Docker:
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
        // 04 - DOCKER BUILD & PUSH
        // ====================================================

        stage('Docker Build & Push') {

            withCredentials([

                usernamePassword(

                    credentialsId: 'nexus-credential',

                    usernameVariable: 'NEXUS_USERNAME',

                    passwordVariable: 'NEXUS_PASSWORD'
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
        // 05 - DEPLOY K3S
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
        // 06 - VERIFY
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

        Application : Flutter Web

        Docker Image:
        ${dockerImage}

        Nexus:
        ${nexusRegistry}

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
                docker image rm '${dockerImage}' || true
            """
        }


        // ====================================================
        // LOGOUT NEXUS
        // ====================================================

        sh """
            docker logout '${nexusRegistry}' || true
        """


        // ====================================================
        // WORKSPACE CLEANUP
        // ====================================================

        deleteDir()
    }
}